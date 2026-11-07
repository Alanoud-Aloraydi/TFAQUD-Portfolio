import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/private_photo.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/services/simplified_text_scale.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/features/account/presentation/widgets/settings_card.dart';
import 'package:app/features/account/presentation/widgets/sign_out_row.dart';
import 'package:app/features/circles/presentation/widgets/calendar_sync_section.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_account_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_account_state.dart';
import 'package:app/features/simplified_mode/presentation/widgets/listen_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_scale.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// "حسابي" for simplified mode: the patient's photo and name, the circle's
/// reminder sync, the medical card, and signing out. No circle tab exists
/// in this mode, so the medical card opens from here instead.
class SimplifiedAccountScreen extends StatelessWidget {
  const SimplifiedAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SimplifiedScale(
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StepHeader(
                  title: context.tr('account.title'),
                  onBack: () => context.pop(),
                  trailing: ListenButton(
                    segments: [
                      context.tr('account.title'),
                      context.tr('simplified_mode.medical_card_title'),
                      context.tr('simplified_mode.medical_card'),
                      context.tr('auth.sign_out'),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child:
                      BlocBuilder<
                        SimplifiedAccountCubit,
                        SimplifiedAccountState
                      >(
                        builder: (context, state) {
                          switch (state.status) {
                            case SimplifiedAccountStatus.loading:
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            case SimplifiedAccountStatus.failure:
                              return Center(
                                child: TextButton(
                                  onPressed: () => context
                                      .read<SimplifiedAccountCubit>()
                                      .load(),
                                  child: Text(context.tr('error.unknown')),
                                ),
                              );
                            case SimplifiedAccountStatus.ready:
                              return _SimplifiedAccountBody(state: state);
                          }
                        },
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SimplifiedAccountBody extends StatefulWidget {
  const _SimplifiedAccountBody({required this.state});

  final SimplifiedAccountState state;

  @override
  State<_SimplifiedAccountBody> createState() => _SimplifiedAccountBodyState();
}

class _SimplifiedAccountBodyState extends State<_SimplifiedAccountBody> {
  SimplifiedTextScale? _textScale;

  @override
  void initState() {
    super.initState();
    GetIt.I<SimplifiedTextScalePreference>().get().then((value) {
      if (mounted) setState(() => _textScale = value);
    });
  }

  Future<void> _setTextScale(SimplifiedTextScale value) async {
    setState(() => _textScale = value);
    await GetIt.I<SimplifiedTextScalePreference>().set(value);
  }

  SimplifiedAccountState get state => widget.state;

  @override
  Widget build(BuildContext context) {
    final String shown = state.displayName ?? '';
    final String? circleId = state.circleId;
    return ListView(
      children: [
        Column(
          children: [
            Semantics(
              button: true,
              label: context.tr('photos.edit_your_photo'),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => showPersonPhotoSheet(
                  context,
                  title: context.tr('photos.your_photo'),
                  name: shown,
                  photoPath: ApiEndpoints.accountPhoto,
                  avatarPath: ApiEndpoints.accountAvatar,
                  avatarCode: state.avatarCode,
                  frontCamera: true,
                  onSaved: () => context.read<SimplifiedAccountCubit>().load(),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    PersonPhoto(
                      name: shown,
                      photoPath: ApiEndpoints.accountPhoto,
                      avatarCode: state.avatarCode,
                      size: AppSizes.avatarLarge,
                    ),
                    const PhotoEditBadge(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(shown, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        SettingsSection(
          title: context.tr('simplified_mode.display_sound_title'),
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(context.tr('simplified_mode.text_size')),
                  const SizedBox(height: AppSpacing.sm),
                  GlassSegmentedControl<SimplifiedTextScale>(
                    segments: {
                      SimplifiedTextScale.small: context.tr(
                        'simplified_mode.text_size_small',
                      ),
                      SimplifiedTextScale.normal: context.tr(
                        'simplified_mode.text_size_normal',
                      ),
                      SimplifiedTextScale.large: context.tr(
                        'simplified_mode.text_size_large',
                      ),
                    },
                    selected: _textScale ?? SimplifiedTextScale.normal,
                    onChanged: _setTextScale,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        if (circleId != null) ...[
          SectionTitle(context.tr('circle_overview.calendar_sync_title')),
          CalendarSyncToggles(circleId: circleId),
          const CalendarSyncHint(),
          const SizedBox(height: AppSpacing.xl),
          SettingsSection(
            title: context.tr('simplified_mode.medical_card_title'),
            children: [
              ActionRow(
                label: context.tr('simplified_mode.medical_card'),
                onPressed: () => context.push(Routes.medicalFile(circleId)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        const SettingsCard(children: [SignOutRow()]),
      ],
    );
  }
}
