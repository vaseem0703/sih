#!/usr/bin/env python3
"""
Download and normalize all evaluation datasets for Indic translation benchmarking.

Produces a unified format:
    eval/data/{dataset}/{dataset}_{src_lang}_{tgt_lang}.src
    eval/data/{dataset}/{dataset}_{src_lang}_{tgt_lang}.ref
    eval/data/manifest.json

Usage:
    python download_datasets.py --output-dir eval/data
    python download_datasets.py --output-dir eval/data --datasets flores200 in22gen
"""

import argparse
import glob
import json
import logging
import os
import sys
import tarfile
import tempfile
import urllib.request
from pathlib import Path

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Language codes supported by our model (58 total)
# ---------------------------------------------------------------------------
SUPPORTED_LANG_CODES = {
    # 25 native Indic languages + English
    "eng_Latn", "hin_Deva", "tam_Taml", "tel_Telu", "ben_Beng",
    "kan_Knda", "mal_Mlym", "mar_Deva", "guj_Gujr", "pan_Guru",
    "urd_Arab", "ory_Orya", "asm_Beng", "npi_Deva", "san_Deva",
    "bho_Deva", "mag_Deva", "hne_Deva", "mai_Deva", "awa_Deva",
    "kas_Arab", "kas_Deva", "doi_Deva", "snd_Arab", "mni_Mtei",
    # 33 new fine-tuned languages
    "tcy_Knda", "kfa_Knda", "kok_Deva", "ahr_Deva", "kht_Mymr",
    "brj_Deva", "kru_Deva", "lmn_Deva", "phr_Deva", "bfy_Deva",
    "bfz_Deva", "bgc_Deva", "bgq_Deva", "bhb_Deva", "bns_Deva",
    "bra_Deva", "brx_Deva", "dcc_Deva", "gbm_Deva", "gon_Deva",
    "grt_Latn", "hoj_Deva", "kfr_Deva", "kfy_Deva", "mtr_Deva",
    "mwr_Deva", "noe_Deva", "raj_Deva", "sgj_Deva", "wbr_Deva",
    "xnr_Deva", "sat_Olck", "spv_Orya",
    # Additional from monolingual-translated
    "hoc_Deva", "kho_Deva", "unr_Deva", "kha_Latn", "srb_Latn",
    "lus_Latn",
}

# ISO 639-1/2/3 -> language code mapping
ISO_TO_LANG = {
    "en": "eng_Latn", "hi": "hin_Deva", "bn": "ben_Beng",
    "ta": "tam_Taml", "te": "tel_Telu", "kn": "kan_Knda",
    "ml": "mal_Mlym", "mr": "mar_Deva", "gu": "guj_Gujr",
    "pa": "pan_Guru", "or": "ory_Orya", "as": "asm_Beng",
    "ne": "npi_Deva", "sa": "san_Deva", "sd": "snd_Arab",
    "ur": "urd_Arab", "mai": "mai_Deva", "mni": "mni_Mtei",
    "doi": "doi_Deva", "kok": "kok_Deva", "brx": "brx_Deva",
    "sat": "sat_Olck", "bho": "bho_Deva", "mag": "mag_Deva",
    "hne": "hne_Deva", "awa": "awa_Deva",
}

# Reverse mapping: language code -> ISO
LANG_TO_ISO = {v: k for k, v in ISO_TO_LANG.items()}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def write_pair(output_dir, dataset_name, src_lang, tgt_lang, src_sentences, ref_sentences):
    """Write a parallel sentence pair to standardized files."""
    assert len(src_sentences) == len(ref_sentences), (
        f"Mismatch: {len(src_sentences)} src vs {len(ref_sentences)} ref"
    )
    # Filter out empty lines (keep only pairs where both are non-empty)
    pairs = [(s.strip(), r.strip()) for s, r in zip(src_sentences, ref_sentences)
             if s.strip() and r.strip()]
    if not pairs:
        log.warning(f"  {dataset_name} {src_lang}->{tgt_lang}: 0 valid pairs, skipping")
        return 0

    ds_dir = os.path.join(output_dir, dataset_name)
    os.makedirs(ds_dir, exist_ok=True)
    base = f"{dataset_name}_{src_lang}_{tgt_lang}"

    src_sents, ref_sents = zip(*pairs)
    with open(os.path.join(ds_dir, f"{base}.src"), "w", encoding="utf-8") as f:
        f.write("\n".join(src_sents) + "\n")
    with open(os.path.join(ds_dir, f"{base}.ref"), "w", encoding="utf-8") as f:
        f.write("\n".join(ref_sents) + "\n")

    log.info(f"  {dataset_name} {src_lang}->{tgt_lang}: {len(pairs)} sentences")
    return len(pairs)


