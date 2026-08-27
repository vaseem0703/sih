#!/usr/bin/env python3
"""
Multi-GPU evaluation runner for CTranslate2 translation model.

Distributes translation tasks across 4 GPU workers for maximum throughput.
Computes BLEU and chrF++ using sacrebleu.

Usage:
    python run_evaluation.py \
        --model ct2-int8 \
        --tokenizer merged-model \
        --manifest eval/data/manifest.json \
        --output-dir eval/results \
        --num-gpus 4
"""

import argparse
import csv
import json
import logging
import os
import time
import multiprocessing as mp
from collections import defaultdict

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
DEFAULT_BATCH_SIZE = 64
DEFAULT_BEAM_SIZE = 5
MAX_INPUT_LENGTH = 256
MAX_DECODING_LENGTH = 256


# ---------------------------------------------------------------------------
# Worker
# ---------------------------------------------------------------------------

def gpu_worker(gpu_id, model_path, tokenizer_path, task_queue, result_queue,
               batch_size, beam_size):
    """
    Worker process: loads CT2 model on a specific GPU,
    picks tasks from queue, translates + scores.
    """
    import ctranslate2
    from transformers import AutoTokenizer
    import sacrebleu

    # Pin to specific GPU
    os.environ["CUDA_VISIBLE_DEVICES"] = str(gpu_id)

    try:
        # Load CT2 translator
        translator = ctranslate2.Translator(
            model_path,
            device="cuda",
            device_index=0,
            compute_type="int8_float16",
        )

        # Load tokenizer
        tokenizer = AutoTokenizer.from_pretrained(tokenizer_path)

        log.info(f"[GPU {gpu_id}] Model loaded successfully")
    except Exception as e:
        log.error(f"[GPU {gpu_id}] Failed to load model: {e}")
        # Drain tasks and report errors
        while True:
            task = task_queue.get()
            if task is None:
                break
            result_queue.put({
                "dataset": task[0], "src_lang": task[1], "tgt_lang": task[2],
                "num_sentences": task[5], "bleu": None, "chrf": None,
                "gpu_id": gpu_id, "status": f"error: model load failed: {e}",
                "time_seconds": 0,
            })
        return

    while True:
        task = task_queue.get()
        if task is None:  # Poison pill
            break

        dataset, src_lang, tgt_lang, src_file, ref_file, num_sentences = task
        t0 = time.time()

        try:
            # Read source and reference
            with open(src_file, encoding="utf-8") as f:
                sources = [line.strip() for line in f if line.strip()]
            with open(ref_file, encoding="utf-8") as f:
                references = [line.strip() for line in f if line.strip()]

            # Truncate to match if needed
            min_len = min(len(sources), len(references))
            sources = sources[:min_len]
            references = references[:min_len]

            # Translate
            translations = translate_batch_ct2(
                translator, tokenizer, sources, src_lang, tgt_lang,
                batch_size=batch_size, beam_size=beam_size,
            )

            # Compute metrics
            bleu = sacrebleu.corpus_bleu(translations, [references])
            chrf = sacrebleu.corpus_chrf(translations, [references], word_order=2)

            elapsed = time.time() - t0
            result = {
                "dataset": dataset,
                "src_lang": src_lang,
                "tgt_lang": tgt_lang,
                "num_sentences": len(sources),
                "bleu": round(bleu.score, 2),
                "bleu_signature": str(bleu),
                "chrf": round(chrf.score, 2),
                "chrf_signature": str(chrf),
                "gpu_id": gpu_id,
                "status": "ok",
                "time_seconds": round(elapsed, 1),
            }
        except Exception as e:
            elapsed = time.time() - t0
            result = {
                "dataset": dataset,
                "src_lang": src_lang,
                "tgt_lang": tgt_lang,
                "num_sentences": num_sentences,
                "bleu": None,
                "chrf": None,
                "gpu_id": gpu_id,
                "status": f"error: {str(e)}",
                "time_seconds": round(elapsed, 1),
            }

        result_queue.put(result)

    log.info(f"[GPU {gpu_id}] Worker finished")


