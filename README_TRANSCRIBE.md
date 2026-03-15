Batch convert .opus (Spanish) → English text

Quick summary
- The `scripts/transcribe_opus.py` script converts `.opus` files to temporary `.wav` files and uses OpenAI Whisper (local model) to translate Spanish audio into English text files.
- It requires `ffmpeg` on PATH and the Whisper Python package.

Install (Windows - PowerShell)
1. Install ffmpeg (e.g., via Chocolatey):
```powershell
choco install ffmpeg -y
```

2. Create a virtualenv and install requirements:
```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install --upgrade pip
pip install -r scripts\requirements.txt
```

If `openai-whisper` is not available or you'd rather use another method, see the notes section.

Run the script
```powershell
python scripts\transcribe_opus.py --src "D:\PIXS\___2024-08-10-FABIOLA\WhatsApp Chat - Mayra Galicia" --out "D:\PIXS\___2024-08-10-FABIOLA\transcriptions" --model small
```

Options
- `--model`: whisper model size (`tiny`, `base`, `small`, `medium`, `large`). Larger models are slower but more accurate.
- `--keep-wav`: keep the converted `.wav` files next to the final `.txt` files.

Notes / Alternatives
- If you prefer using the OpenAI hosted API, you can adapt the script to call the API instead of local whisper; you'll need an `OPENAI_API_KEY` and slightly different code. Consider this if you cannot install or run local models.
- For large batches or faster performance, install GPU drivers and run Whisper on a machine with a GPU.

If you want, I can:
- Convert the folder here (I don't have direct access to your D: drive) — instead I can produce a one-line PowerShell loop that will run this script across files.
- Provide an OpenAI-API-based variant that uses `whisper-1` (you must supply `OPENAI_API_KEY`).
