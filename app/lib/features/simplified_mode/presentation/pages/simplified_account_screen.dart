import 'dart:async';

import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/media/private_photo.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/services/calendar_sync.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/care_visuals.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/core/widgets/forms/calendar_sync_choices.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/account/presentation/widgets/delete_dialogs.dart';
import 'package:app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:app/features/auth/presentation/cubit/auth_state.dart';
import 'package:app/features/simplified_mode/data/simplified_voice.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_speech_rate.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_text_size.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_settings_cubit.dart';
import 'package:app/features/simplified_mode/presentation/simplified_speech.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_controls.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/task_visuals.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// «حسابي»: the patient's name and number, the text size and reading,
/// the calendar copy of appointments, the medical file, signing out and
/// deleting the account. Needs an [AccountCubit] and an [AuthCubit].
class SimplifiedAccountScreen extends StatelessWidget {
  const SimplifiedAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? circleId = context.select<SimplifiedModeCubit, String?>(
      (cubit) => cubit.state.day?.circleId,
    );
    final bool voiceEnabled = context.select<SimplifiedSettingsCubit, bool>(
      (cubit) => cubit.state.voiceEnabled,
    );
    final SimplifiedTextSize textSize = context
        .select<SimplifiedSettingsCubit, SimplifiedTextSize>(
          (cubit) => cubit.state.textSize,
        );
    final SimplifiedSpeechRate speechRate = context
        .select<SimplifiedSettingsCubit, SimplifiedSpeechRate>(
          (cubit) => cubit.state.speechRate,
        );
    final bool autoRead = context.select<SimplifiedSettingsCubit, bool>(
      (cubit) => cubit.state.autoRead,
    );
    return BlocListener<AccountCubit, AccountState>(
      listenWhen: (before, after) =>
          (after.sessionEnded && !before.sessionEnded) ||
          (after.signedOut && !before.signedOut) ||
          (after.errorKey != null && after.errorKey != before.errorKey) ||
          (after.deletePrompt != before.deletePrompt &&
              after.deletePrompt != DeletePrompt.none),
      listener: (context, state) {
        final AccountCubit cubit = context.read<AccountCubit>();
        if (state.sessionEnded || state.signedOut) {
          context.go(Routes.auth);
          return;
        }
        if (state.errorKey case final String key) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(context.tr(key))));
          cubit.messagesShown();
        }
        if (state.deletePrompt != DeletePrompt.none) {
          answerDeletePrompt(
            context,
            cubit,
            state.deletePrompt,
            confirm: _confirmDelete,
          );
        }
      },
      child: BlocBuilder<AccountCubit, AccountState>(
        builder: (context, state) {
          final account = state.account;
          return SimplifiedPage(
            title: context.tr('simplified_mode.account_title'),
            listen: <SpokenPart>[
              if (account != null)
                (
                  id: _Part.profile,
                  text: sentences(<String>[
                    account.displayName,
                    context.tr('simplified_mode.photo_hint'),
                  ]),
                ),
              (
                id: _Part.textSize,
                text: sentences(<String>[
                  context.tr('simplified_mode.display_sound'),
                  context.tr('simplified_mode.text_size'),
                  context.tr(
                    'simplified_mode.selected_option',
                    args: <String>[
                      context.tr('simplified_mode.size.${textSize.name}'),
                    ],
                  ),
                ]),
              ),
              (
                id: _Part.voice,
                text: sentences(<String>[
                  context.tr('simplified_mode.voice_title'),
                  context.tr('simplified_mode.voice_text'),
                ]),
              ),
              if (voiceEnabled) ...<SpokenPart>[
                (
                  id: _Part.speechRate,
                  text: sentences(<String>[
                    context.tr('simplified_mode.speech_rate'),
                    context.tr(
                      'simplified_mode.selected_option',
                      args: <String>[
                        context.tr('simplified_mode.rate.${speechRate.name}'),
                      ],
                    ),
                  ]),
                ),
                (
                  id: _Part.autoRead,
                  text: sentences(<String>[
                    context.tr('simplified_mode.auto_read_title'),
                    context.tr('simplified_mode.auto_read_text'),
                    context.tr(
                      autoRead
                          ? 'simplified_mode.setting_on'
                          : 'simplified_mode.setting_off',
                    ),
                  ]),
                ),
              ],
              if (circleId != null) ...<SpokenPart>[
                (
                  id: _Part.calendar,
                  text: sentences(<String>[
                    context.tr('simplified_mode.calendar_title'),
                    context.tr('simplified_mode.calendar_text'),
                  ]),
                ),
                (
                  id: _Part.medicalFile,
                  text: sentences(<String>[
                    context.tr('simplified_mode.my_info'),
                    context.tr('simplified_mode.my_medical_file'),
                    context.tr('simplified_mode.my_medical_file_sub'),
                  ]),
                ),
              ],
              (id: _Part.signOut, text: context.tr('simplified_mode.sign_out')),
              (
                id: _Part.delete,
                text: context.tr('simplified_mode.delete_account'),
              ),
            ],
            children: <Widget>[
              if (account != null)
                ListenTarget(
                  id: _Part.profile,
                  speaker: ListenSpeaker.beside,
                  child: Row(
                    children: <Widget>[
                      Semantics(
                        button: true,
                        label: context.tr('simplified_mode.change_photo'),
                        excludeSemantics: true,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => unawaited(
                            showPersonPhotoSheet(
                              context,
                              title: context.tr('photos.your_photo'),
                              name: account.displayName,
                              photoPath: ApiEndpoints.accountPhoto,
                              avatarPath: ApiEndpoints.accountAvatar,
                              avatarCode: account.avatarCode,
                              frontCamera: true,
                              onSaved: () => unawaited(
                                context.read<AccountCubit>().load(),
                              ),
                            ),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: <Widget>[
                              PersonPhoto(
                                name: account.displayName,
                                photoPath: ApiEndpoints.accountPhoto,
                                avatarCode: account.avatarCode,
                                size: 72,
                              ),
                              const PhotoEditBadge(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: SimplifiedStyle.gap),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              account.displayName,
                              style: SimplifiedStyle.head(
                                SimplifiedStyle.headline,
                              ),
                            ),
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                SaudiMobile.display(account.phoneNumber),
                                style: SimplifiedStyle.text(
                                  SimplifiedStyle.caption,
                                ),
                              ),
                            ),
                            Text(
                              context.tr('simplified_mode.photo_hint'),
                              style: SimplifiedStyle.text(
                                SimplifiedStyle.caption,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else if (state.status == AccountStatus.loading)
                const Center(child: CircularProgressIndicator()),
              _SectionTitle(context.tr('simplified_mode.display_sound')),
              const ListenTarget(id: _Part.textSize, child: _TextSizeCard()),
              const ListenTarget(id: _Part.voice, child: _VoiceSwitch()),
              if (voiceEnabled) ...const <Widget>[
                ListenTarget(id: _Part.speechRate, child: _SpeechRateCard()),
                ListenTarget(id: _Part.autoRead, child: _AutoReadSwitch()),
              ],
              if (circleId != null) ...<Widget>[
                _SectionTitle(context.tr('simplified_mode.calendar_title')),
                ListenTarget(
                  id: _Part.calendar,
                  child: _CalendarSyncCard(circleId: circleId),
                ),
                _SectionTitle(context.tr('simplified_mode.my_info')),
                ListenTarget(
                  id: _Part.medicalFile,
                  child: SimplifiedCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SimplifiedStyle.pad,
                      vertical: SimplifiedStyle.gap,
                    ),
                    onTap: () =>
                        context.push(Routes.simplifiedMedicalFile(circleId)),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                context.tr('simplified_mode.my_medical_file'),
                                style: SimplifiedStyle.head(
                                  SimplifiedStyle.body,
                                ),
                              ),
                              Text(
                                context.tr(
                                  'simplified_mode.my_medical_file_sub',
                                ),
                                style: SimplifiedStyle.text(
                                  SimplifiedStyle.caption,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          AppIcons.next,
                          size: 28,
                          color: SimplifiedStyle.ink,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              const ListenTarget(
                id: _Part.signOut,
                radius: SimplifiedStyle.action / 2,
                child: _SignOutButton(),
              ),
              ListenTarget(
                id: _Part.delete,
                radius: SimplifiedStyle.action / 2,
                child: _OutlinedDanger(
                  label: context.tr('simplified_mode.delete_account'),
                  busy: state.deleting,
                  filled: false,
                  onPressed: context.read<AccountCubit>().startDelete,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// The first question of deleting, asked as a big sheet.
  static Future<bool?> _confirmDelete(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      backgroundColor: SimplifiedStyle.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                sheetContext.tr('simplified_mode.delete_title'),
                style: SimplifiedStyle.head(26),
              ),
              const SizedBox(height: 8),
              Text(
                sheetContext.tr('simplified_mode.delete_text'),
                style: SimplifiedStyle.text(
                  SimplifiedStyle.body,
                  weight: AppTextTheme.medium,
                ),
              ),
              const SizedBox(height: 20),
              SimplifiedButton(
                label: sheetContext.tr('simplified_mode.delete_yes'),
                tone: SimplifiedButtonTone.danger,
                onPressed: () => Navigator.of(sheetContext).pop(true),
              ),
              const SizedBox(height: 12),
              SimplifiedButton(
                label: sheetContext.tr('simplified_mode.delete_no'),
                tone: SimplifiedButtonTone.quiet,
                onPressed: () => Navigator.of(sheetContext).pop(false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The parts of the account «استماع» reads and marks, in their order.
enum _Part {
  profile,
  textSize,
  voice,
  speechRate,
  autoRead,
  calendar,
  medicalFile,
  signOut,
  delete,
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: SimplifiedStyle.head(SimplifiedStyle.body));
}

/// Three big tiles, each showing «أ» at the size it gives.
class _TextSizeCard extends StatelessWidget {
  const _TextSizeCard();

  static const Map<SimplifiedTextSize, double> _sample =
      <SimplifiedTextSize, double>{
        SimplifiedTextSize.normal: 24,
        SimplifiedTextSize.large: 34,
        SimplifiedTextSize.larger: 44,
      };

  @override
  Widget build(BuildContext context) {
    final SimplifiedTextSize selected = context
        .select<SimplifiedSettingsCubit, SimplifiedTextSize>(
          (cubit) => cubit.state.textSize,
        );
    return SimplifiedCard(
      padding: const EdgeInsets.symmetric(
        horizontal: SimplifiedStyle.pad,
        vertical: SimplifiedStyle.gap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.tr('simplified_mode.text_size'),
            style: SimplifiedStyle.head(SimplifiedStyle.body),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              for (final SimplifiedTextSize size
                  in SimplifiedTextSize.values) ...<Widget>[
                if (size != SimplifiedTextSize.normal)
                  const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: size == selected,
                    child: GestureDetector(
                      onTap: () => context
                          .read<SimplifiedSettingsCubit>()
                          .setTextSize(size),
                      child: Container(
                        height: 104,
                        decoration: BoxDecoration(
                          color: size == selected
                              ? SimplifiedStyle.accentTint
                              : SimplifiedStyle.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: size == selected
                                ? SimplifiedStyle.ink
                                : SimplifiedStyle.disabled,
                            width: size == selected ? 3 : 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            // A fixed size, so each tile shows its own
                            // size and not the one chosen now.
                            MediaQuery.withNoTextScaling(
                              child: Text(
                                context.tr('simplified_mode.size_sample'),
                                style: SimplifiedStyle.head(
                                  _sample[size]!,
                                  height: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.tr('simplified_mode.size.${size.name}'),
                              style: SimplifiedStyle.head(
                                SimplifiedStyle.caption,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  const _SwitchCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SimplifiedCard(
      padding: const EdgeInsets.symmetric(
        horizontal: SimplifiedStyle.pad,
        vertical: SimplifiedStyle.gap,
      ),
      child: MergeSemantics(
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: SimplifiedStyle.head(SimplifiedStyle.body),
                  ),
                  Text(
                    subtitle,
                    style: SimplifiedStyle.text(SimplifiedStyle.caption),
                  ),
                ],
              ),
            ),
            const SizedBox(width: SimplifiedStyle.gap),
            Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: SimplifiedStyle.success,
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceSwitch extends StatelessWidget {
  const _VoiceSwitch();

  @override
  Widget build(BuildContext context) {
    final bool enabled = context.select<SimplifiedSettingsCubit, bool>(
      (cubit) => cubit.state.voiceEnabled,
    );
    return _SwitchCard(
      title: context.tr('simplified_mode.voice_title'),
      subtitle: context.tr('simplified_mode.voice_text'),
      value: enabled,
      onChanged: context.read<SimplifiedSettingsCubit>().setVoiceEnabled,
    );
  }
}

/// How fast the mode reads: three choices in one capsule. A choice reads a
/// short sentence at its pace, so the person hears what they picked.
class _SpeechRateCard extends StatelessWidget {
  const _SpeechRateCard();

  @override
  Widget build(BuildContext context) {
    final SimplifiedSpeechRate selected = context
        .select<SimplifiedSettingsCubit, SimplifiedSpeechRate>(
          (cubit) => cubit.state.speechRate,
        );
    return SimplifiedCard(
      padding: const EdgeInsets.symmetric(
        horizontal: SimplifiedStyle.pad,
        vertical: SimplifiedStyle.gap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.tr('simplified_mode.speech_rate'),
            style: SimplifiedStyle.head(SimplifiedStyle.body),
          ),
          const SizedBox(height: 12),
          SimplifiedSegmented<SimplifiedSpeechRate>(
            segments: <SimplifiedSpeechRate, String>{
              for (final SimplifiedSpeechRate rate
                  in SimplifiedSpeechRate.values)
                rate: context.tr('simplified_mode.rate.${rate.name}'),
            },
            selected: selected,
            onChanged: (rate) {
              unawaited(
                context.read<SimplifiedSettingsCubit>().setSpeechRate(rate),
              );
              unawaited(
                readAloud(context, <SpokenPart>[
                  (
                    id: _Part.speechRate,
                    text: context.tr('simplified_mode.speech_rate_sample'),
                  ),
                ]),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AutoReadSwitch extends StatelessWidget {
  const _AutoReadSwitch();

  @override
  Widget build(BuildContext context) {
    final bool enabled = context.select<SimplifiedSettingsCubit, bool>(
      (cubit) => cubit.state.autoRead,
    );
    return _SwitchCard(
      title: context.tr('simplified_mode.auto_read_title'),
      subtitle: context.tr('simplified_mode.auto_read_text'),
      value: enabled,
      onChanged: context.read<SimplifiedSettingsCubit>().setAutoRead,
    );
  }
}

/// The circle's medicines, scheduled measurements and appointments on the
/// phone's own calendar — the detailed mode's calendar group in this
/// mode's sizes: one group, each row the kind's icon square, its name and a
/// switch, and the explanation under it. The same choices, kept by the
/// same [CalendarSync]; all off until chosen.
class _CalendarSyncCard extends StatefulWidget {
  const _CalendarSyncCard({required this.circleId});

  final String circleId;

  @override
  State<_CalendarSyncCard> createState() => _CalendarSyncCardState();
}

class _CalendarSyncCardState extends State<_CalendarSyncCard>
    with CalendarSyncChoices<_CalendarSyncCard> {
  @override
  String get calendarCircleId => widget.circleId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SimplifiedCard(
          padding: const EdgeInsets.symmetric(horizontal: SimplifiedStyle.pad),
          child: Column(
            children: <Widget>[
              for (final CalendarSyncCategory category
                  in CalendarSyncCategory.values) ...<Widget>[
                if (category != CalendarSyncCategory.values.first)
                  const Divider(height: 1, color: SimplifiedStyle.chip),
                _CalendarRow(
                  look: (category.icon, category.tile),
                  label: context.tr(
                    'simplified_mode.calendar.${category.name}',
                  ),
                  value: enabled?[category] ?? false,
                  onChanged: enabled == null
                      ? null
                      : (value) => unawaited(setChoice(category, value)),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(
            top: 8,
            start: SimplifiedStyle.pad,
            end: SimplifiedStyle.pad,
          ),
          child: Text(
            context.tr('simplified_mode.calendar_text'),
            style: SimplifiedStyle.text(SimplifiedStyle.caption),
          ),
        ),
      ],
    );
  }
}

/// One calendar row: the kind's icon square, its name, a switch.
class _CalendarRow extends StatelessWidget {
  const _CalendarRow({
    required this.look,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final (IconData, Color) look;
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Row(
          children: <Widget>[
            CareIconTile(icon: look.$1, background: look.$2),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: SimplifiedStyle.label(SimplifiedStyle.body),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: SimplifiedStyle.success,
            ),
          ],
        ),
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthErrorState) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(context.tr(state.messageKey))));
        }
        if (state is AuthSignedOutState) {
          if (!state.serverConfirmed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr('auth.sign_out_local_only'))),
            );
          }
          context.go(Routes.auth);
        }
      },
      builder: (context, state) => _OutlinedDanger(
        label: context.tr('simplified_mode.sign_out'),
        busy: state is AuthLoadingState,
        filled: true,
        onPressed: context.read<AuthCubit>().signOut,
      ),
    );
  }
}

/// A red-worded capsule for leaving or deleting the account.
class _OutlinedDanger extends StatelessWidget {
  const _OutlinedDanger({
    required this.label,
    required this.busy,
    required this.filled,
    required this.onPressed,
  });

  final String label;
  final bool busy;

  /// White behind it with a light edge; else only a red edge.
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: busy ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(64),
        shape: const StadiumBorder(),
        backgroundColor: filled
            ? SimplifiedStyle.surface
            : SimplifiedStyle.clear,
        side: BorderSide(
          color: filled ? SimplifiedStyle.line : SimplifiedStyle.danger,
          width: filled ? 1 : 1.5,
        ),
        foregroundColor: SimplifiedStyle.danger,
      ),
      child: busy
          ? const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : Text(
              label,
              style: SimplifiedStyle.head(
                SimplifiedStyle.body,
                color: SimplifiedStyle.danger,
              ),
            ),
    );
  }
}
