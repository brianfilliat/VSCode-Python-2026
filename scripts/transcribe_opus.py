#!/usr/bin/env python3
"""
Batch transcribe .opus audio files (Spanish) to English text using local Whisper.

Usage examples:
  python scripts/transcribe_opus.py --src "D:\PIXS\___2024-08-10-FABIOLA\WhatsApp Chat - Mayra Galicia" --out transcriptions --model small

Notes:
- This script prefers the local `whisper` package (OpenAI Whisper). Install per README.
- Requires `ffmpeg` on PATH for conversion. The script converts .opus -> .wav before transcribing.
"""
import argparse
import os
import shlex
import shutil
import subprocess
import sys
import tempfile


def find_opus_files(src_dir):
    for root, dirs, files in os.walk(src_dir):
        for f in files:
            if f.lower().endswith('.opus'):
                yield os.path.join(root, f)


def ffmpeg_convert_to_wav(input_path, output_path):
    cmd = [
        'ffmpeg', '-y', '-hide_banner', '-loglevel', 'error',
        '-i', input_path,
        '-ar', '16000', '-ac', '1', output_path,
    ]
    subprocess.check_call(cmd)


def transcribe_with_whisper(model_name, wav_path):
    try:
        import whisper
    except Exception as e:
        raise RuntimeError('Local whisper not available: ' + str(e))
    model = whisper.load_model(model_name)
    # task='translate' translates to English; language='es' provides a hint
    result = model.transcribe(wav_path, task='translate', language='es')
    return result.get('text', '').strip()


def ensure_dir(path):
    os.makedirs(path, exist_ok=True)


def main():
    parser = argparse.ArgumentParser(description='Batch convert .opus (Spanish) → English text')
    parser.add_argument('--src', required=True, help='Source folder containing .opus files')
    parser.add_argument('--out', default='transcriptions', help='Output folder for .txt files')
    parser.add_argument('--model', default='small', help='Whisper model size (tiny, base, small, medium, large)')
    parser.add_argument('--keep-wav', action='store_true', help='Keep intermediate .wav files')
    parser.add_argument('--workers', type=int, default=1, help='Parallel workers (not implemented; reserved)')
    args = parser.parse_args()

    src = os.path.abspath(args.src)
    out = os.path.abspath(args.out)

    if not os.path.isdir(src):
        print('Source folder not found:', src, file=sys.stderr)
        sys.exit(2)

    # check ffmpeg
    if not shutil.which('ffmpeg'):
        print('ffmpeg not found on PATH. Install ffmpeg and retry.', file=sys.stderr)
        sys.exit(2)

    ensure_dir(out)

    opus_files = list(find_opus_files(src))
    if not opus_files:
        print('No .opus files found under', src)
        return

    print(f'Found {len(opus_files)} .opus files — writing text to {out} using model "{args.model}"')

    for opus in opus_files:
        base = os.path.splitext(os.path.basename(opus))[0]
        txt_path = os.path.join(out, base + '.txt')
        if os.path.exists(txt_path):
            print('Skipping (already exists):', txt_path)
            continue

        with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as tmp:
            wav_path = tmp.name
        try:
            print('Converting:', opus)
            ffmpeg_convert_to_wav(opus, wav_path)
            print('Transcribing:', opus)
            text = transcribe_with_whisper(args.model, wav_path)
            with open(txt_path, 'w', encoding='utf-8') as f:
                f.write(text + '\n')
            print('Saved:', txt_path)
        except subprocess.CalledProcessError as e:
            print('ffmpeg failed for', opus, '->', e, file=sys.stderr)
        except Exception as e:
            print('Transcription failed for', opus, '->', e, file=sys.stderr)
        finally:
            if args.keep_wav:
                keep_path = os.path.join(out, base + '.wav')
                shutil.move(wav_path, keep_path)
            else:
                try:
                    os.remove(wav_path)
                except Exception:
                    pass


if __name__ == '__main__':
    main()
