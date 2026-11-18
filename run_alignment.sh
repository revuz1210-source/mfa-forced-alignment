#!/usr/bin/env bash
# Full MFA forced-alignment pipeline (Assignment 2a).
# Usage: bash run_alignment.sh [DATA_DIR] [OUT_DIR]
#   DATA_DIR must contain wav/ and transcripts/   (default: "Assignment 2a")
#   OUT_DIR  receives the TextGrids               (default: output_textgrids)
# Requires: montreal-forced-aligner installed in the active conda env.
set -euo pipefail

DATA_DIR="${1:-Assignment 2a}"
OUT_DIR="${2:-output_textgrids}"
DICT_NAME="${DICT_NAME:-english_us_arpa}"
ACOUSTIC="${ACOUSTIC:-english_us_arpa}"   # only english_us_arpa was tested
MFA_ROOT="${MFA_ROOT_DIR:-$HOME/Documents/MFA}"
WORK="$(pwd)"

echo "[1/6] Downloading pretrained models"
mfa model download dictionary "$DICT_NAME" || true
mfa model download acoustic   "$ACOUSTIC"  || true
mfa model download g2p        "$DICT_NAME" || true

echo "[2/6] Preparing corpus (wav + .txt side by side)"
rm -rf corpus && mkdir -p corpus dictionary
cp "$DATA_DIR"/wav/*.wav corpus/
for f in "$DATA_DIR"/transcripts/*; do
  b=$(basename "$f"); cp "$f" "corpus/${b%.*}.txt"
done
ls corpus

echo "[3/6] Validating corpus (reports OOV words)"
mfa validate corpus "$DICT_NAME" "$ACOUSTIC" --single_speaker --clean 2>&1 | grep -E "OOV|duration" || true

echo "[4/6] G2P for OOV words (for inspection; review before trusting)"
mfa g2p corpus "$DICT_NAME" dictionary/oov_pronunciations.txt --dictionary_path "$DICT_NAME" --clean
cat dictionary/oov_pronunciations.txt

echo "[5/6] Building custom dictionary = base dictionary + manual fixes"
cp "$MFA_ROOT/pretrained_models/dictionary/$DICT_NAME.dict" dictionary/custom.dict
cat custom_additions.dict >> dictionary/custom.dict

echo "[6/6] Aligning"
mfa align corpus dictionary/custom.dict "$ACOUSTIC" "$OUT_DIR" --clean --single_speaker --beam 100 --retry_beam 400
ls "$OUT_DIR"
