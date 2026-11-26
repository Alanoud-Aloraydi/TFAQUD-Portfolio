from pathlib import Path
import subprocess, json, html, math, sys

ROOT = Path(__file__).parent / 'edit'
ASSETS = ROOT / 'assets'
COMP = ROOT / 'compositions'
COMP.mkdir(exist_ok=True)

# Source in/out seconds; speed affects navigation only. Original footage is retained.
chapters = [
 ('daily', 'متابعة الرعاية اليومية', 'المهام اليومية وما يحتاج انتباهك', [(26, 42.0, 1.2)]),
 ('medicines', 'إدارة الأدوية', 'خطة الدواء وتفاصيل الجرعات', [(43, 48.7, 1), (81.8, 90.5, 1.2)]),
 ('appointments', 'تنظيم المواعيد', 'الموعد والمرافق في مكان واحد', [(51, 54.2, 1), (58, 60.5, 1), (64.3, 67.5, 1), (73.3, 77.8, 1)]),
 ('readings', 'تسجيل القياسات ومتابعتها', 'قراءات الضغط والسكر وسجلها', [(196.8, 202.8, 1), (94, 105, 1.15)]),
 ('visits', 'توثيق الزيارات', 'ملاحظات الزيارة والمذكرة الصوتية', [(109, 113, 1), (118, 129, 1.15)]),
 ('pdf', 'تصدير سجل الرعاية', 'اختيار البيانات وتجهيز التقرير', [(132.5, 140.5, 1)]),
 ('circles', 'إدارة دوائر الرعاية', 'أعضاء الدائرة والتبديل بين الدوائر', [(164.8, 172, 1), (293.8, 299.5, 1.2)]),
 ('profile', 'الملف الطبي', 'المعلومات الصحية وجهات اتصال الطوارئ', [(175, 177.7, 1), (227.5, 231.7, 1.1)]),
 ('emergency', 'بطاقة الطوارئ', 'الأدوية والحساسيات والمعلومات الأساسية', [(265.0, 265.8, 0.1333333333)]),
 ('notifications', 'التنبيهات وتقويم الجوال', 'تفعيل التنبيهات ومزامنة مواعيد الرعاية', [(277, 290, 1.15)]),
]

# Introduce the patient and care circle, then the plan, daily work and records.
feature_order = ['circles', 'profile', 'medicines', 'readings', 'appointments',
                 'daily', 'visits', 'pdf', 'emergency', 'notifications']
chapters.sort(key=lambda chapter: feature_order.index(chapter[0]))

def run(args):
    subprocess.run(args, check=True, stdout=subprocess.DEVNULL)

for slug, title, subtitle, cuts in chapters:
    pieces=[]
    for j,(a,b,speed) in enumerate(cuts):
        p=ASSETS/f'{slug}-{j}.mp4'
        frames=round((b-a)/speed*30)
        crop = 'crop=384:550:0:113,pad=384:848:0:140:color=0xF8F7FB,' if slug=='pdf' and j==1 else ''
        if '--reuse' not in sys.argv or slug in ('pdf', 'emergency') or not p.exists():
            run(['ffmpeg','-y','-hide_banner','-loglevel','error','-ss',str(a),'-t',str(b-a),'-i',str(ASSETS/'source.mp4'),'-an','-vf',crop+f'setpts=(PTS-STARTPTS)/{speed},fps=30','-frames:v',str(frames),'-c:v','libx264','-preset','fast','-crf','17','-g','30','-pix_fmt','yuv420p',str(p)])
        pieces.append(p)
    concat=ASSETS/f'{slug}.txt'
    concat.write_text(''.join(f"file '{p.name}'\n" for p in pieces),encoding='utf-8')
    run(['ffmpeg','-y','-hide_banner','-loglevel','error','-f','concat','-safe','0','-i',str(concat),'-c','copy','-movflags','+faststart',str(ASSETS/f'{slug}.mp4')])

font = "@font-face{font-family:'PlexArabic';src:url('assets/fonts/IBMPlexSansArabic-Regular.ttf');font-weight:400}@font-face{font-family:'PlexArabic';src:url('assets/fonts/IBMPlexSansArabic-SemiBold.ttf');font-weight:600}@font-face{font-family:'PlexArabic';src:url('assets/fonts/IBMPlexSansArabic-Bold.ttf');font-weight:700}"
style = font + """
#root{position:absolute;inset:0;font-family:'PlexArabic';color:#202734}
.heading{position:absolute;top:72px;right:108px;left:108px;height:120px;display:flex;align-items:center;gap:22px;direction:rtl}
.number{font-size:54px;font-weight:700;color:#3F2A65;background:#DCD2F0;min-width:88px;height:88px;display:flex;align-items:center;justify-content:center;border-radius:44px;flex-shrink:0}
.copy{direction:rtl;text-align:right;flex:1}
h1{font-size:48px;line-height:1.4;font-weight:700;margin:0;white-space:nowrap}
.subtitle{font-size:28px;line-height:1.6;color:#36415A;margin-top:3px;white-space:nowrap}
.phone{position:absolute;left:180px;top:220px;width:720px;height:1590px;object-fit:contain;border-radius:26px;box-shadow:0 15px 44px rgba(63,42,101,.14);clip-path:inset(96px 0 0 0)}
.progress{position:absolute;left:180px;top:1842px;width:720px;height:5px;background:#E1DDE9;overflow:hidden}
.progress-fill{height:100%;width:100%;background:#AB98D0;transform-origin:right center}
"""

