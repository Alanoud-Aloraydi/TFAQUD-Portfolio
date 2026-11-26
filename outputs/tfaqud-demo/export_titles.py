from pathlib import Path
import json

root = Path(__file__).parent
data = json.loads((root / 'edit/edit-decision-list.json').read_text(encoding='utf-8'))

def stamp(seconds):
    milliseconds = round(seconds * 1000)
    seconds, ms = divmod(milliseconds, 1000)
    minutes, sec = divmod(seconds, 60)
    hours, minute = divmod(minutes, 60)
    return f'{hours:02}:{minute:02}:{sec:02},{ms:03}'

parts = []
for index, chapter in enumerate(data['chapters'], 1):
    start = chapter['start']
    end = start + chapter['duration']
    number = str(index).translate(str.maketrans('0123456789', '٠١٢٣٤٥٦٧٨٩'))
    parts.append(f"{index}\n{stamp(start)} --> {stamp(end)}\n{number}. {chapter['title']}")
(root / 'TFAQUD-features-ar.srt').write_text('\n\n'.join(parts) + '\n', encoding='utf-8-sig')
print('Saved Arabic feature titles')
