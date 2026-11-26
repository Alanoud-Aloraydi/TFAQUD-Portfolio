"""Assemble the two revised HyperFrames spans and a chime-only audio track."""
from pathlib import Path
import json
import subprocess

BASE = Path(__file__).resolve().parent
PARTS = BASE / 'review' / 'notification-only'
OLD = BASE / 'TFAQUD-demo-new-ar.mp4'
OUT = BASE / 'TFAQUD-demo-notification-only-ar.mp4'

for name, frames in [('opening.mp4', 78), ('return.mp4', 42)]:
    meta = json.loads(subprocess.check_output([
        'ffprobe', '-v', 'error', '-show_streams', '-of', 'json', str(PARTS / name)]))
    video = next(s for s in meta['streams'] if s['codec_type'] == 'video')
    assert int(video['nb_frames']) == frames, (name, video)

duration = 5725 / 30
filters = (
    '[0:v]trim=end_frame=78,setpts=PTS-STARTPTS[v0];'
    '[1:v]trim=end_frame=5415,setpts=PTS-STARTPTS[v1];'
    '[2:v]trim=end_frame=42,setpts=PTS-STARTPTS[v2];'
    '[3:v]trim=end_frame=190,setpts=PTS-STARTPTS[v3];'
    '[v0][v1][v2][v3]concat=n=4:v=1:a=0[v];'
    '[4:a]aformat=sample_rates=48000:channel_layouts=stereo,volume=0.8,asplit=2[c1][c2];'
    '[c1]adelay=80|80[chime1];'
    '[c2]adelay=183180|183180[chime2];'
    f'anullsrc=r=48000:cl=stereo:d={duration}[silence];'
    '[silence][chime1][chime2]amix=inputs=3:normalize=0:duration=first[a]'
)
cmd = [
    'ffmpeg', '-hide_banner', '-y',
    '-i', str(PARTS / 'opening.mp4'),
    '-ss', '2.6', '-t', '180.5', '-i', str(OLD),
    '-i', str(PARTS / 'return.mp4'),
    '-ss', '184.5', '-t', str(190 / 30), '-i', str(OLD),
    '-i', str(BASE / 'edit' / 'assets' / 'chime.wav'),
    '-filter_complex', filters, '-map', '[v]', '-map', '[a]',
    '-c:v', 'libx264', '-preset', 'fast', '-crf', '17', '-threads', '2',
    '-pix_fmt', 'yuv420p', '-r', '30', '-frames:v', '5725',
    '-c:a', 'aac', '-b:a', '192k', '-t', str(duration),
    '-movflags', '+faststart', str(OUT),
]
(PARTS / 'assembly-command.json').write_text(json.dumps(cmd, indent=2), encoding='utf-8')
with (PARTS / 'assembly.log').open('w', encoding='utf-8') as log:
    subprocess.run(cmd, stdout=log, stderr=log, check=True)
print(OUT)
