#!/usr/bin/env bash
# Master Pipeline Shell Script
# Runs IndicTrans2 in sih-venv312 -> saves translation -> runs Quipus TTS in quipus-venv312

set -e

TEXT="${1:-कर्म करो, फल की चिंता मत करो।}"

echo "======================================================================"
echo "  SIH PROBLEM STATEMENT 26042 — FULL TEXT & VOICE SANTALI PIPELINE"
echo "======================================================================"
echo "Input Hindi Sentence: $TEXT"
echo ""

# Step 1: Run IndicTrans2 Translation in sih-venv312
echo "[STEP 1/2] Translating Hindi -> Santali Ol Chiki (sih-venv312)..."
/mnt/f/SIH/SIH_Translator/sih-venv312/bin/python3 /mnt/f/SIH/SIH_Translator/run_live_translation.py "$TEXT"

# Read translation result
SANTALI_TEXT=$(cat /mnt/f/SIH/SIH_Translator/live_translation_result.txt)
echo "  -> Santali Translation: $SANTALI_TEXT"
echo ""

# Step 2: Run Quipus TTS in quipus-venv312
echo "[STEP 2/2] Synthesizing Santali Voice Audio (quipus-venv312)..."
/home/vaseem/quipus-venv312/bin/python3 /mnt/f/SIH/SIH_Translator/run_live_tts.py "$SANTALI_TEXT"

echo "======================================================================"
echo "  SUCCESS! SANTALI AUDIO GENERATED AT:"
echo "  F:\\SIH\\SIH_Translator\\test_audio\\tts_outputs\\live_karma_phulmani.wav"
echo "======================================================================"
