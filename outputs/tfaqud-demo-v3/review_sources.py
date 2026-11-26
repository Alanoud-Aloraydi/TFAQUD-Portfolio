from pathlib import Path
import subprocess
from PIL import Image, ImageDraw

root = Path(__file__).parent
sources = [
    ('01', Path('C:/Users/alano/Downloads/WhatsApp Video 2026-11-23 at 11.29.53 PM.mp4'), 1),
    ('02', Path('C:/Users/alano/Downloads/WhatsApp Video 2026-11-23 at 11.34.18 PM.mp4'), 5),
    ('03', Path('C:/Users/alano/Downloads/WhatsApp Video 2026-11-23 at 11.42.34 PM.mp4'), .5),
]
for name, source, interval in sources:
    folder = root / 'review' / name
    folder.mkdir(exist_ok=True)
    subprocess.run(['ffmpeg','-y','-hide_banner','-loglevel','error','-i',str(source),'-vf',f'fps=1/{interval},scale=192:424',str(folder/'frame-%03d.jpg')],check=True)
    files=sorted(folder.glob('frame-*.jpg'))
    for page in range((len(files)+19)//20):
        group=files[page*20:(page+1)*20]
        canvas=Image.new('RGB',(1020,1820),'#202734')
        draw=ImageDraw.Draw(canvas)
        for j,f in enumerate(group):
            index=int(f.stem.split('-')[-1])-1
            time=(index+.5)*interval
            canvas.paste(Image.open(f),(j%5*204,j//5*455+26))
            draw.text((j%5*204+8,j//5*455+5),f'{int(time)//60}:{time%60:04.1f} | {name}',fill='white')
        canvas.save(folder/f'contact-{page}.jpg')
    with (folder/'audio.txt').open('w') as log:
        subprocess.run(['ffmpeg','-hide_banner','-i',str(source),'-vn','-af','volumedetect','-f','null','NUL'],stderr=log,stdout=subprocess.DEVNULL,check=True)
print('Source contact sheets and audio measurements saved')