def generate_manifest(output_dir):
    """Scan output_dir and produce manifest.json listing all eval tasks."""
    manifest = []
    for src_file in sorted(glob.glob(os.path.join(output_dir, "*", "*.src"))):
        ref_file = src_file.replace(".src", ".ref")
        if not os.path.exists(ref_file):
            continue
        # Parse filename: {dataset}_{src_lang}_{tgt_lang}.src
        basename = os.path.basename(src_file).replace(".src", "")
        dataset_name = os.path.basename(os.path.dirname(src_file))
        # Extract src and tgt lang from the basename after the dataset prefix
        rest = basename[len(dataset_name) + 1:]  # skip "{dataset}_"
        # Language codes are like "eng_Latn", so split on the boundary
        parts = rest.split("_")
        # Language codes are always {3chars}_{4chars}, so src_lang is parts[0]_parts[1]
        if len(parts) >= 4:
            src_lang = f"{parts[0]}_{parts[1]}"
            tgt_lang = f"{parts[2]}_{parts[3]}"
        else:
            log.warning(f"Cannot parse filename: {basename}")
            continue

        with open(src_file) as f:
            num_sentences = sum(1 for line in f if line.strip())

        manifest.append({
            "dataset": dataset_name,
            "src_lang": src_lang,
            "tgt_lang": tgt_lang,
            "src_file": os.path.abspath(src_file),
            "ref_file": os.path.abspath(ref_file),
            "num_sentences": num_sentences,
        })

    manifest_path = os.path.join(output_dir, "manifest.json")
    with open(manifest_path, "w") as f:
        json.dump(manifest, f, indent=2)
    log.info(f"\nManifest: {len(manifest)} evaluation tasks written to {manifest_path}")
    return manifest


# ---------------------------------------------------------------------------
# Dataset downloaders
# ---------------------------------------------------------------------------

def download_flores200(output_dir):
    """Download FLORES-200 devtest for all available Indic language pairs."""
    from datasets import load_dataset

    log.info("=" * 60)
    log.info("Downloading FLORES-200 devtest")
    log.info("=" * 60)

    # FLORES-200 Indic languages (subset of our supported codes that exist in FLORES)
    flores_indic = [
        "hin_Deva", "ben_Beng", "tam_Taml", "tel_Telu", "kan_Knda",
        "mal_Mlym", "mar_Deva", "guj_Gujr", "pan_Guru", "urd_Arab",
        "ory_Orya", "asm_Beng", "npi_Deva", "san_Deva", "snd_Arab",
        "mai_Deva", "mni_Mtei", "kas_Deva", "bho_Deva", "mag_Deva",
        "hne_Deva", "awa_Deva", "doi_Deva",
        # New languages that might be in FLORES
        "brx_Deva", "sat_Olck", "kok_Deva", "tcy_Knda", "grt_Latn",
        "kha_Latn", "lus_Latn",
    ]

    count = 0
    for lang in flores_indic:
        if lang == "eng_Latn":
            continue
        try:
            # FLORES-200 uses language code as config name
            ds = load_dataset("facebook/flores", lang, split="devtest", trust_remote_code=True)
            en_col = "sentence"  # Will check the actual column names
            # Check column structure
            cols = ds.column_names
            if "sentence" in cols:
                # Single-language config: need to also load English
                ds_en = load_dataset("facebook/flores", "eng_Latn", split="devtest", trust_remote_code=True)
                en_sents = [row["sentence"] for row in ds_en]
                lang_sents = [row["sentence"] for row in ds]
            elif f"sentence_{lang}" in cols:
                en_sents = [row["sentence_eng_Latn"] for row in ds]
                lang_sents = [row[f"sentence_{lang}"] for row in ds]
            else:
                log.warning(f"  FLORES {lang}: unexpected columns {cols}")
                continue

            # Write both directions
            n1 = write_pair(output_dir, "flores200", "eng_Latn", lang, en_sents, lang_sents)
            n2 = write_pair(output_dir, "flores200", lang, "eng_Latn", lang_sents, en_sents)
            if n1 > 0:
                count += 2
        except Exception as e:
            log.warning(f"  FLORES {lang}: not available ({e})")

    log.info(f"FLORES-200: {count} direction pairs downloaded")
    return count


