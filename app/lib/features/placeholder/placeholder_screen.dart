import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Empty screen used until the real screens exist. Tab pages show only the
/// title (the shell supplies the bars); standalone pages get an app bar.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.titleKey,
    this.standalone = false,
  });

  final String titleKey;
  final bool standalone;

  @override
  Widget build(BuildContext context) {
    final String title = context.tr(titleKey);
    final Widget body = Center(
      child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
    );
    if (!standalone) return body;
    return Scaffold(appBar: AppBar(title: Text(title)));
  }
}
