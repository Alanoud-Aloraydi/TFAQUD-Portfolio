from pathlib import Path
import subprocess, json, html, math, shutil

BASE=Path(__file__).parent
ROOT=BASE/'edit'
ASSETS=ROOT/'assets'
COMP=ROOT/'compositions'
COMP.mkdir(exist_ok=True)

# In/out ranges stay in the user's order. Only the report section is replaced,
# exactly where it occurs, with the earlier recording requested by the user.
# Each cut: source id, in, out, speed; optional fifth item isolates PDF content.
chapters=[
 ('notification','تنبيه الجرعة','حين يحين','موعد الجرعة','تنبيه يفتح المهمة، وتأكيد يحفظ الاستجابة',
  [('01',.15,2.75,1),('01',6.8,11.75,1.15),('01',12.0,13.55,1)]),
 ('circle','إنشاء دائرة الرعاية','رعايتك تبدأ','بدائرة واضحة','أنشئ دائرتك وأكمل البيانات الأساسية',
  [('02',7,9.3,1),('02',11.4,15.9,1.4),('02',18.5,22.8,1.2)]),
 ('profile','الملف الطبي','ملفك الطبي،','واضح ومحدّث','فصيلة الدم والحالات المزمنة والحساسيات',
  [('02',24.7,28.2,1.5),('02',30.4,33.6,1.3),('02',36.7,41.8,1.3)]),
 ('medicine','جدولة الدواء','من اسم الدواء','إلى موعد الجرعة','الجرعة والتكرار والتنبيه ضمن خطة واحدة',
  [('02',52,54.6,1.5),('02',56.7,60.7,1.5),('02',63.4,65.9,1.3),('02',67.3,73.5,1.3),('02',76.2,83.4,1.3)]),
 ('measurement-plan','خطة القياس','موعد للقياس،','ونطاق للمقارنة','اضبط الجدول والتكرار والنطاق المحدّد',
  [('02',86.1,89.8,1.5),('02',94.1,98.6,1.5),('02',104.3,112.2,1.3),('02',116.5,120.4,1.2)]),
 ('first-reading','تسجيل القراءة','تُحفظ القراءة،','ويبدأ سجلّها','النتيجة محفوظة مع وقت القياس وسياقه',
  [('02',132.3,135.2,1.5),('02',139.9,143.3,1.4),('02',146,155.2,1.3)]),
 ('appointment','تنظيم المواعيد','كل موعد،','بتفاصيله ومرافقه','المكان والتذكير والمرافق قبل الزيارة',
  [('02',161,164.8,1.4),('02',170.7,173.6,1.4),('02',183.8,186.3,1.4),('02',193.1,201.7,1.5),('02',204.6,207.9,1.2)]),
 ('extra-dose','تسجيل جرعة إضافية','جرعة خارج الجدول؟','لها سجل أيضًا','احفظ الدواء والكمية ووقت أخذ الجرعة',
  [('02',210.6,219.2,1.3)]),
 ('quick-reading','قراءة عند الحاجة','قراءة جديدة','في سجلّك الصحي','أدخل النتيجة واحفظها بوقتها',
  [('02',221.5,224,1.3),('02',245.2,249.2,1.4),('02',252.4,260.2,1.3)]),
 ('history','مراجعة سجل القياسات','راجع التغيّر،','قراءة بعد أخرى','قراءات محفوظة ورسم يوضح تغيّرها',
  [('02',263,275.8,1.4)]),
 ('permissions','أعضاء الدائرة وصلاحياتهم','المشاركة في الرعاية','بصلاحيات واضحة','حدّد ما يستطيع كل عضو تعديله',
  [('02',278.7,284.3,1)]),
 ('export','تصدير سجل الرعاية','اختر ما تشاركه','من سجلّك الصحي','مثال على تجهيز التقرير ومحتوى ملف PDF',
  [('old',135.0,139.0,1.2),('old',140.2,141.8,1),('old',151.5,154.0,1,'pdf')]),
 ('switch-circle','التبديل بين الدوائر','كل مريض،','ودائرة رعايته','انتقل بين الدوائر وتابع أعضاء كل مريض',
  [('02',303.2,305.0,1),('02',310.3,314.8,1.1)]),
 ('visit','ورقة الزيارة والمذكرة الصوتية','الزيارة لا تنتهي','عند الموعد','ملاحظات ومذكرة صوتية للرجوع إليها',
  [('02',319.4,321.9,1),('02',324.7,327,1.2),('02',330.4,338.8,1.3)]),
 ('settings','التنبيهات وتقويم الجوال','تذكيراتك،','على جوالك وتقويمك','التحكم بالتنبيهات ومزامنة الدائرة',
  [('02',343.0,343.8,1),('02',346.3,350.2,1)]),
 ('emergency','بطاقة الطوارئ','بطاقة واحدة','للمعلومات الضرورية','الأدوية والحساسيات وجهات اتصال الطوارئ',
  [('02',364.3,365.4,1),('02',367.3,370.0,.8)]),
 ('patient','الوضع المبسّط للمريض','جرعة مؤكّدة،','وقراءة محفوظة','مهام واضحة وتأكيد بنجاح كل استجابة',
  [('02',399.8,402.2,1),('02',405,409,1),('02',412.2,415.2,1.2),('02',418.1,420.1,1.3),('02',423.5,429.3,1.2)]),
 ('snooze','تأجيل التذكير','ليس الآن؟','حدّد وقت التذكير','اختر وقتًا آخر مع إبقاء المهمة ظاهرة',
  [('02',434.6,436.8,1.2),('02',437.5,440.5,1),('02',441.8,444.1,1)]),
 ('accessibility','إعدادات المريض','واجهة تتكيّف','مع احتياج المريض','حجم الخط والتاريخ والتنبيهات من حسابك',
  [('02',447,450.4,1.2),('02',451.7,454.5,1.4),('02',455.5,460.2,1.3),('02',462,464.5,1)]),
 ('reminder-return','العودة من التنبيه','التذكير يعيدك','إلى المهمة','من التنبيه إلى الجرعة مباشرة',
  [('03',.15,.95,1),('03',1.15,4.6,1)]),
]