def download_in22(output_dir):
    """Download IN22-Gen and IN22-Conv from AI4Bharat."""
    from datasets import load_dataset

    log.info("=" * 60)
    log.info("Downloading IN22-Gen + IN22-Conv")
    log.info("=" * 60)

    count = 0
    for ds_name, hf_name in [("in22gen", "ai4bharat/IN22-Gen"),
                               ("in22conv", "ai4bharat/IN22-Conv")]:
        log.info(f"\n  --- {hf_name} ---")
        try:
            # Try loading without config to see available configs
            ds = load_dataset(hf_name, "all", split="test", trust_remote_code=True)
            cols = ds.column_names
            log.info(f"  Columns: {cols}")

            # IN22 typically has sentence columns for each language
            # Find all language columns
            lang_cols = [c for c in cols if c.startswith("sentence_") and c != "sentence_eng_Latn"]
            en_col = "sentence_eng_Latn" if "sentence_eng_Latn" in cols else None

            if en_col and lang_cols:
                en_sents = [row[en_col] for row in ds]
                for lc in lang_cols:
                    lang_code = lc.replace("sentence_", "")
                    if lang_code not in SUPPORTED_LANG_CODES:
                        continue
                    lang_sents = [row[lc] for row in ds]
                    write_pair(output_dir, ds_name, "eng_Latn", lang_code, en_sents, lang_sents)
                    write_pair(output_dir, ds_name, lang_code, "eng_Latn", lang_sents, en_sents)
                    count += 2
            else:
                log.warning(f"  {hf_name}: no sentence_eng_Latn column found")
        except Exception:
            # Try loading individual language pair configs
            in22_langs = [
                "asm_Beng", "ben_Beng", "brx_Deva", "doi_Deva", "guj_Gujr",
                "hin_Deva", "kan_Knda", "kas_Arab", "kas_Deva", "mai_Deva",
                "mal_Mlym", "mni_Mtei", "mar_Deva", "npi_Deva", "ory_Orya",
                "pan_Guru", "san_Deva", "sat_Olck", "snd_Arab", "tam_Taml",
                "tel_Telu", "urd_Arab",
            ]
            for lang in in22_langs:
                try:
                    config = f"eng_Latn-{lang}"
                    ds = load_dataset(hf_name, config, split="test", trust_remote_code=True)
                    cols = ds.column_names

                    en_col = next((c for c in cols if "eng" in c.lower()), None)
                    lang_col = next((c for c in cols if lang.split("_")[0] in c.lower()), None)

                    if not en_col or not lang_col:
                        # Try positional: first and second columns
                        if len(cols) >= 2:
                            en_col, lang_col = cols[0], cols[1]
                        else:
                            continue

                    en_sents = [row[en_col] for row in ds]
                    lang_sents = [row[lang_col] for row in ds]
                    write_pair(output_dir, ds_name, "eng_Latn", lang, en_sents, lang_sents)
                    write_pair(output_dir, ds_name, lang, "eng_Latn", lang_sents, en_sents)
                    count += 2
                except Exception as e:
                    log.debug(f"  {hf_name} {lang}: {e}")

    log.info(f"IN22: {count} direction pairs downloaded")
    return count


def download_pmindia(output_dir):
    """Download PMIndia parallel corpus and extract test splits."""
    log.info("=" * 60)
    log.info("Downloading PMIndia")
    log.info("=" * 60)

    PMINDIA_LANGS = {
        "as": "asm_Beng", "bn": "ben_Beng", "gu": "guj_Gujr",
        "hi": "hin_Deva", "kn": "kan_Knda", "ml": "mal_Mlym",
        "mr": "mar_Deva", "or": "ory_Orya", "pa": "pan_Guru",
        "ta": "tam_Taml", "te": "tel_Telu", "ur": "urd_Arab",
    }
    # Also try mni (Manipuri)
    # PMINDIA_LANGS["mni"] = "mni_Mtei"

    TEST_SIZE = 500  # Last 500 sentences as test split

    count = 0
    for iso, lang_code in PMINDIA_LANGS.items():
        url = f"http://data.statmt.org/pmindia/v1/parallel/pmindia.v1.{iso}-en.tsv"
        try:
            log.info(f"  Downloading {url}...")
            response = urllib.request.urlopen(url, timeout=60)
            content = response.read().decode("utf-8")
            lines = [l for l in content.strip().split("\n") if l.strip()]

            # Parse TSV: columns are typically en\tlang or lang\ten
            en_sents = []
            lang_sents = []
            for line in lines:
                parts = line.split("\t")
                if len(parts) >= 2:
                    en_sents.append(parts[0].strip())
                    lang_sents.append(parts[1].strip())

            if len(en_sents) < TEST_SIZE + 10:
                log.warning(f"  PMIndia {iso}: only {len(en_sents)} sentences, too few")
                continue

            # Use last TEST_SIZE as test set
            test_en = en_sents[-TEST_SIZE:]
            test_lang = lang_sents[-TEST_SIZE:]

            write_pair(output_dir, "pmindia", "eng_Latn", lang_code, test_en, test_lang)
            write_pair(output_dir, "pmindia", lang_code, "eng_Latn", test_lang, test_en)
            count += 2
        except Exception as e:
            log.warning(f"  PMIndia {iso}: download failed ({e})")

    log.info(f"PMIndia: {count} direction pairs downloaded")
    return count


