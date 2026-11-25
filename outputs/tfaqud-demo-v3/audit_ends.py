from pathlib import Path
import subprocess, json
from PIL import Image, ImageDraw

base=Path(__file__).parent
edl=json.loads((base/'edit/edit-decision-list.json').read_text(encoding='utf-8'))
folder=base/'review/cut-ends'
folder.mkdir(exist_ok=True)
shots=[]
for chapter in edl['chapters']:
    for i,cut in enumerate(chapter['cuts']):
        image=folder/f'{chapter["number"]:02}-{i}.jpg'
        subprocess.run(['ffmpeg','-y','-hide_banner','-loglevel','error','-sseof','-0.1','-i',str(base/f'edit/assets/{chapter["id"]}-{i}.mp4'),'-frames:v','1','-vf','scale=192:399',str(image)],check=True)
        shots.append((image,f'{chapter["number"]:02}/{i} {cut["source"]}:{cut["source_out"]}'))
for page in range((len(shots)+19)//20):
    canvas=Image.new('RGB',(1020,1740),'#202734')
    draw=ImageDraw.Draw(canvas)
    for j,(image,label) in enumerate(shots[page*20:(page+1)*20]):
        canvas.paste(Image.open(image),(j%5*204,j//5*435+26))
        draw.text((j%5*204+6,j//5*435+6),label,fill='white')
    canvas.save(folder/f'contact-{page}.jpg')
print('Audited',len(shots),'retained cut endings')
