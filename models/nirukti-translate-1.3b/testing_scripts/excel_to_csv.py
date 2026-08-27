#!/usr/bin/env python3
"""
Convert ASR Translation Testing Excel file to CSV + evaluation manifest.

Reads the Excel file with 47 language-specific sheets, filters out rows
containing "/" (multiple translation variants), and produces:
  1. A unified CSV with all filtered data
  2. Per-language .src/.ref files for the evaluation runner
  3. A manifest.json compatible with run_evaluation.py

Usage:
    conda run -n base python eval/excel_to_csv.py \
        --input eval/ASR_Translation_Testing_dataset_3rdMarch2026.xlsx \
        --output-dir eval/data/asr_test
"""

import argparse
import csv
import json
import os

import pandas as pd

# Language name (sheet name) → language code mapping
# Source: inference/matrix_evaluate.py LANGUAGE_TO_CODE dict
LANG_TO_CODE = {
    "Ahirani": "ahr_Deva",
    "Assamese": "asm_Beng",
    "Awadhi": "awa_Deva",
    "Bagheli": "bfy_Deva",
    "Bagri": "bgq_Deva",
    "Banjari": "lmn_Deva",
    "Bengali": "ben_Beng",
    "Bhili": "bhb_Deva",
    "Bhojpuri": "bho_Deva",
    "Bodo": "brx_Deva",
    "Brajbhasha": "bra_Deva",
    "Bundeli": "bns_Deva",
    "Chhatisgarhi": "hne_Deva",
    "Dogri": "doi_Deva",
    "Garhwali": "gbm_Deva",
    "Garo": "grt_Latn",
    "Gujarati": "guj_Gujr",
    "Haryanvi": "bgc_Deva",
    "Hindi": "hin_Deva",
    "Kangri": "xnr_Deva",
    "Kannada": "kan_Knda",
    "Kashmiri": "kas_Deva",
    "Khortha": "kho_Deva",
    "Konkani": "kok_Deva",
    "Kumaoni": "kfy_Deva",
    "Kurukh": "kru_Deva",
    "Magahi": "mag_Deva",
    "Maithili": "mai_Deva",
    "Malayalam": "mal_Mlym",
    "Manipuri": "mni_Beng",
    "Marathi": "mar_Deva",
    "Marwadi": "mwr_Deva",
    "Mewari": "mtr_Deva",
    "Nepali": "npi_Deva",
    "Nimadi": "noe_Deva",
    "Odia": "ory_Orya",
    "Punjabi": "pan_Guru",
    "Rajasthani": "raj_Deva",
    "Sambalpuri": "spv_Orya",
    "Sanskrit": "san_Deva",
    "Santali": "sat_Olck",
    "Sindhi": "snd_Arab",
    "Surgujia": "sgj_Deva",
    "Tamil": "tam_Taml",
    "Telugu": "tel_Telu",
    "Tulu": "tcy_Knda",
    "Urdu": "urd_Arab",
}


def main():
    parser = argparse.ArgumentParser(
        description="Convert ASR Translation Testing Excel to CSV + manifest"
    )
    parser.add_argument("--input", required=True, help="Path to Excel file")
    parser.add_argument("--output-dir", required=True, help="Output directory")
    args = parser.parse_args()

    os.makedirs(args.output_dir, exist_ok=True)

    print("=" * 70)
    print("ASR Translation Testing Dataset — Excel to CSV")
    print("=" * 70)

    xl = pd.ExcelFile(args.input, engine="openpyxl")
    print(f"Sheets found: {len(xl.sheet_names)}")

    all_rows = []
    manifest = []
    total_kept = 0
    total_filtered = 0

    for sheet_name in xl.sheet_names:
        lang_code = LANG_TO_CODE.get(sheet_name)
        if lang_code is None:
            print(f"  WARNING: No language code for sheet '{sheet_name}', skipping")
            continue

        df = xl.parse(sheet_name, header=0)

        # Use positional access: col 0=ID, col 1=English, col 2=Language
        id_col = df.iloc[:, 0]
        eng_col = df.iloc[:, 1]
        lang_col = df.iloc[:, 2]

        kept_eng = []
        kept_lang = []
        kept_ids = []
        n_filtered = 0

        for i in range(len(df)):
            eng_val = str(eng_col.iloc[i]).strip() if pd.notna(eng_col.iloc[i]) else ""
            lang_val = str(lang_col.iloc[i]).strip() if pd.notna(lang_col.iloc[i]) else ""
            id_val = id_col.iloc[i]

            # Skip empty rows
            if not eng_val or not lang_val:
                continue

            # Skip rows with "/" in either column
            if "/" in eng_val or "/" in lang_val:
                n_filtered += 1
                continue

            kept_eng.append(eng_val)
            kept_lang.append(lang_val)
            kept_ids.append(id_val)
            all_rows.append({
                "language": sheet_name,
                "lang_code": lang_code,
                "id": id_val,
                "english": eng_val,
                "translation": lang_val,
            })

        total_kept += len(kept_eng)
        total_filtered += n_filtered

        # Write per-language .src and .ref files
        src_file = os.path.join(
            args.output_dir, f"asr_test_eng_Latn_{lang_code}.src"
        )
        ref_file = os.path.join(
            args.output_dir, f"asr_test_eng_Latn_{lang_code}.ref"
        )

        with open(src_file, "w", encoding="utf-8") as f:
            for s in kept_eng:
                f.write(s + "\n")
        with open(ref_file, "w", encoding="utf-8") as f:
            for s in kept_lang:
                f.write(s + "\n")

        manifest.append({
            "dataset": "asr_test",
            "src_lang": "eng_Latn",
            "tgt_lang": lang_code,
            "src_file": os.path.abspath(src_file),
            "ref_file": os.path.abspath(ref_file),
            "num_sentences": len(kept_eng),
        })

        print(
            f"  {sheet_name:<15s} ({lang_code}): "
            f"{len(kept_eng):>3d} kept, {n_filtered:>2d} filtered"
        )

    # Write unified CSV
    csv_path = os.path.join(args.output_dir, "asr_test_dataset.csv")
    with open(csv_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(
            f, fieldnames=["language", "lang_code", "id", "english", "translation"]
        )
        writer.writeheader()
        writer.writerows(all_rows)

    # Write manifest
    manifest_path = os.path.join(args.output_dir, "manifest.json")
    with open(manifest_path, "w") as f:
        json.dump(manifest, f, indent=2)

    print(f"\n{'=' * 70}")
    print(f"Total rows kept:     {total_kept:,}")
    print(f"Total rows filtered: {total_filtered:,} (contained '/')")
    print(f"Languages:           {len(manifest)}")
    print(f"CSV:                 {csv_path}")
    print(f"Manifest:            {manifest_path}")
    print(f"{'=' * 70}")


if __name__ == "__main__":
    main()