# Verify sequence independently of the eventual render.
last_source,last_end=0,0
for slug,*rest,cuts in chapters:
    for cut in cuts:
        src,a,b,speed,*mode=cut
        assert b>a and speed>0
        if src=='old':
            assert slug=='export'
            continue
        number=int(src)
        assert number>=last_source
        assert number!=last_source or a>=last_end, (slug,a,last_end)
        last_source,last_end=number,b

shutil.copy2(BASE.parent/'tfaqud-demo/edit/assets/source.mp4',ASSETS/'source-old.mp4')
def run(args): subprocess.run(args,check=True,stdout=subprocess.DEVNULL)

# Hold only the original notification card while the phone is locked.
# No wallpaper, clock, widgets, system buttons, or recording indicator survives.
notification_cards = {
    'notification': ('01', 1.0, 'crop=360:70:12:626', 2.6),
    'reminder-return': ('03', .15, 'crop=360:70:12:662', 1.4),
}
notification_messages = {
    'notification': ('يا خالد، لا تنسى الميتفورمين', 'قبل دقيقة'),
    'reminder-return': ('يا لين، لا تنسي أسبرين لخالد', 'الآن'),
}
shutil.copy2(BASE.parent.parent/'app/assets/images/logo.png', ASSETS/'notification-logo.png')
for slug, (src, at, crop, hold) in notification_cards.items():
    run(['ffmpeg','-y','-hide_banner','-loglevel','error','-ss',str(at),
         '-i',str(ASSETS/f'source-{src}.mp4'),'-vf',crop,'-frames:v','1',
         str(ASSETS/f'{slug}-card.png')])

timeline=[]
cursor=0
for index,(slug,category,line1,line2,description,cuts) in enumerate(chapters,1):
    pieces=[]
    rendered_cuts=[]
    local=0
    for j,cut in enumerate(cuts):
        src,a,b,speed,*mode=cut
        output=ASSETS/f'{slug}-{j}.mp4'
        # Remove all of the system status bar, including the red recorder.
        # The earlier PDF is isolated to document pixels; no share-sheet UI.
        crop='crop=384:550:0:113,pad=384:798:0:124:color=0xF8F7FB' if mode==['pdf'] else 'crop=384:798:0:50'
        signature=json.dumps([src,a,b,speed,crop])
        signature_file=output.with_suffix('.signature')
        if not output.exists() or not signature_file.exists() or signature_file.read_text()!=signature:
            run(['ffmpeg','-y','-hide_banner','-loglevel','error','-ss',str(a),'-t',str(b-a),'-i',str(ASSETS/f'source-{src}.mp4'),'-an','-vf',f'{crop},setpts=(PTS-STARTPTS)/{speed},fps=30','-frames:v',str(round((b-a)/speed*30)),'-c:v','libx264','-preset','fast','-crf','17','-g','30','-pix_fmt','yuv420p',str(output)])
            signature_file.write_text(signature)
        duration=float(json.loads(subprocess.check_output(['ffprobe','-v','quiet','-show_format','-of','json',str(output)]))['format']['duration'])
        duration=round(duration*30)/30
        rendered_cuts.append(dict(source=src,source_in=a,source_out=b,speed=speed,start=round(cursor+local,3),duration=duration,isolate_pdf=mode==['pdf']))
        local+=duration
        pieces.append(output)
    listing=ASSETS/f'{slug}.txt'
    listing.write_text(''.join(f"file '{p.name}'\n" for p in pieces),encoding='utf-8')
    run(['ffmpeg','-y','-hide_banner','-loglevel','error','-f','concat','-safe','0','-i',str(listing),'-c','copy','-movflags','+faststart',str(ASSETS/f'{slug}.mp4')])
    timeline.append(dict(id=slug,number=index,category=category,line1=line1,line2=line2,description=description,start=round(cursor,3),duration=round(local,3),cuts=rendered_cuts))
    cursor+=local