def download_wat(output_dir):
    """Download WAT Indic multilingual test sets."""
    log.info("=" * 60)
    log.info("Downloading WAT test sets")
    log.info("=" * 60)

    # Try HuggingFace datasets for WAT
    try:
        from datasets import load_dataset
        # WAT 2021 Indic task data - try different sources
        # The official WAT data might not be on HuggingFace, try direct download
    except ImportError:
        pass

    WAT_LANGS = {
        "hi": "hin_Deva", "bn": "ben_Beng", "ta": "tam_Taml",
        "te": "tel_Telu", "ml": "mal_Mlym", "mr": "mar_Deva",
        "gu": "guj_Gujr", "pa": "pan_Guru", "or": "ory_Orya",
        "kn": "kan_Knda",
    }

    # Try downloading the WAT tarball
    wat_url = "http://lotus.kuee.kyoto-u.ac.jp/WAT/indic-multilingual/indic_wat_2021.tar.gz"
    count = 0

    try:
        log.info(f"  Downloading {wat_url}...")
        tmp_path = os.path.join(output_dir, "_wat_tmp.tar.gz")
        urllib.request.urlretrieve(wat_url, tmp_path)

        with tarfile.open(tmp_path, "r:gz") as tar:
            tar.extractall(path=os.path.join(output_dir, "_wat_extracted"))

        # Find test files in the extracted directory
        extracted_dir = os.path.join(output_dir, "_wat_extracted")
        test_files = {}
        for root, dirs, files in os.walk(extracted_dir):
            for f in files:
                if "test" in f.lower():
                    fpath = os.path.join(root, f)
                    test_files[f] = fpath
                    log.info(f"  Found: {f}")

        # Process test files
        for iso, lang_code in WAT_LANGS.items():
            # Look for en-{iso} or {iso}-en test files
            en_file = None
            lang_file = None
            for fname, fpath in test_files.items():
                if f".en" in fname or fname.endswith(".en"):
                    en_file = fpath
                if f".{iso}" in fname or fname.endswith(f".{iso}"):
                    lang_file = fpath

            if en_file and lang_file:
                with open(en_file) as f:
                    en_sents = [l.strip() for l in f if l.strip()]
                with open(lang_file) as f:
                    lang_sents = [l.strip() for l in f if l.strip()]
                if len(en_sents) == len(lang_sents):
                    write_pair(output_dir, "wat", "eng_Latn", lang_code, en_sents, lang_sents)
                    write_pair(output_dir, "wat", lang_code, "eng_Latn", lang_sents, en_sents)
                    count += 2

        # Cleanup
        import shutil
        shutil.rmtree(os.path.join(output_dir, "_wat_extracted"), ignore_errors=True)
        os.remove(tmp_path) if os.path.exists(tmp_path) else None

    except Exception as e:
        log.warning(f"  WAT download failed ({e}), trying alternative sources...")

        # Fallback: try loading from HuggingFace or skip
        try:
            from datasets import load_dataset
            ds = load_dataset("cfilt/iitb-english-hindi", split="test", trust_remote_code=True)
            if ds and len(ds) > 0:
                cols = ds.column_names
                en_col = next((c for c in cols if "en" in c.lower()), cols[0])
                hi_col = next((c for c in cols if "hi" in c.lower()), cols[1] if len(cols) > 1 else None)
                if hi_col:
                    en_sents = [row[en_col] for row in ds]
                    hi_sents = [row[hi_col] for row in ds]
                    write_pair(output_dir, "wat", "eng_Latn", "hin_Deva",
                              en_sents[:2000], hi_sents[:2000])
                    write_pair(output_dir, "wat", "hin_Deva", "eng_Latn",
                              hi_sents[:2000], en_sents[:2000])
                    count += 2
        except Exception as e2:
            log.warning(f"  WAT fallback also failed ({e2})")

    log.info(f"WAT: {count} direction pairs downloaded")
    return count


