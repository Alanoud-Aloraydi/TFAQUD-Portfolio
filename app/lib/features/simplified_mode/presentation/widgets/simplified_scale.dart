import 'package:app/core/services/simplified_text_scale.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

/// Applies the person's saved simplified-mode text size to [child]. Wraps
/// every simplified screen so the choice made in «حسابي» takes effect
/// immediately on the next screen, without an app restart.
class SimplifiedScale extends StatefulWidget {
  const SimplifiedScale({super.key, required this.child});

  final Widget child;

  @override
  State<SimplifiedScale> createState() => _SimplifiedScaleState();
}

class _SimplifiedScaleState extends State<SimplifiedScale> {
  double? _factor;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final scale = await GetIt.I<SimplifiedTextScalePreference>().get();
    if (mounted) setState(() => _factor = scale.factor);
  }

  @override
  Widget build(BuildContext context) {
    final double? factor = _factor;
    if (factor == null) return widget.child;
    final MediaQueryData data = MediaQuery.of(context);
    return MediaQuery(
      data: data.copyWith(
        textScaler: TextScaler.linear(data.textScaler.scale(1) * factor),
      ),
      child: widget.child,
    );
  }
}