outro_duration=3.5
duration=round(cursor+outro_duration,3)
font="""@font-face{font-family:'PlexArabic';src:url('assets/fonts/IBMPlexSansArabic-Regular.ttf');font-weight:400}@font-face{font-family:'PlexArabic';src:url('assets/fonts/IBMPlexSansArabic-SemiBold.ttf');font-weight:600}@font-face{font-family:'PlexArabic';src:url('assets/fonts/IBMPlexSansArabic-Bold.ttf');font-weight:700}"""
css=font+"""
#root{position:absolute;inset:0;color:#202734;font-family:'PlexArabic'}
.header{position:absolute;top:78px;right:112px;left:112px;direction:rtl;text-align:right}
.eyebrow{height:48px;display:flex;align-items:baseline;gap:18px;color:#3F2A65;font-size:27px;font-weight:600}
.number{font-size:36px;line-height:1.2;font-weight:700;min-width:46px}
.category{color:#36415A}
.headline{font-size:62px;line-height:1.25;font-weight:700;margin-top:12px}
.headline-line{display:block;white-space:nowrap}
.emphasis{color:#3F2A65}
.description{font-size:29px;line-height:1.55;color:#36415A;margin-top:11px;white-space:nowrap}
.footage{position:absolute;left:188px;top:380px;width:704px;height:1463px;object-fit:contain;border-radius:16px}
.notification-card{position:absolute;left:144px;top:866px;width:792px;height:220px;background:#FFFFFF;border:2px solid #E1DDE9;border-radius:28px;padding:28px;display:flex;direction:rtl;align-items:center;gap:22px;color:#202734}
.notification-logo{width:74px;height:74px;object-fit:contain;flex-shrink:0}
.notification-copy{flex:1;min-width:0}
.notification-row{display:flex;justify-content:space-between;align-items:baseline;gap:16px}
.notification-title{font-size:36px;font-weight:700;white-space:nowrap}
.notification-time{font-size:28px;color:#535D70;white-space:nowrap}
.notification-message{font-size:32px;line-height:1.6;margin-top:10px;white-space:nowrap}
.progress{position:absolute;left:188px;top:1870px;width:704px;height:4px;background:#E1DDE9;overflow:hidden}
.progress-fill{width:100%;height:100%;background:#AB98D0;transform-origin:right center}
"""
digits=str.maketrans('0123456789','٠١٢٣٤٥٦٧٨٩')
hosts=[]
for item in timeline:
    slug=item['id']; dur=item['duration']; number=str(item['number']).translate(digits)
    hold=notification_cards[slug][3] if slug in notification_cards else 0
    footage=f'<video id="{slug}-video" class="clip footage" src="assets/{slug}.mp4" data-start="{hold}" data-media-start="{hold}" data-duration="{round(dur-hold,3)}" data-track-index="0" muted playsinline></video>'
    if hold:
        message,shown_time=notification_messages[slug]
        footage+=f'<div id="{slug}-card" class="clip notification-card" data-start="0" data-duration="{hold}" data-track-index="0"><img class="notification-logo" src="assets/notification-logo.png" alt="تفقد"><div class="notification-copy"><div class="notification-row"><strong class="notification-title">حان موعد الدواء</strong><span class="notification-time">{shown_time}</span></div><p class="notification-message">{message}</p></div></div>'
    scene=f'''<template><style>{css}</style>
<div id="root" data-composition-id="{slug}" data-width="1080" data-height="1920">
{footage}
<div id="{slug}-caption" class="clip" data-start="0" data-duration="{dur}" data-track-index="1"><div id="{slug}-header" class="header" data-layout-allow-safe-zone>
<div id="{slug}-eyebrow" class="eyebrow"><span class="number">{number}</span><span class="category">{item['category']}</span></div>
<div class="headline"><span id="{slug}-line1" class="headline-line">{item['line1']}</span><span id="{slug}-line2" class="headline-line emphasis">{item['line2']}</span></div>
<p id="{slug}-description" class="description">{item['description']}</p></div></div>
<div class="progress" data-layout-ignore><div id="{slug}-progress" class="progress-fill"></div></div>
</div><script>{{const tl=gsap.timeline({{paused:true}});
tl.fromTo('#{slug}-line1',{{clipPath:'inset(0 0 0 100%)'}},{{clipPath:'inset(0 0 0 0%)',duration:.24,ease:'power3.out'}},0);
tl.fromTo('#{slug}-line2',{{clipPath:'inset(0 0 0 100%)'}},{{clipPath:'inset(0 0 0 0%)',duration:.28,ease:'power3.out'}},.08);
tl.fromTo('#{slug}-description',{{opacity:0}},{{opacity:1,duration:.18}},.12);
tl.fromTo('#{slug}-progress',{{scaleX:0}},{{scaleX:1,duration:{max(.1,dur-.04)},ease:'none'}},0);
window.__timelines['{slug}']=tl;}}</script></template>'''
    (COMP/f'{slug}.html').write_text(scene,encoding='utf-8')
    if hold:
        # Small render projects contain only the changed card span, avoiding
        # re-extraction of the entire 3-minute footage for a 1–3 second edit.
        import re
        part_dir=BASE/'notification-render'/('opening' if slug=='notification' else 'return')
        (part_dir/'compositions').mkdir(parents=True,exist_ok=True)
        (part_dir/'assets/fonts').mkdir(parents=True,exist_ok=True)
        for font_file in (ASSETS/'fonts').iterdir():
            if font_file.is_file(): shutil.copy2(font_file,part_dir/'assets/fonts'/font_file.name)
        shutil.copy2(ASSETS/'notification-logo.png',part_dir/'assets/notification-logo.png')
        still_scene=re.sub(r'<video\b[^>]*></video>','',scene)
        (part_dir/f'compositions/{slug}.html').write_text(still_scene,encoding='utf-8')
        (part_dir/'index.html').write_text(f'''<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8"><script src="https://cdn.jsdelivr.net/npm/gsap@3.15.0/dist/gsap.min.js"></script><style>*{{box-sizing:border-box;margin:0;padding:0}}html,body{{width:1080px;height:1920px;overflow:hidden;background:#F8F7FB}}#root{{position:relative;width:1080px;height:1920px}}</style></head><body><div id="root" data-composition-id="main" data-duration="{hold}" data-width="1080" data-height="1920" data-fps="30"><div id="{slug}" class="clip" data-composition-id="{slug}" data-composition-src="compositions/{slug}.html" data-start="0" data-duration="{hold}" data-width="1080" data-height="1920"></div></div><script>window.__timelines=window.__timelines||{{}};window.__timelines.main=gsap.timeline({{paused:true}});</script></body></html>''',encoding='utf-8')
    hosts.append(f'<div id="{slug}" class="clip" data-composition-id="{slug}" data-composition-src="compositions/{slug}.html" data-start="{item["start"]}" data-duration="{dur}" data-track-index="0" data-track-kind="graphics" data-width="1080" data-height="1920"></div>')