def translate_batch_ct2(translator, tokenizer, sources, src_lang, tgt_lang,
                        batch_size=64, beam_size=5):
    """
    Translate a list of source sentences using CTranslate2.
    Processes in chunks of batch_size for memory efficiency.
    """
    tokenizer.src_lang = src_lang
    all_translations = []

    for i in range(0, len(sources), batch_size):
        chunk = sources[i:i + batch_size]

        # Tokenize each sentence
        batch_tokens = []
        for text in chunk:
            encoded = tokenizer(
                text, return_tensors=None,
                max_length=MAX_INPUT_LENGTH, truncation=True,
            )
            tokens = tokenizer.convert_ids_to_tokens(encoded["input_ids"])
            batch_tokens.append(tokens)

        # Target prefix: language token for each sentence
        target_prefix = [[tgt_lang]] * len(batch_tokens)

        # Translate batch
        results = translator.translate_batch(
            batch_tokens,
            target_prefix=target_prefix,
            beam_size=beam_size,
            max_decoding_length=MAX_DECODING_LENGTH,
        )

        # Decode translations
        for result in results:
            output_tokens = result.hypotheses[0][1:]  # skip the language token
            output_ids = tokenizer.convert_tokens_to_ids(output_tokens)
            translation = tokenizer.decode(output_ids, skip_special_tokens=True)
            all_translations.append(translation)

    return all_translations


# ---------------------------------------------------------------------------
# Results output
# ---------------------------------------------------------------------------