def download_samanantar(output_dir):
    """Download Samanantar test splits (last 1000 sentences)."""
    from datasets import load_dataset

    log.info("=" * 60)
    log.info("Downloading Samanantar (test splits)")
    log.info("=" * 60)

    SAMANANTAR_LANGS = {
        "as": "asm_Beng", "bn": "ben_Beng", "gu": "guj_Gujr",
        "hi": "hin_Deva", "kn": "kan_Knda", "ml": "mal_Mlym",
        "mr": "mar_Deva", "or": "ory_Orya", "pa": "pan_Guru",
        "ta": "tam_Taml", "te": "tel_Telu",
    }

    TEST_SIZE = 1000
    count = 0

    for iso, lang_code in SAMANANTAR_LANGS.items():
        try:
            log.info(f"  Loading samanantar/{iso}...")
            ds = load_dataset("ai4bharat/samanantar", iso, split="train", trust_remote_code=True)
            total = len(ds)
            if total < TEST_SIZE + 100:
                log.warning(f"  Samanantar {iso}: only {total} sentences, too few")
                continue

            # Take last TEST_SIZE as test
            test_data = ds.select(range(total - TEST_SIZE, total))
            en_sents = [row["src"] for row in test_data]
            lang_sents = [row["tgt"] for row in test_data]

            write_pair(output_dir, "samanantar", "eng_Latn", lang_code, en_sents, lang_sents)
            write_pair(output_dir, "samanantar", lang_code, "eng_Latn", lang_sents, en_sents)
            count += 2
        except Exception as e:
            log.warning(f"  Samanantar {iso}: failed ({e})")

    log.info(f"Samanantar: {count} direction pairs downloaded")
    return count


def download_bpcc(output_dir):
    """Download BPCC test data from AI4Bharat."""
    from datasets import load_dataset

    log.info("=" * 60)
    log.info("Downloading BPCC")
    log.info("=" * 60)

    count = 0

    # BPCC has multiple configs: bpcc-seed-latest, comparable, daily, ilci, etc.
    # Try bpcc-seed-latest first (most curated)
    bpcc_configs = ["bpcc-seed-latest"]

    for config in bpcc_configs:
        try:
            log.info(f"  Loading BPCC config: {config}...")
            ds = load_dataset("ai4bharat/BPCC", config, split="train", trust_remote_code=True)
            cols = ds.column_names
            log.info(f"  Columns: {cols}, size: {len(ds)}")

            # BPCC typically has 'src', 'tgt', 'src_lang', 'tgt_lang' or similar
            if "src" in cols and "tgt" in cols and "src_lang" in cols:
                # Group by language pair
                from collections import defaultdict
                pairs = defaultdict(lambda: {"src": [], "tgt": []})
                for row in ds:
                    src_lang = row.get("src_lang", "")
                    tgt_lang = row.get("tgt_lang", "")
                    key = (src_lang, tgt_lang)
                    pairs[key]["src"].append(row["src"])
                    pairs[key]["tgt"].append(row["tgt"])

                for (sl, tl), data in pairs.items():
                    # Map to language codes
                    src_code = ISO_TO_LANG.get(sl, sl)
                    tgt_code = ISO_TO_LANG.get(tl, tl)
                    if src_code in SUPPORTED_LANG_CODES and tgt_code in SUPPORTED_LANG_CODES:
                        # Use last 500 as test
                        test_size = min(500, len(data["src"]))
                        write_pair(output_dir, "bpcc", src_code, tgt_code,
                                  data["src"][-test_size:], data["tgt"][-test_size:])
                        count += 1
            elif "sentence_eng_Latn" in cols:
                # Multi-column format like IN22
                en_sents = [row["sentence_eng_Latn"] for row in ds]
                for col in cols:
                    if col.startswith("sentence_") and col != "sentence_eng_Latn":
                        lang_code = col.replace("sentence_", "")
                        if lang_code in SUPPORTED_LANG_CODES:
                            lang_sents = [row[col] for row in ds]
                            test_size = min(500, len(en_sents))
                            write_pair(output_dir, "bpcc", "eng_Latn", lang_code,
                                      en_sents[-test_size:], lang_sents[-test_size:])
                            write_pair(output_dir, "bpcc", lang_code, "eng_Latn",
                                      lang_sents[-test_size:], en_sents[-test_size:])
                            count += 2
            else:
                log.warning(f"  BPCC {config}: unexpected columns {cols}")

        except Exception as e:
            log.warning(f"  BPCC {config}: failed ({e})")
            log.warning(f"  (BPCC may require HuggingFace access agreement)")

    log.info(f"BPCC: {count} direction pairs downloaded")
    return count


