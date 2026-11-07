import 'package:app/core/services/simplified_voice.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

/// The «استماع» button every simplified screen carries: reads [segments]
/// aloud in order (title, then body text, then the button names), for a
/// patient who cannot read the screen easily.
class ListenButton extends StatelessWidget {
  const ListenButton({super.key, required this.segments});

  final List<String> segments;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: context.tr('simplified_mode.listen'),
      icon: const Icon(CupertinoIcons.speaker_3_fill),
      onPressed: () => GetIt.I<SimplifiedVoice>().speak(segments),
    );
  }
}
