"""Verify the finished file, notification cues and representative frames."""
from pathlib import Path
import hashlib
import json
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw

BASE = Path(__file__).resolve().parent
NOTIFICATION_ONLY = '--notification-only' in sys.argv
VIDEO = BASE / ('TFAQUD-demo-notification-only-ar.mp4' if NOTIFICATION_ONLY else 'TFAQUD-demo-new-ar.mp4')
OUT = BASE / 'review' / ('delivery-notification-only' if NOTIFICATION_ONLY else 'delivery')
OUT.mkdir(exist_ok=True)

def run(*args):
    return subprocess.check_output(list(args))

meta = json.loads(run('ffprobe', '-v', 'error', '-show_format', '-show_streams', '-of', 'json', str(VIDEO)))
v = next(s for s in meta['streams'] if s['codec_type'] == 'video')
a = next(s for s in meta['streams'] if s['codec_type'] == 'audio')
assert (v['width'], v['height'], v['codec_name'], v['avg_frame_rate']) == (1080, 1920, 'h264', '30/1')
assert a['codec_name'] == 'aac'
assert abs(float(meta['format']['duration']) - 190.833) < 0.1

def mono(path):
    return np.frombuffer(run('ffmpeg', '-hide_banner', '-loglevel', 'error', '-i', str(path), '-vn', '-ac', '1', '-ar', '16000', '-f', 'f32le', '-'), dtype='<f4')

audio = mono(VIDEO)
reference = mono(BASE / 'edit' / 'assets' / 'chime.wav')
cues = []
for cue in (0.08, 183.18):
    # Find the same chime within 20 ms of its authored onset. AAC may shift a few samples.
    best = (-1, None)
    for shift in range(-320, 321):
        start = round(cue * 16000) + shift
        observed = audio[start:start + len(reference)]
        corr = float(np.dot(observed, reference) / np.sqrt(np.dot(observed, observed) * np.dot(reference, reference)))
        if corr > best[0]:
            best = (corr, start / 16000)
    assert best[0] > 0.95, best
    cues.append({'authored_seconds': cue, 'detected_seconds': best[1], 'correlation': best[0]})

quiet_peak = None
if NOTIFICATION_ONLY:
    quiet = np.concatenate([audio[round(1.7 * 16000):round(183.0 * 16000)], audio[round(184.8 * 16000):]])
    quiet_peak = float(np.max(np.abs(quiet)))
    assert quiet_peak < 1e-5, quiet_peak

times = ([0.5, 2.5, 2.6, 34, 117, 122.5, 156, 183.2, 184.3, 184.5, 185, 189]
         if NOTIFICATION_ONLY else [0.5, 11, 34, 70, 105, 117, 122.5, 147, 156, 169, 178, 184, 189])
sheet = Image.new('RGB', (1080, 4 * 505), '#eee')
draw = ImageDraw.Draw(sheet)
for i, t in enumerate(times):
    dest = OUT / f'frame-{t:06.2f}.jpg'
    subprocess.run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-ss', str(t), '-i', str(VIDEO), '-frames:v', '1', '-q:v', '2', str(dest)], check=True)
    im = Image.open(dest)
    if NOTIFICATION_ONLY and t in (0.5, 184.3):
        pixels = np.asarray(im).astype(float)
        background = pixels[400:1800].copy()
        mask = np.ones(background.shape[:2], dtype=bool)
        mask[458:694, 136:944] = False  # White notification card plus codec-edge margin.
        deviation = np.abs(background[mask] - np.array([248, 247, 251]))
        assert np.percentile(deviation, 99.99) < 6, 'Unexpected phone background outside notification'
    im.thumbnail((270, 480))
    x, y = (i % 4) * 270, (i // 4) * 505
    sheet.paste(im, (x, y))
    draw.text((x + 5, y + 481), f'{t:.2f} seconds', fill='black')
sheet.save(OUT / 'contact-sheet.jpg', quality=90)

report = {
    'file': str(VIDEO),
    'bytes': VIDEO.stat().st_size,
    'sha256': hashlib.sha256(VIDEO.read_bytes()).hexdigest(),
    'duration_seconds': float(meta['format']['duration']),
    'video': {k: v[k] for k in ('codec_name', 'width', 'height', 'avg_frame_rate', 'nb_frames')},
    'audio': {k: a[k] for k in ('codec_name', 'sample_rate', 'channels')},
    'notification_cues': cues,
    'mono_peak_dbfs': float(20 * np.log10(np.max(np.abs(audio)))),
    'notification_only': NOTIFICATION_ONLY,
    'peak_outside_chime_windows': quiet_peak,
    'decoded_visual_sample_times': times,
}
(OUT / 'verification.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print(json.dumps(report, indent=2))