def download_opus_bible(output_dir):
    """Download OPUS Bible alignments for low-resource languages."""
    log.info("=" * 60)
    log.info("Downloading OPUS Bible alignments")
    log.info("=" * 60)

    count = 0

    # OPUS Bible has limited Indic coverage. Try via opustools or direct download.
    # Focus on: Santali (sat), Bodo (brx), Ho (hoc), Munda (unr)
    # Most of these are unlikely to be in OPUS Bible, but we try.

    # Try using HuggingFace OPUS datasets
    try:
        from datasets import load_dataset

        # Helsinki-NLP/opus-100 has some Indic pairs
        opus_langs = {
            "hi": "hin_Deva", "bn": "ben_Beng", "ta": "tam_Taml",
            "te": "tel_Telu", "mr": "mar_Deva", "gu": "guj_Gujr",
            "ur": "urd_Arab", "ml": "mal_Mlym",
        }

        for iso, lang_code in opus_langs.items():
            config = f"en-{iso}"
            try:
                ds = load_dataset("Helsinki-NLP/opus-100", config, split="test",
                                 trust_remote_code=True)
                if len(ds) > 0:
                    cols = ds.column_names
                    # opus-100 has 'translation' dict with 'en' and '{iso}' keys
                    if "translation" in cols:
                        en_sents = [row["translation"]["en"] for row in ds]
                        lang_sents = [row["translation"][iso] for row in ds]
                    else:
                        continue

                    test_size = min(1000, len(en_sents))
                    write_pair(output_dir, "opus_bible", "eng_Latn", lang_code,
                              en_sents[:test_size], lang_sents[:test_size])
                    write_pair(output_dir, "opus_bible", lang_code, "eng_Latn",
                              lang_sents[:test_size], en_sents[:test_size])
                    count += 2
            except Exception as e:
                log.debug(f"  OPUS {config}: {e}")

    except Exception as e:
        log.warning(f"  OPUS Bible download failed ({e})")

    log.info(f"OPUS Bible: {count} direction pairs downloaded")
    return count


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

DATASET_FUNCTIONS = {
    "flores200": download_flores200,
    "in22": download_in22,
    "pmindia": download_pmindia,
    "wat": download_wat,
    "samanantar": download_samanantar,
    "bpcc": download_bpcc,
    "opus_bible": download_opus_bible,
}


def main():
    parser = argparse.ArgumentParser(description="Download evaluation datasets")
    parser.add_argument("--output-dir", default="eval/data",
                        help="Output directory for prepared datasets")
    parser.add_argument("--datasets", nargs="*", default=None,
                        choices=list(DATASET_FUNCTIONS.keys()),
                        help="Specific datasets to download (default: all)")
    args = parser.parse_args()

    os.makedirs(args.output_dir, exist_ok=True)

    datasets_to_download = args.datasets or list(DATASET_FUNCTIONS.keys())

    log.info(f"Downloading datasets: {', '.join(datasets_to_download)}")
    log.info(f"Output directory: {args.output_dir}")

    total_pairs = 0
    for ds_name in datasets_to_download:
        try:
            n = DATASET_FUNCTIONS[ds_name](args.output_dir)
            total_pairs += n
        except Exception as e:
            log.error(f"Failed to download {ds_name}: {e}")
            import traceback
            traceback.print_exc()

    # Generate manifest
    manifest = generate_manifest(args.output_dir)

    log.info("\n" + "=" * 60)
    log.info("DOWNLOAD COMPLETE")
    log.info("=" * 60)
    log.info(f"Total direction pairs: {total_pairs}")
    log.info(f"Total evaluation tasks in manifest: {len(manifest)}")
    log.info(f"Output: {args.output_dir}")


if __name__ == "__main__":
    main()
