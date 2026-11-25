# New recording edit — review

## User requirements

- Preserve the sequence of the three supplied recordings. Cut pauses, typing, loaders, duplicates and unrelated content without rearranging the remaining actions.
- Use the earlier recording for the export section only, as explicitly requested after review started. The replacement stays in the same place in the user's sequence.
- Use `tafaqod_chime.wav` on visible TFAQUD notifications.
- Replace generic headings with specific Arabic descriptions above the footage, and retain Arabic feature numbers.
- Remove WhatsApp contacts/sharing screens, sign-in codes, unrelated notifications and the red screen-recording indicator.

## Creative decisions

Twenty sections follow the user's recording order. A script assertion checks monotonic source ranges across source 01, 02 and 03; only the authorized earlier export footage is exempted. The three new source files total approximately 543.4 seconds. The edit is 190.833 seconds, including a 3.5-second closing lockup. About 65% of the original running time is removed.

The Arabic hierarchy uses 62px bold two-line headlines with violet emphasis on the second line, 29px descriptive copy, a 27px secondary category, and 36px Arabic feature numbers. IBM Plex Sans Arabic and TFAQUD's palette are retained. Headline reveals stop after 0.36 seconds; text stays still while being read. Real footage is cropped by 50 source pixels at the top to remove the status bar, then displayed at 704 x1463 on a 1080 x1920 canvas.

No invented interface, completion state, voiceover, or notification was added. The supplied 1.35-second chime plays at 0.08 seconds and 183.18 seconds, on the two real notification shots. Music is normalized to an approximately -27 LUFS target and ducked to 0.3 gain around each chime. The original recordings measure approximately -91 dB mean, so there is no useful recorded sound to preserve.

## Review performed

Initial HyperFrames check: zero lint, runtime, layout, contrast or audio errors. The beat, phone-width and seam sheets were generated. Full-size beat sheets were inspected across all twenty sections. All 58 retained cut endings were extracted and inspected, including the previous export footage, Emergency Card, patient confirmations, and return from notification. Two remaining loading pauses were removed after this pass; targeted snapshots and the final check cover these changes.

## Intentional warnings and limitations

- The 27px secondary category labels generate `text_below_floor` craft warnings. Main headlines are 62px and descriptions are 29px; the small category is supplementary to both.
- Footage is WhatsApp-compressed 384 x848. Output resolution does not restore the source's missing text detail.
- The earlier PDF concerns an earlier demo example. Its caption explicitly calls it an example, and no claim is made that it was generated from the new self-care entry.
- The weakest visual evidence is the mostly empty visit-note form; the captured voice-note controls and saved waveform establish the feature, but the recording does not contain written visit notes. The copy describes the available fields without inventing content.
- Audio is verified by waveform/levels and timing, not listened to.

## Files

`edit-decision-list.json` contains every original in/out time, playback speed, output time and notification cue. `../build_edit.py` recreates the composition and cached edited clips. Original input copies remain in `assets/source-*.mp4`; only the selected ranges are part of the delivered video.


## Final delivery verification — 2026-11-24

Delivered `../TFAQUD-demo-new-ar.mp4`: 190.833333 seconds, 1080 x1920, H.264 at 30 fps (5,725 frames), stereo AAC 48 kHz, 56,338,204 bytes. SHA-256: `7a3d9e3b3737040367a80a6573064dc4b8f5193c0a0ef0fed20ef80872609afc`. MP4 metadata precedes media data for progressive playback.

Thirteen frames decoded from the actual delivered MP4 were inspected, including the prior PDF, Emergency Card, patient confirmation, snooze controls, patient settings, reminder return and closing lockup. The opening notification and PDF were also inspected at full size. These confirm the intended crop and Arabic titles; the full pre-render review additionally covers all 58 retained cut endings.

The supplied chime is detected at 0.0800 and 183.1838 seconds; normalized waveform correlation against the source is 0.9982 and 0.9840 respectively. Mono audio peak is -4.61 dBFS. No audition was performed. Verification details and decoded frame samples are in `../review/delivery/`.

## Temporary-file closeout

The initial render was blocked by disk space. Thirty-one extracted-frame cache entries from this task's prior renders were inventoried, visually matched to preserved old edited clips, and removed after confirming that no render was active. Reclaimed payload: 406,498,576 bytes. Exact paths and revalidation receipts are in `../review/cleanup-plan.json` and `../review/cleanup-result.json`. No recordings, completed exports, edited clips, project sources or other projects were removed. A PowerShell inspection-parameter error occurred during cleanup; all literal targets were independently revalidated afterward as within the exact intended cache directory and absent.

Two-worker capture would require about 2.5 GB of temporary frame images, so the successful export used one streaming worker with the extracted-frame cache disabled. The render completed normally with exit code 0. Its temporary work files are managed by HyperFrames. The older Nov22 render directory was deferred because ownership was not established; both preview servers remain available. Original and edited source assets are retained. Measured C: free space after delivery was approximately 1.95 GB; this delta includes unrelated concurrent system activity and is not claimed as entirely reclaimed by this task.