outro=f'''<template><style>{font}#root{{position:absolute;inset:0;background:#EFEAF8;direction:rtl;color:#3F2A65;font-family:'PlexArabic';text-align:center}}#outro-lockup{{position:absolute;top:680px;left:108px;right:108px}}#outro-name{{font-size:116px;font-weight:700;line-height:1.5}}#outro-tagline{{font-size:43px;line-height:1.7}}#outro-small{{font-size:29px;margin-top:32px;color:#36415A}}</style>
<div id="root" data-composition-id="outro" data-width="1080" data-height="1920"><div id="outro-clip" class="clip" data-start="0" data-duration="{outro_duration}" data-track-index="0"><div id="outro-lockup"><div id="outro-name">تفقّد</div><div id="outro-tagline">رعاية تجمع العائلة</div><div id="outro-small">من خطة الرعاية إلى متابعة الاستجابة</div></div></div></div>
<script>{{const tl=gsap.timeline({{paused:true}});tl.fromTo('#outro-name',{{clipPath:'inset(0 0 100% 0)'}},{{clipPath:'inset(0 0 0% 0)',duration:.4,ease:'power3.out'}},0);tl.fromTo('#outro-tagline',{{opacity:0}},{{opacity:1,duration:.25}},.2);tl.fromTo('#outro-small',{{opacity:0}},{{opacity:1,duration:.25}},.4);window.__timelines['outro']=tl;}}</script></template>'''
(COMP/'outro.html').write_text(outro,encoding='utf-8')
hosts.append(f'<div id="outro" class="clip" data-composition-id="outro" data-composition-src="compositions/outro.html" data-start="{round(cursor,3)}" data-duration="{outro_duration}" data-track-index="0" data-track-kind="graphics" data-width="1080" data-height="1920"></div>')