timeline=[]
start=3.5
nums='٠١٢٣٤٥٦٧٨٩'
def arabic(n): return ''.join(nums[int(c)] for c in str(n))
for n,(slug,title,subtitle,cuts) in enumerate(chapters,1):
    data=json.loads(subprocess.check_output(['ffprobe','-v','quiet','-show_format','-of','json',str(ASSETS/f'{slug}.mp4')]))
    dur=round(float(data['format']['duration'])*30)/30
    timeline.append(dict(id=slug,feature=n,title=title,subtitle=subtitle,start=round(start,3),duration=dur,source_cuts=cuts))
    scene=f'''<template><style>{style}</style>
<div id="root" data-composition-id="{slug}" data-width="1080" data-height="1920">
<video id="{slug}-video" class="clip phone" src="assets/{slug}.mp4" data-start="0" data-duration="{dur}" data-track-index="0" muted playsinline></video>
<div id="{slug}-label" class="clip" data-start="0" data-duration="{dur}" data-track-index="1"><div id="{slug}-heading" class="heading"><div class="number">{arabic(n)}</div><div class="copy"><h1 data-var-text="title">{title}</h1><p class="subtitle" data-var-text="subtitle">{subtitle}</p></div></div></div>
<div class="progress" data-layout-ignore><div id="{slug}-progress" class="progress-fill"></div></div>
</div><script>
{{const tl=gsap.timeline({{paused:true}});
tl.fromTo('#{slug}-heading',{{clipPath:'inset(0 0 0 100%)'}},{{clipPath:'inset(0 0 0 0%)',duration:.38,ease:'power3.out'}},0);
tl.fromTo('#{slug}-progress',{{scaleX:0}},{{scaleX:1,duration:{dur-.04},ease:'none'}},0);
window.__timelines['{slug}']=tl;}}
</script></template>'''
    (COMP/f'{slug}.html').write_text(scene,encoding='utf-8')
    start+=dur

# A short real-screen opening; no invented product UI.
intro=f'''<template><style>{style}
.intro-title{{position:absolute;top:63px;right:108px;left:108px;direction:rtl;text-align:center;font-size:58px;font-weight:700}}
.intro-sub{{font-size:30px;font-weight:400;color:#36415A}}
</style><div id="root" data-composition-id="intro" data-width="1080" data-height="1920">
<video id="intro-video" class="clip phone" src="assets/source.mp4" data-media-start="26" data-start="0" data-duration="3.5" data-track-index="0" muted playsinline></video>
<div class="clip" data-start="0" data-duration="3.5" data-track-index="1"><div id="intro-title" class="intro-title">تفقّد<div class="intro-sub">رعاية تجمع العائلة</div></div></div>
</div><script>{{const tl=gsap.timeline({{paused:true}});tl.fromTo('#intro-title',{{opacity:0}},{{opacity:1,duration:.25}},0);window.__timelines['intro']=tl;}}</script></template>'''
(COMP/'intro.html').write_text(intro,encoding='utf-8')
outro=f'''<template><style>{font}
#root{{position:absolute;inset:0;font-family:'PlexArabic';background:#EFEAF8;color:#3F2A65;direction:rtl;text-align:center}}
#end-lockup{{position:absolute;top:650px;left:108px;right:108px}}
#end-word{{font-size:118px;font-weight:700;line-height:1.5}}
#end-line{{font-size:44px;line-height:1.7}}
#end-sub{{font-size:30px;color:#36415A;margin-top:45px}}
</style><div id="root" data-composition-id="outro" data-width="1080" data-height="1920">
<div class="clip" data-start="0" data-duration="4" data-track-index="0"><div id="end-lockup"><div id="end-word">تفقّد</div><div id="end-line">رعاية تجمع العائلة</div><div id="end-sub">الأدوية · القياسات · المواعيد</div></div></div>
</div><script>{{const tl=gsap.timeline({{paused:true}});tl.fromTo('#end-word',{{clipPath:'inset(0 0 100% 0)'}},{{clipPath:'inset(0 0 0% 0)',duration:.5,ease:'power3.out'}},0);tl.fromTo('#end-line',{{opacity:0}},{{opacity:1,duration:.4}},.35);tl.fromTo('#end-sub',{{opacity:0}},{{opacity:1,duration:.4}},.65);window.__timelines['outro']=tl;}}</script></template>'''
(COMP/'outro.html').write_text(outro,encoding='utf-8')
duration=round(start+4,3)
hosts=[f'<div id="intro" class="clip" data-composition-id="intro" data-composition-src="compositions/intro.html" data-start="0" data-duration="3.5" data-track-index="0" data-track-kind="graphics" data-width="1080" data-height="1920"></div>']
for c in timeline:
    variables=html.escape(json.dumps({'title':c['title'],'subtitle':c['subtitle']},ensure_ascii=False),quote=True)
    hosts.append(f'<div id="{c["id"]}" class="clip" data-composition-id="{c["id"]}" data-composition-src="compositions/{c["id"]}.html" data-start="{c["start"]}" data-duration="{c["duration"]}" data-track-index="0" data-track-kind="graphics" data-width="1080" data-height="1920" data-variable-values="{variables}"></div>')
