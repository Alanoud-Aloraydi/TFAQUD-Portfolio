import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Welcome page. The phone number and code pages are added next (TFQD-22).
class AuthFeatureScreen extends StatelessWidget {
  const AuthFeatureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          context.tr('auth.welcome'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
