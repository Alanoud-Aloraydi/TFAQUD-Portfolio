# Review — Arabic feature demo

## Revision 2 — feature sequence and privacy cleanup

The current composition is 120.1 seconds. Features are reordered and renumbered: care circles, medical profile, medications, measurements, appointments, daily care, visit notes, report export, Emergency Card, then notifications/calendar. The phone status bar is cropped by 96 output pixels on every footage element, removing the red recording indicator, clock and TestFlight status text while retaining app navigation.

The WhatsApp document-preview segment was removed. Export now uses only source 132.5–140.5, before the external sharing sheet. A second contact-suggestion sheet in the Emergency Card footage was found during review and removed: this scene now uses only 265.0–265.8, slowed to a six-second reading hold. Its full six-second video was audited at two frames per second, and early/middle/end composition snapshots confirmed no sharing controls or contacts. Sign-in/OTP footage is not part of the composition. The user's original input file remains the source; the delivered edit excludes these scenes.

Revision 2 HyperFrames check passed with zero runtime, layout or contrast errors. Ten chapter frames and the export/emergency ranges were visually checked after the changes. Earlier notes below describe revision 1, superseded by this revision.

Revision 2 delivery: `../TFAQUD-demo-ar-v2.mp4`, 120.100 seconds, 1080 x 1920, 30 fps, H.264/AAC, 46,077,942 bytes. The rendered export section was decoded at four frames per second for all eight seconds, and the Emergency Card section at four frames per second for all six seconds; neither sheet contains WhatsApp contacts or sharing controls. The earlier canonical MP4 is replaced with this verified clean version so the original file link also opens the corrected edit.

## Creative decisions

Edited the supplied 5:10 recording into a 2:05 portrait demo with ten sequential Arabic feature numbers. Real interface footage remains the subject. Labels sit above the phone, using the app's IBM Plex Sans Arabic font, violet palette, and neutral canvas. Short opening and closing lockups use the app name as text. A quiet instrumental from the connected HeyGen catalog replaces the effectively silent original audio. No narration was added.

This task is an edit and overlay on supplied footage; alternate storylines were not needed. The editable timeline and exact source cuts are in `edit-decision-list.json`. `build_edit.py` is a reproducible authoring script; omit `--reuse` for a complete source rebuild.

## Measured and inspected

HyperFrames checks cover runtime, layout, contrast, and audio presence. Scene beat sheets, cut strips, and phone-size sheets were visually inspected. Follow-up snapshots checked the revised opening, medical profile, PDF excerpt, and circle-switch payoff. The permission prompt was removed from the opening; the exported document is cropped to remove WhatsApp's sharing controls. No product UI was recreated.

The final MP4 is additionally checked with ffprobe, decoded representative frames, and audio loudness measurement. Audio is measured, not listened to.

Delivery verification: `../TFAQUD-demo-ar.mp4` is 125.000 seconds, 1080 x 1920, H.264 at 30 fps with AAC audio, 50,460,883 bytes. Decoded frames across the exported file match the Arabic headings and real footage. Audio mean is -26.5 dBFS and peak -7.6 dBFS; there is no measured clipping. Final HyperFrames check: passed, with zero runtime, layout, or contrast errors. Application source files were not changed.

## Intentional warnings and limits

- The title band intentionally sits above the app screen, inside the canvas but outside the generic social-platform top safe area. This version is a presentation/product demo; added platform chrome may overlap it if posted as a Reel.
- Two editable-id warnings refer to grouping wrappers. They do not affect rendering or the ten numbered headings.
- The supplied video is only 384 x 848. Output is 1080 x 1920, but the app footage retains the source's compression softness.
- The weakest evidence is successful task entry: the recording shows care forms and existing history, but does not show a new reading or patient dose response being saved. The edit does not invent those results.
- Simplified Mode is not shown. `../EXTRA-CAPTURES.md` gives the exact additional recordings needed.

## Additional source provenance

Background music: HeyGen audio catalog item `7c7c9903947c472e9568a88fe44bc24a`, described as warm professional healthcare ambient with soft piano and light strings. The selected catalog file is kept locally, with three-second overlapping repeats and an approximately -24 LUFS soundtrack target.