hosts.append(f'<div id="outro" class="clip" data-composition-id="outro" data-composition-src="compositions/outro.html" data-start="{start:.3f}" data-duration="4" data-track-index="0" data-track-kind="graphics" data-width="1080" data-height="1920"></div>')

# A quiet catalog instrumental, repeated with 3-second overlaps to avoid hard seams.
run(['ffmpeg','-y','-hide_banner','-loglevel','error','-i',str(ASSETS/'music.wav'),'-i',str(ASSETS/'music.wav'),'-i',str(ASSETS/'music.wav'),'-filter_complex',f'[0:a][1:a]acrossfade=d=3:c1=tri:c2=tri[a];[a][2:a]acrossfade=d=3:c1=tri:c2=tri,atrim=duration={duration},loudnorm=I=-24:TP=-3:LRA=7,afade=t=in:d=1.5,afade=t=out:st={duration-3}:d=3[out]','-map','[out]','-c:a','aac','-b:a','192k',str(ASSETS/'soundtrack.m4a')])

page=f'''<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8"><meta name="viewport" content="width=1080,height=1920"><script src="https://cdn.jsdelivr.net/npm/gsap@3.15.0/dist/gsap.min.js"></script><style>*{{box-sizing:border-box;margin:0;padding:0}}html,body{{width:1080px;height:1920px;overflow:hidden;background:#F8F7FB}}#root{{position:relative;width:1080px;height:1920px}}.ground{{position:absolute;inset:0;background:#F8F7FB}}</style></head><body><div id="root" data-composition-id="main" data-start="0" data-duration="{duration}" data-width="1080" data-height="1920" data-fps="30"><div class="ground" data-layout-ignore></div>{''.join(hosts)}<audio id="music" class="clip" src="assets/soundtrack.m4a" data-start="0" data-duration="{duration}" data-track-index="2" data-volume="1"></audio></div><script>window.__timelines=window.__timelines||{{}};window.__timelines['main']=gsap.timeline({{paused:true}});</script></body></html>'''
(ROOT/'index.html').write_text(page,encoding='utf-8')
(ROOT/'edit-decision-list.json').write_text(json.dumps({'duration':duration,'fps':30,'chapters':timeline},ensure_ascii=False,indent=2),encoding='utf-8')
(ROOT/'SPEC.md').write_text(f'''# TFAQUD Arabic demo edit
GOAL: Show ten real features using only the supplied recording.
OUTPUT: HyperFrames, 1080 x 1920, 30 fps; {duration} seconds.
LOOK: #F8F7FB canvas, #202734 ink, #3F2A65 violet, #DCD2F0 number background. IBM Plex Sans Arabic 48px bold headings, 28px regular supporting text; video 720 x 1590 at (180,220).
MOTION: 0.38s right-to-left title wipe, power3.out; source cuts 1x to 1.5x; emergency card slowed to preserve a readable hold. Source actions remain in their recorded sequence within each retained cut.
SOUND: HeyGen catalog warm healthcare piano/light strings, id 7c7c9903947c472e9568a88fe44bc24a; -24 LUFS target. No voiceover. Source is effectively silent (-91 dB mean).
SHOTS: See edit-decision-list.json for every source in/out and final chapter time.
BANNED: fabricated UI, captions over buttons, dark empty background, neon, 3D phone tilt, constant drifting text, WhatsApp recipient sheets, OTP entry and repeated typing.
QA: Inspect each chapter midpoint, opening, ending, and transition frames. Arabic must shape right-to-left and titles must remain above footage.
LIMITS: Source is 384 x 848, compressed by WhatsApp. Upscaling does not restore lost detail. Simplified Mode and successful dose/reading confirmations are not present in the retained footage.
''',encoding='utf-8')
print(json.dumps({'duration':duration,'chapters':len(timeline)},ensure_ascii=False))
