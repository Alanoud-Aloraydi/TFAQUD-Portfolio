import 'package:app/features/auth/presentation/widgets/sign_out_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Temporary account page with only the sign-out button (prototype).
/// F05 (account settings) replaces this page.
class AccountPrototypeScreen extends StatelessWidget {
  const AccountPrototypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('topbar.account'))),
      body: const Center(child: SignOutButton()),
    );
  }
}
