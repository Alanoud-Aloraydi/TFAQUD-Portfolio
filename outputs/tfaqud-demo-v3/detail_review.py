from pathlib import Path
import subprocess
from PIL import Image, ImageDraw

root=Path(__file__).parent
source=Path('C:/Users/alano/Downloads/WhatsApp Video 2026-11-23 at 11.34.18 PM.mp4')
for name,start,end in [('export',290,306),('emergency',358,387),('simplified',399,470)]:
    folder=root/'review'/name
    folder.mkdir(exist_ok=True)
    interval=1 if name!='simplified' else 2
    subprocess.run(['ffmpeg','-y','-hide_banner','-loglevel','error','-ss',str(start),'-t',str(end-start),'-i',str(source),'-vf',f'fps=1/{interval},scale=192:424',str(folder/'frame-%03d.jpg')],check=True)
    files=sorted(folder.glob('frame-*.jpg'))
    for page in range((len(files)+19)//20):
        canvas=Image.new('RGB',(1020,1820),'#202734')
        draw=ImageDraw.Draw(canvas)
        for j,f in enumerate(files[page*20:(page+1)*20]):
            t=start+(int(f.stem.split('-')[-1])-.5)*interval
            canvas.paste(Image.open(f),(j%5*204,j//5*455+26))
            draw.text((j%5*204+8,j//5*455+5),f'{t:.1f}s',fill='white')
        canvas.save(folder/f'contact-{page}.jpg')
