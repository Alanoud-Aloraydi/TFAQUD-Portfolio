import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SimplifiedLoadFailed extends StatelessWidget {
  const SimplifiedLoadFailed({super.key, required this.messageKey});

  final String? messageKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(SimplifiedStyle.page),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            context.tr(messageKey ?? 'error.unknown'),
            textAlign: TextAlign.center,
            style: SimplifiedStyle.text(
              SimplifiedStyle.body,
              color: SimplifiedStyle.ink,
            ),
          ),
          const SizedBox(height: SimplifiedStyle.gap),
          SimplifiedButton(
            label: context.tr('simplified_mode.try_again'),
            onPressed: context.read<SimplifiedModeCubit>().load,
          ),
        ],
      ),
    );
  }
}