def write_results(results, output_dir, total_time):
    """Write evaluation results in multiple formats."""
    os.makedirs(output_dir, exist_ok=True)
    timestamp = time.strftime("%Y%m%d_%H%M%S")

    sorted_results = sorted(
        results, key=lambda r: (r["dataset"], r["src_lang"], r["tgt_lang"])
    )

    # 1. Full JSON
    json_path = os.path.join(output_dir, f"eval_results_{timestamp}.json")
    with open(json_path, "w") as f:
        json.dump({
            "timestamp": timestamp,
            "total_time_seconds": round(total_time, 1),
            "num_tasks": len(results),
            "num_ok": sum(1 for r in results if r["status"] == "ok"),
            "num_errors": sum(1 for r in results if r["status"] != "ok"),
            "results": sorted_results,
        }, f, indent=2)

    # 2. CSV
    csv_path = os.path.join(output_dir, f"eval_results_{timestamp}.csv")
    with open(csv_path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow([
            "dataset", "src_lang", "tgt_lang", "num_sentences",
            "bleu", "chrf++", "time_sec", "status",
        ])
        for r in sorted_results:
            writer.writerow([
                r["dataset"], r["src_lang"], r["tgt_lang"],
                r["num_sentences"], r.get("bleu", ""),
                r.get("chrf", ""), r.get("time_seconds", ""),
                r["status"],
            ])

    # 3. Summary text
    summary_path = os.path.join(output_dir, f"eval_summary_{timestamp}.txt")
    with open(summary_path, "w") as f:
        f.write("=" * 80 + "\n")
        f.write("Indic Translation Evaluation Summary\n")
        f.write(f"Timestamp: {timestamp}\n")
        f.write(f"Total time: {total_time:.0f}s ({total_time/60:.1f} min)\n")
        f.write("=" * 80 + "\n\n")

        # Per-dataset breakdown
        by_dataset = defaultdict(list)
        for r in results:
            by_dataset[r["dataset"]].append(r)

        for ds_name in sorted(by_dataset.keys()):
            ds_results = by_dataset[ds_name]
            ok_results = [r for r in ds_results if r["status"] == "ok"]
            err_results = [r for r in ds_results if r["status"] != "ok"]

            f.write(f"\n{'=' * 80}\n")
            f.write(f"Dataset: {ds_name}\n")
            f.write(f"  Tasks: {len(ok_results)} OK")
            if err_results:
                f.write(f", {len(err_results)} errors")
            f.write("\n")

            if not ok_results:
                f.write("  No successful evaluations\n")
                continue

            avg_bleu = sum(r["bleu"] for r in ok_results) / len(ok_results)
            avg_chrf = sum(r["chrf"] for r in ok_results) / len(ok_results)
            f.write(f"  Average BLEU:  {avg_bleu:.2f}\n")
            f.write(f"  Average chrF++: {avg_chrf:.2f}\n")

            # En→X breakdown
            en_to_x = [r for r in ok_results if r["src_lang"] == "eng_Latn"]
            x_to_en = [r for r in ok_results if r["tgt_lang"] == "eng_Latn"]

            if en_to_x:
                avg_b = sum(r["bleu"] for r in en_to_x) / len(en_to_x)
                avg_c = sum(r["chrf"] for r in en_to_x) / len(en_to_x)
                f.write(f"  En→X:  avg BLEU={avg_b:.2f}, chrF++={avg_c:.2f} ({len(en_to_x)} pairs)\n")
            if x_to_en:
                avg_b = sum(r["bleu"] for r in x_to_en) / len(x_to_en)
                avg_c = sum(r["chrf"] for r in x_to_en) / len(x_to_en)
                f.write(f"  X→En:  avg BLEU={avg_b:.2f}, chrF++={avg_c:.2f} ({len(x_to_en)} pairs)\n")

            # Per-language detail
            f.write(f"\n  {'Direction':<25s} {'BLEU':>8s} {'chrF++':>8s} {'Sents':>7s} {'Time':>7s}\n")
            f.write(f"  {'-'*25} {'-'*8} {'-'*8} {'-'*7} {'-'*7}\n")
            for r in sorted(ok_results, key=lambda x: -x["bleu"]):
                direction = f"{r['src_lang']}→{r['tgt_lang']}"
                f.write(f"  {direction:<25s} {r['bleu']:>8.2f} {r['chrf']:>8.2f} "
                        f"{r['num_sentences']:>7d} {r['time_seconds']:>6.1f}s\n")

        # Overall summary
        all_ok = [r for r in results if r["status"] == "ok"]
        f.write(f"\n{'=' * 80}\n")
        f.write(f"OVERALL\n")
        f.write(f"  Total tasks:    {len(results)}\n")
        f.write(f"  Successful:     {len(all_ok)}\n")
        f.write(f"  Failed:         {len(results) - len(all_ok)}\n")
        if all_ok:
            overall_bleu = sum(r["bleu"] for r in all_ok) / len(all_ok)
            overall_chrf = sum(r["chrf"] for r in all_ok) / len(all_ok)
            total_sents = sum(r["num_sentences"] for r in all_ok)
            f.write(f"  Overall BLEU:   {overall_bleu:.2f}\n")
            f.write(f"  Overall chrF++: {overall_chrf:.2f}\n")
            f.write(f"  Total sentences: {total_sents:,}\n")
        f.write(f"  Wall time:      {total_time:.0f}s ({total_time/60:.1f} min)\n")
        f.write("=" * 80 + "\n")

    # Also create a symlink to latest
    for ext, path in [("json", json_path), ("csv", csv_path), ("txt", summary_path)]:
        link = os.path.join(output_dir, f"eval_latest.{ext}")
        if os.path.islink(link):
            os.unlink(link)
        try:
            os.symlink(os.path.basename(path), link)
        except OSError:
            pass

    log.info(f"\nResults written to:")
    log.info(f"  JSON:    {json_path}")
    log.info(f"  CSV:     {csv_path}")
    log.info(f"  Summary: {summary_path}")

    # Print summary to stdout
    with open(summary_path) as f:
        print(f.read())

    return json_path, csv_path, summary_path


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Multi-GPU Indic translation evaluation with CTranslate2"
    )
    parser.add_argument("--model", required=True, help="CT2 model directory")
    parser.add_argument("--tokenizer", default=None,
                        help="Tokenizer path (default: same as --model)")
    parser.add_argument("--manifest", required=True,
                        help="manifest.json from download step")
    parser.add_argument("--output-dir", default="eval/results",
                        help="Results output directory")
    parser.add_argument("--num-gpus", type=int, default=4,
                        help="Number of GPUs to use")
    parser.add_argument("--batch-size", type=int, default=DEFAULT_BATCH_SIZE,
                        help="Sentences per CT2 batch")
    parser.add_argument("--beam-size", type=int, default=DEFAULT_BEAM_SIZE,
                        help="Beam size for translation")
    parser.add_argument("--datasets", nargs="*", default=None,
                        help="Filter to specific datasets")
    parser.add_argument("--languages", nargs="*", default=None,
                        help="Filter to specific Indic language codes")
    args = parser.parse_args()

    tokenizer_path = args.tokenizer or args.model

    # Load manifest
    with open(args.manifest) as f:
        manifest = json.load(f)

    # Filter
    tasks = manifest
    if args.datasets:
        ds_set = set(args.datasets)
        tasks = [t for t in tasks if t["dataset"] in ds_set]
    if args.languages:
        lang_set = set(args.languages)
        tasks = [t for t in tasks
                 if t["src_lang"] in lang_set or t["tgt_lang"] in lang_set]

    if not tasks:
        log.error("No evaluation tasks match the given filters")
        return

    # Sort by num_sentences descending for load balancing
    tasks.sort(key=lambda t: t["num_sentences"], reverse=True)

    total_sents = sum(t["num_sentences"] for t in tasks)
    log.info(f"Evaluation tasks: {len(tasks)}")
    log.info(f"Total sentences: {total_sents:,}")
    log.info(f"GPUs: {args.num_gpus}")
    log.info(f"Batch size: {args.batch_size}, Beam size: {args.beam_size}")

    # Set multiprocessing start method
    mp.set_start_method("spawn", force=True)

    # Create queues
    task_queue = mp.Queue()
    result_queue = mp.Queue()

    # Enqueue tasks
    for task in tasks:
        task_queue.put((
            task["dataset"], task["src_lang"], task["tgt_lang"],
            task["src_file"], task["ref_file"], task["num_sentences"],
        ))

    # Add poison pills
    for _ in range(args.num_gpus):
        task_queue.put(None)

    # Spawn workers
    t_start = time.time()
    workers = []
    for gpu_id in range(args.num_gpus):
        p = mp.Process(
            target=gpu_worker,
            args=(gpu_id, args.model, tokenizer_path,
                  task_queue, result_queue, args.batch_size, args.beam_size),
        )
        p.start()
        workers.append(p)

    # Collect results with progress
    results = []
    for i in range(len(tasks)):
        result = result_queue.get()
        results.append(result)
        status_icon = "OK" if result["status"] == "ok" else "FAIL"
        bleu_str = f"{result['bleu']:>6.2f}" if result.get("bleu") is not None else "  N/A "
        chrf_str = f"{result['chrf']:>6.2f}" if result.get("chrf") is not None else "  N/A "
        log.info(
            f"  [{i+1:3d}/{len(tasks)}] {result['dataset']:15s} "
            f"{result['src_lang']:>10s} → {result['tgt_lang']:<10s} "
            f"BLEU={bleu_str} chrF++={chrf_str} "
            f"({result.get('time_seconds', 0):.1f}s GPU{result['gpu_id']}) "
            f"[{status_icon}]"
        )

    # Wait for workers
    for p in workers:
        p.join()

    total_time = time.time() - t_start

    # Write results
    write_results(results, args.output_dir, total_time)


if __name__ == "__main__":
    main()
