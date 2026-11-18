# Forced Alignment with Montreal Forced Aligner (Assignment 2a)

Aligns 6 English utterances (3 long read-speech recordings, 3 short ISLE utterances; about 97 s in total)
with their transcripts at word and phone level using MFA 3.4.4 and the pretrained `english_us_arpa`
dictionary and acoustic model, plus a small custom dictionary for out-of-vocabulary (OOV) words.

## Repository contents
```
wav/                    input audio
transcripts/            input transcripts
custom_additions.dict   manual pronunciations added to english_us_arpa
run_alignment.sh        full pipeline in one script
output_textgrids/       resulting TextGrids + alignment_analysis.csv
figures/                Praat screenshots used in the report
report.pdf              short report
```

## 1. Install MFA (Google Colab)
```python
!pip install -q condacolab
import condacolab
condacolab.install()          # the runtime restarts once, this is normal
```
After the restart:
```python
!conda install -c conda-forge montreal-forced-aligner -y
!pip install praatio
!mfa version                  # 3.4.4
```
(On a normal machine: `conda create -n aligner -c conda-forge montreal-forced-aligner`, then `conda activate aligner`.)

## 2. Download models
```bash
mfa model download dictionary english_us_arpa
mfa model download acoustic   english_us_arpa
mfa model download g2p        english_us_arpa
```

## 3. Prepare the data
MFA expects each `name.wav` next to a `name.txt`:
```bash
mkdir -p corpus
cp wav/*.wav corpus/
for f in transcripts/*; do b=$(basename "$f"); cp "$f" "corpus/${b%.*}.txt"; done
```

## 4. Check OOV words and build the custom dictionary
```bash
mfa validate corpus english_us_arpa english_us_arpa --single_speaker --clean
mfa g2p corpus english_us_arpa dictionary/oov_pronunciations.txt --dictionary_path english_us_arpa --clean
```
G2P output was reviewed by hand. It read the radio station "WBUR" as an ordinary word, so it was replaced by the
letter-by-letter pronunciation (W-B-U-R). `custom_additions.dict` holds the final entries, which are appended to a copy of the
base dictionary:
```bash
cp ~/Documents/MFA/pretrained_models/dictionary/english_us_arpa.dict dictionary/custom.dict
cat custom_additions.dict >> dictionary/custom.dict
```
Entries are tab separated (word, TAB, phones).

## 5. Align
```bash
mfa align corpus dictionary/custom.dict english_us_arpa output_textgrids --clean --single_speaker --beam 100 --retry_beam 400
```
`--single_speaker` is used because all files belong to one speaker label.

## One-command version
```bash
bash run_alignment.sh "Assignment 2a" output_textgrids
```

## 6. Inspect
Open a wav and its TextGrid in Praat (`Open > Read from file`, select both, `View & Edit`).
Praat shows the spectrogram only when 10 s or less is visible (`Time > Zoom...`).
`alignment_analysis.csv` has per-file log-likelihood, SNR and phone-duration deviation.

## Notes
- Only `english_us_arpa` was run. Other acoustic models were not tested; they use different phone sets, so
  the dictionary would have to match the model.
- Praat is only for viewing. Do not save changes back over the aligned TextGrids.