chimes=[.08,next(c['start'] for c in timeline if c['id']=='reminder-return')+.08]
audios=''
for i,t in enumerate(chimes,1): audios+=f'<audio id="notification-chime-{i}" class="clip" src="assets/chime.wav" data-start="{t}" data-duration="1.35" data-track-index="3" data-volume="0.8"></audio>'
page=f'''<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8"><meta name="viewport" content="width=1080,height=1920"><script src="https://cdn.jsdelivr.net/npm/gsap@3.15.0/dist/gsap.min.js"></script><style>*{{box-sizing:border-box;margin:0;padding:0}}html,body{{width:1080px;height:1920px;overflow:hidden;background:#F8F7FB}}#root{{position:relative;width:1080px;height:1920px}}.ground{{position:absolute;inset:0;background:#F8F7FB}}</style></head><body><div id="root" data-composition-id="main" data-start="0" data-duration="{duration}" data-width="1080" data-height="1920" data-fps="30"><div class="ground" data-layout-ignore></div>{''.join(hosts)}{audios}</div><script>window.__timelines=window.__timelines||{{}};window.__timelines['main']=gsap.timeline({{paused:true}});</script></body></html>'''
(ROOT/'index.html').write_text(page,encoding='utf-8')
edl={'duration':duration,'fps':30,'sequence_preserved':True,'authorized_replacement':'Earlier export footage in the export position only','notification_chimes':chimes,'music':False,'notification_cards_only':{slug:{'source':src,'frame_seconds':at,'crop':crop,'hold_seconds':hold} for slug,(src,at,crop,hold) in notification_cards.items()},'chapters':timeline}
(ROOT/'edit-decision-list.json').write_text(json.dumps(edl,ensure_ascii=False,indent=2),encoding='utf-8')
(ROOT/'SPEC.md').write_text(f'''# TFAQUD — new recording edit
GOAL: Preserve the user's sequence, shorten the recording, explain each actual action in Arabic, and use the provided notification chime only with visible TFAQUD notifications.
OUTPUT: HyperFrames, 1080 x 1920, 30 fps, {duration} seconds.
LOOK: #F8F7FB ground, #202734 ink, #3F2A65 emphasis. IBM Plex Sans Arabic, 62px bold two-line headlines, 29px body, 27px functional section label and 36px Arabic number. Header x112 y78; real footage x188 y380, 704 x1463. No generic purple number pills. Editorial-emphasis hierarchy adapted from the searched Registry component, retaining native Arabic shaping and the app font.
MOTION: 0.24/0.28s right-to-left clip reveals on headline lines, stationary after entry. Paragraph opacity 0.18s. Real interactions at 0.8–1.5x; loading and long typing omitted. Each chapter has a finite progress stroke.
SHOTS: edit-decision-list.json is the exact source and output frame plan. All retained ranges are monotonic within the three new files. Export alone is the earlier recording, explicitly requested by the user. No fabricated product UI, no invented completion states.
SOUND: Only the provided tafaqod_chime.wav at {chimes}, gain 0.8. Absolute silence elsewhere; no music or source audio.
NOTIFICATION SHOTS: Original notification text restyled at the user's explicit request with a solid white background and dark text, using the actual app logo. Card at x144 y866, 792x220, 28px radius, 36px title and 32px body. Holds 2.6s / 1.4s. Entire phone-lock-screen layer and the app-opening transition hidden during those intervals. Notification source copies are retained for provenance, not used as display imagery.
BANNED: changing the user's sequence, WhatsApp contacts and sharing sheets, OTP/sign-in, unrelated notifications, notification-center waiting, red system recorder, false claim that all clips concern the same patient, text covering product controls, neon, serif Arabic, purple gradients, floating/rotating phone mockups.
QA: One early and middle frame for every chapter, transition seams, actual exported emergency/export scenes, all audio cues and output duration. Source status bar removed with crop y50 (384 x798 retained). Earlier PDF isolated to document pixels only.
''',encoding='utf-8')
print(json.dumps({'duration':duration,'raw_new_seconds':543.416666,'chapters':len(timeline),'chimes':chimes,'sequence_preserved':True}))
