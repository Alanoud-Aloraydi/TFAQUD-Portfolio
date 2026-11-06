# خريطة كود تفقد

هذه خريطة للكود الموجود محليًا بتاريخ 2026-11-04 على فرع `feature/medications`. مصدرها الملفات نفسها؛ ليست مواصفة تصميم أو وعدًا بأن كل المسارات اختُبرت.

## كيف تصل من الشاشة إلى الكود

| ما يظهر في التطبيق | تركيب الواجهة | الحالة والبيانات | الخادم |
|---|---|---|---|
| الشريط العلوي والسفلي وزر + | `app/lib/features/shell/app_shell.dart`، `widgets/app_top_bar.dart`، `widgets/app_bottom_bar.dart`، `widgets/glass_add_button.dart` | `app/lib/features/home/presentation/pages/home_feature_screen.dart`، `app/lib/core/navigation/app_router.dart` | — |
| قائمة زر + | `app/lib/features/home/presentation/widgets/home_add_sheet.dart` | تفتح نماذج الدواء والقياس والموعد أو تسجيل قراءة | مجالات الأدوية والقياسات والمواعيد |
| اليوم: المهمة القادمة والتنبيهات وجدول الصلاة | `app/lib/features/home/presentation/pages/today_page.dart` | `HomeFeatureScreen` يحمّل بيانات المجالات، و`TodayPage` يجمعها | `backend/app/home.py` ومجالات المهام |
| دواء اليوم | `app/lib/features/medications/presentation/widgets/today_medication_components.dart`، `today_dose_window.dart`، `dose_record_controls.dart` | `medication_occurrences_cubit.dart`، `today_medication_view.dart` | `backend/app/medications/` |
| قياس اليوم | `app/lib/features/measurements/presentation/widgets/measurement_today_section.dart`، `measurement_reading_sheet.dart` | `measurement_tasks_cubit.dart`، `measurement_readings_cubit.dart` | `backend/app/measurements/` |
| موعد اليوم | `app/lib/features/appointments/presentation/widgets/appointment_sections.dart` | `appointments_cubit.dart` | `backend/app/appointments/` |
| الخطة | `app/lib/features/home/presentation/pages/plan_page.dart`، `widgets/home_category_control.dart` | أقسام الدواء والقياس والموعد من ميزاتها | المجالات الثلاثة |
| السجل وتصدير PDF | `app/lib/features/home/presentation/pages/record_page.dart`، `widgets/record_export_sheet.dart` | `app/lib/features/home/data/record_pdf_exporter.dart` وأقسام السجل في المجالات | المجالات الثلاثة |
| نموذج الدواء وتفاصيله | `app/lib/features/medications/presentation/pages/medication_form_page.dart`، `medication_details_page.dart` | `medications_cubit.dart`، `medication_occurrences_cubit.dart` | `backend/app/medications/` |
| نموذج خطة القياس | `app/lib/features/measurements/presentation/pages/measurement_plan_form_page.dart` | `measurement_plans_cubit.dart` | `backend/app/measurements/` |
| نموذج الموعد وورقة الزيارة | `app/lib/features/appointments/presentation/pages/appointment_form_page.dart`، `visit_page.dart` | `appointments_cubit.dart`، `visit_cubit.dart`، `visit_audio_service.dart` | `backend/app/appointments/` |
| الدائرة وأعضاؤها | `app/lib/features/circles/presentation/pages/circle_tab_screen.dart` | `circle_overview_cubit.dart` ومكوّنات الدائرة | `backend/app/circles/` |
| الملف الطبي وبطاقة الطوارئ | `app/lib/features/circles/presentation/pages/medical_file_screen.dart`، `medical_file_edit_screen.dart`، `emergency_card_screen.dart` | Cubits الملف والطوارئ | `backend/app/circles/` |
| الحساب وصورة المستخدم | `app/lib/features/account/presentation/pages/account_screen.dart`، `account_edit_screen.dart`، `app/lib/core/media/person_photo.dart` | `account_cubit.dart`، `private_photo.dart` | `backend/app/users/`، `backend/app/photos.py` |
| تسجيل الدخول والتهيئة الأولى | `app/lib/features/auth/presentation/pages/`، `app/lib/features/onboarding/presentation/pages/` | Cubits المجالين | `backend/app/auth/`، `backend/app/users/routes.py` لحفظ بيانات الحساب |
| مواقيت الصلاة | مدمجة داخل `today_page.dart` | `prayer_times_cubit.dart` و`prayer_times_repository.dart` | `backend/app/prayer_times/` |

## مسار التنفيذ المختصر

`app_router.dart` يفتح الصفحة ويجهز Cubits ← صفحة Home ترتب الأقسام ← الـWidget المتخصص في مجاله يعرض الحالة ويتلقى الضغط ← Cubit يطلب من Repository ← مصدر البيانات يستدعي API ← Route في Flask يطبق الصلاحية ويستدعي Service ← Model/Migration يحفظان البيانات.

## APNs

APNs اختصار **Apple Push Notification service**: قناة Apple لإرسال إشعار من الخادم إلى iPhone. `AppDelegate.swift` يطلب رمز جهاز؛ `push_registration.dart` يرفعه للخادم؛ `backend/app/push/` يرسل الرسالة إلى Apple باستخدام مفتاح `.p8` وإعدادات `APNS_*`. هذا منفصل عن تذكيرات الدواء المحلية في `phone_notifications.dart` و`dose_reminders.dart`. الخيار الافتراضي للخادم `PUSH_BACKEND=none`؛ حالة التشغيل الفعلية تعتمد على بيئة النشر.

المفتاح `backend/secrets/AuthKey_JUJ74B4CS8.p8` أُضيف في commit `7a5dff9` على الفرع البعيد. غير موجود في الشجرة المحلية بعد الدمج، لكنه لا يزال في تاريخ Git البعيد؛ يلزم إبطاله وإصدار مفتاح جديد إذا كان حقيقيًا.

## الفهرس الكامل للملفات البرمجية

يسرد هذا الفهرس كل ملفات Dart داخل `app/lib`، وكل Python داخل `backend/app`، والمهاجرات والاختبارات الموجودة محليًا. الملفات المولدة موسومة. لا يشمل الصور وحزم الطرف الثالث وملفات البناء و`.worktrees`.

### Flutter: التطبيق (329 ملف)

| الملف | نوعه | التعريفات المباشرة داخله |
|---|---|---|
| [`app/lib/core/constants/app_colors.dart`](app/lib/core/constants/app_colors.dart) | تصميم وثوابت مشتركة | `AppColors` |
| [`app/lib/core/constants/app_enums.dart`](app/lib/core/constants/app_enums.dart) | تصميم وثوابت مشتركة | `LoadingState`, `NetworkStatus`, `StateLoadUser`, `AuthStatus`, `LanguagesEnum` |
| [`app/lib/core/constants/app_icons.dart`](app/lib/core/constants/app_icons.dart) | تصميم وثوابت مشتركة | `AppIcons` |
| [`app/lib/core/constants/app_images.dart`](app/lib/core/constants/app_images.dart) | تصميم وثوابت مشتركة | `AppImages` |
| [`app/lib/core/di/configure_dependencies.config.dart`](app/lib/core/di/configure_dependencies.config.dart) | مولّد آلي | كود مولّد؛ لا يُعدّل يدويًا |
| [`app/lib/core/di/configure_dependencies.dart`](app/lib/core/di/configure_dependencies.dart) | حقن اعتماديات | `configureDependencies` |
| [`app/lib/core/di/third_part.dart`](app/lib/core/di/third_part.dart) | حقن اعتماديات | `ThirdPartyConfig` |
| [`app/lib/core/errors/failure.dart`](app/lib/core/errors/failure.dart) | تهيئة/أداة | `Failure`, `ServerFailure`, `NetworkFailure`, `TimeoutFailure`, `NotFoundFailure`, `UnauthorizedFailure`, `SessionExpiredFailure`, `ForbiddenFailure`, `CacheFailure`, `ValidationFailure`, `ConflictFailure`, `EmptyDataFailure`, `FormatFailure`, `StorageFailure`, `UploadFailure`, `DownloadFailure`, `PermissionFailure`, `LocationFailure`, `CameraFailure`, `UnknownFailure`, `CancelledFailure` |
| [`app/lib/core/errors/network_exceptions.dart`](app/lib/core/errors/network_exceptions.dart) | تهيئة/أداة | `FailureExceptions` |
| [`app/lib/core/extensions/color_extensions.dart`](app/lib/core/extensions/color_extensions.dart) | تهيئة/أداة | `ColorExtensions` |
| [`app/lib/core/extensions/context_extensions.dart`](app/lib/core/extensions/context_extensions.dart) | تهيئة/أداة | `ContextExtensions` |
| [`app/lib/core/extensions/font_extensions.dart`](app/lib/core/extensions/font_extensions.dart) | تهيئة/أداة | `ResponsiveFontSizer` |
| [`app/lib/core/extensions/scroll_insets.dart`](app/lib/core/extensions/scroll_insets.dart) | تهيئة/أداة | `ScrollInsets` |
| [`app/lib/core/extensions/string_extensions.dart`](app/lib/core/extensions/string_extensions.dart) | تهيئة/أداة | `StringExtensions` |
| [`app/lib/core/icons/tafaqod_phosphor_icons.dart`](app/lib/core/icons/tafaqod_phosphor_icons.dart) | تهيئة/أداة | `TafaqodPhosphorIcons` |
| [`app/lib/core/media/person_photo.dart`](app/lib/core/media/person_photo.dart) | صور ووسائط مشتركة | `PersonPhoto`, `_PersonPhotoEditor`, `_PersonPhotoEditorState`, `showPersonPhotoSheet`, `personPhotoPath` |
| [`app/lib/core/media/private_photo.dart`](app/lib/core/media/private_photo.dart) | صور ووسائط مشتركة | `PhotoSource`, `PrivatePhotoRepository`, `PrivatePhoto`, `PhotoCropPage`, `_PhotoCropPageState`, `showPhotoSourceSheet`, `pickAndCropPhoto`, `openPhotoViewer` |
| [`app/lib/core/navigation/app_router.dart`](app/lib/core/navigation/app_router.dart) | تنقل ومسارات | `AppRouter` |
| [`app/lib/core/navigation/fading_branches.dart`](app/lib/core/navigation/fading_branches.dart) | تنقل ومسارات | `FadingBranches`, `_Branch`, `_BranchState` |
| [`app/lib/core/navigation/routers.dart`](app/lib/core/navigation/routers.dart) | تنقل ومسارات | `Routes` |
| [`app/lib/core/network/api_endpoints.dart`](app/lib/core/network/api_endpoints.dart) | شبكة مشتركة | `ApiEndpoints` |
| [`app/lib/core/network/api_error_body.dart`](app/lib/core/network/api_error_body.dart) | شبكة مشتركة | `ApiErrorCodes` |
| [`app/lib/core/network/api_options.dart`](app/lib/core/network/api_options.dart) | شبكة مشتركة | دوال عليا: `buildApiOptions` |
| [`app/lib/core/network/auth_interceptor.dart`](app/lib/core/network/auth_interceptor.dart) | شبكة مشتركة | `AuthInterceptor` |
| [`app/lib/core/network/dio_client.dart`](app/lib/core/network/dio_client.dart) | شبكة مشتركة | `DioClient` |
| [`app/lib/core/services/app_accessibility.dart`](app/lib/core/services/app_accessibility.dart) | خدمة جهاز مشتركة | `AppAccessibility` |
| [`app/lib/core/services/app_device_utils.dart`](app/lib/core/services/app_device_utils.dart) | خدمة جهاز مشتركة | `AppDeviceUtils` |
| [`app/lib/core/services/intro_memory.dart`](app/lib/core/services/intro_memory.dart) | خدمة جهاز مشتركة | `IntroMemory` |
| [`app/lib/core/services/local_keys_service.dart`](app/lib/core/services/local_keys_service.dart) | خدمة جهاز مشتركة | `LocalKeysService` |
| [`app/lib/core/services/native_glass.dart`](app/lib/core/services/native_glass.dart) | خدمة جهاز مشتركة | `NativeGlass` |
| [`app/lib/core/services/phone_notifications.dart`](app/lib/core/services/phone_notifications.dart) | خدمة جهاز مشتركة | `ScheduledNotification`, `PluginPhoneNotifications` |
| [`app/lib/core/services/push_registration.dart`](app/lib/core/services/push_registration.dart) | خدمة جهاز مشتركة | `PushRegistration` |
| [`app/lib/core/services/token_storage.dart`](app/lib/core/services/token_storage.dart) | خدمة جهاز مشتركة | `TokenStorageException`, `SecureTokenStorage` |
| [`app/lib/core/setup.dart`](app/lib/core/setup.dart) | تهيئة/أداة | `setup` |
| [`app/lib/core/theme/app_semantic_colors.dart`](app/lib/core/theme/app_semantic_colors.dart) | تصميم وثوابت مشتركة | `AppSemanticColors` |
| [`app/lib/core/theme/app_text_theme.dart`](app/lib/core/theme/app_text_theme.dart) | تصميم وثوابت مشتركة | `AppTextTheme` |
| [`app/lib/core/theme/app_theme.dart`](app/lib/core/theme/app_theme.dart) | تصميم وثوابت مشتركة | `AppTheme` |
| [`app/lib/core/theme/app_tokens.dart`](app/lib/core/theme/app_tokens.dart) | تصميم وثوابت مشتركة | `AppTokens`, `AppTokensContext` |
| [`app/lib/core/theme/components/button_themes.dart`](app/lib/core/theme/components/button_themes.dart) | تصميم وثوابت مشتركة | `AppButtonThemes` |
| [`app/lib/core/theme/components/feedback_themes.dart`](app/lib/core/theme/components/feedback_themes.dart) | تصميم وثوابت مشتركة | `AppFeedbackThemes` |
| [`app/lib/core/theme/components/field_themes.dart`](app/lib/core/theme/components/field_themes.dart) | تصميم وثوابت مشتركة | `AppFieldThemes` |
| [`app/lib/core/theme/components/navigation_themes.dart`](app/lib/core/theme/components/navigation_themes.dart) | تصميم وثوابت مشتركة | `AppNavigationThemes` |
| [`app/lib/core/theme/components/selection_themes.dart`](app/lib/core/theme/components/selection_themes.dart) | تصميم وثوابت مشتركة | `AppSelectionThemes` |
| [`app/lib/core/theme/components/surface_themes.dart`](app/lib/core/theme/components/surface_themes.dart) | تصميم وثوابت مشتركة | `AppSurfaceThemes` |
| [`app/lib/core/theme/foundations/app_effects.dart`](app/lib/core/theme/foundations/app_effects.dart) | تصميم وثوابت مشتركة | `AppEffects` |
| [`app/lib/core/theme/foundations/app_motion.dart`](app/lib/core/theme/foundations/app_motion.dart) | تصميم وثوابت مشتركة | `AppMotion`, `_GlassSpring` |
| [`app/lib/core/theme/foundations/app_radius.dart`](app/lib/core/theme/foundations/app_radius.dart) | تصميم وثوابت مشتركة | `AppRadius` |
| [`app/lib/core/theme/foundations/app_sizes.dart`](app/lib/core/theme/foundations/app_sizes.dart) | تصميم وثوابت مشتركة | `AppSizes` |
| [`app/lib/core/theme/foundations/app_spacing.dart`](app/lib/core/theme/foundations/app_spacing.dart) | تصميم وثوابت مشتركة | `AppSpacing` |
| [`app/lib/core/theme/materials/glass_preferences.dart`](app/lib/core/theme/materials/glass_preferences.dart) | تصميم وثوابت مشتركة | `GlassPreferences` |
| [`app/lib/core/theme/materials/glass_style.dart`](app/lib/core/theme/materials/glass_style.dart) | تصميم وثوابت مشتركة | `AppGlass` |
| [`app/lib/core/theme/materials/surface_style.dart`](app/lib/core/theme/materials/surface_style.dart) | تصميم وثوابت مشتركة | `AppSurfaces` |
| [`app/lib/core/utils/arabic_digits.dart`](app/lib/core/utils/arabic_digits.dart) | تهيئة/أداة | `ArabicDigits`, `WesternDigitsFormatter` |
| [`app/lib/core/utils/formatters.dart`](app/lib/core/utils/formatters.dart) | تهيئة/أداة | `Formatters` |
| [`app/lib/core/widgets/buttons/back_link.dart`](app/lib/core/widgets/buttons/back_link.dart) | مكوّن مشترك | `BackLink` |
| [`app/lib/core/widgets/buttons/pill_button.dart`](app/lib/core/widgets/buttons/pill_button.dart) | مكوّن مشترك | `PillButton` |
| [`app/lib/core/widgets/feedback/compact_status_badge.dart`](app/lib/core/widgets/feedback/compact_status_badge.dart) | مكوّن مشترك | `CompactStatusBadge` |
| [`app/lib/core/widgets/feedback/inline_error.dart`](app/lib/core/widgets/feedback/inline_error.dart) | مكوّن مشترك | `InlineError` |
| [`app/lib/core/widgets/feedback/status_pill.dart`](app/lib/core/widgets/feedback/status_pill.dart) | مكوّن مشترك | `StatusPill` |
| [`app/lib/core/widgets/forms/keyboard_dismiss.dart`](app/lib/core/widgets/forms/keyboard_dismiss.dart) | مكوّن مشترك | `KeyboardDismissOnTap` |
| [`app/lib/core/widgets/forms/labeled_text_field.dart`](app/lib/core/widgets/forms/labeled_text_field.dart) | مكوّن مشترك | `LabeledTextField` |
| [`app/lib/core/widgets/forms/option_chips.dart`](app/lib/core/widgets/forms/option_chips.dart) | مكوّن مشترك | `ChipOption`, `OptionChips` |
| [`app/lib/core/widgets/forms/phone_field.dart`](app/lib/core/widgets/forms/phone_field.dart) | مكوّن مشترك | `PhoneNumberFormatter`, `PhoneField`, `_CountryCodeBox` |
| [`app/lib/core/widgets/forms/stepper_control.dart`](app/lib/core/widgets/forms/stepper_control.dart) | مكوّن مشترك | `StepperControl`, `_Half` |
| [`app/lib/core/widgets/illustrations/guide_owl.dart`](app/lib/core/widgets/illustrations/guide_owl.dart) | مكوّن مشترك | `OwlPose`, `GuideOwl` |
| [`app/lib/core/widgets/layout/content_switcher.dart`](app/lib/core/widgets/layout/content_switcher.dart) | مكوّن مشترك | `ContentSwitcher` |
| [`app/lib/core/widgets/layout/inset_group.dart`](app/lib/core/widgets/layout/inset_group.dart) | مكوّن مشترك | `InsetGroup`, `_RowLabel`, `_RowError`, `InsetRow`, `InsetFieldRow`, `InsetTextRow`, `InsetChoiceButton`, `InsetBlock` |
| [`app/lib/core/widgets/layout/inset_text.dart`](app/lib/core/widgets/layout/inset_text.dart) | مكوّن مشترك | `_InsetKind`, `InsetText` |
| [`app/lib/core/widgets/layout/large_title.dart`](app/lib/core/widgets/layout/large_title.dart) | مكوّن مشترك | `LargeTitle` |
| [`app/lib/core/widgets/layout/step_header.dart`](app/lib/core/widgets/layout/step_header.dart) | مكوّن مشترك | `StepHeader` |
| [`app/lib/core/widgets/layout/step_progress.dart`](app/lib/core/widgets/layout/step_progress.dart) | مكوّن مشترك | `StepProgress` |
| [`app/lib/core/widgets/loading/loading_widget.dart`](app/lib/core/widgets/loading/loading_widget.dart) | مكوّن مشترك | `LoadingWidgetOverlay`, `LoadingWidget` |
| [`app/lib/core/widgets/loading/skeleton.dart`](app/lib/core/widgets/loading/skeleton.dart) | مكوّن مشترك | `Shimmer`, `_ShimmerState`, `SkeletonBox`, `SkeletonLine`, `SkeletonCircle`, `SkeletonSurface`, `SkeletonLargeTitle`, `SkeletonPage`, `SkeletonBlock`, `SkeletonFormGroup`, `SkeletonDetailsCard`, `SkeletonCard`, `PageSkeleton` |
| [`app/lib/core/widgets/navigation/glass.dart`](app/lib/core/widgets/navigation/glass.dart) | مكوّن مشترك | `GlassSurface`, `GlassIconButton`, `GlassCapsuleButton` |
| [`app/lib/core/widgets/navigation/glass_segmented_control.dart`](app/lib/core/widgets/navigation/glass_segmented_control.dart) | مكوّن مشترك | `GlassSegmentedControl` |
| [`app/lib/core/widgets/navigation/swipe_selection_area.dart`](app/lib/core/widgets/navigation/swipe_selection_area.dart) | مكوّن مشترك | `SwipeSelectionArea`, `_SwipeSelectionAreaState` |
| [`app/lib/core/widgets/overlays/app_alert.dart`](app/lib/core/widgets/overlays/app_alert.dart) | مكوّن مشترك | `AppAlertAction`, `AppAlert`, `_AlertButton` |
| [`app/lib/core/widgets/overlays/glass_menu.dart`](app/lib/core/widgets/overlays/glass_menu.dart) | مكوّن مشترك | `GlassMenuItem`, `GlassMenuEntry`, `_GlassMenuRoute`, `GlassMenu`, `_GlassMenuState`, `_MenuRows`, `_MenuRow` |
| [`app/lib/core/widgets/overlays/glass_sheet.dart`](app/lib/core/widgets/overlays/glass_sheet.dart) | مكوّن مشترك | `_GlassSheet` |
| [`app/lib/core/widgets/pickers/date_picker_sheet.dart`](app/lib/core/widgets/pickers/date_picker_sheet.dart) | مكوّن مشترك | `DateWheelSheet`, `_DateWheelSheetState`, `_Wheel`, `_WheelState`, `showTafaqodDateSheet` |
| [`app/lib/core/widgets/pickers/picker_sheet_frame.dart`](app/lib/core/widgets/pickers/picker_sheet_frame.dart) | مكوّن مشترك | `PickerSheetFrame` |
| [`app/lib/core/widgets/pickers/picker_wheel_style.dart`](app/lib/core/widgets/pickers/picker_wheel_style.dart) | مكوّن مشترك | `WheelPosition`, `PickerWheelStyle` |
| [`app/lib/core/widgets/pickers/time_picker_sheet.dart`](app/lib/core/widgets/pickers/time_picker_sheet.dart) | مكوّن مشترك | `_TimePickerSheet`, `_TimePickerSheetState`, `_Wheel`, `showTafaqodTimeSheet` |
| [`app/lib/dev/component_gallery.dart`](app/lib/dev/component_gallery.dart) | تهيئة/أداة | `ComponentGallery`, `_ComponentGalleryState`, `_Section` |
| [`app/lib/features/account/presentation/cubit/account_cubit.dart`](app/lib/features/account/presentation/cubit/account_cubit.dart) | Cubit/حالة | `AccountCubit` |
| [`app/lib/features/account/presentation/cubit/account_state.dart`](app/lib/features/account/presentation/cubit/account_state.dart) | Cubit/حالة | `AccountStatus`, `DeletePrompt`, `AccountState` |
| [`app/lib/features/account/presentation/pages/account_edit_screen.dart`](app/lib/features/account/presentation/pages/account_edit_screen.dart) | صفحة | `AccountEditScreen`, `_AccountEditScreenState`, `_NameField` |
| [`app/lib/features/account/presentation/pages/account_screen.dart`](app/lib/features/account/presentation/pages/account_screen.dart) | صفحة | `AccountScreen`, `_SentRequestRow` |
| [`app/lib/features/account/presentation/pages/licenses_screen.dart`](app/lib/features/account/presentation/pages/licenses_screen.dart) | صفحة | `LicensesScreen` |
| [`app/lib/features/account/presentation/widgets/account_skeleton.dart`](app/lib/features/account/presentation/widgets/account_skeleton.dart) | مكوّن واجهة | `AccountSkeleton` |
| [`app/lib/features/account/presentation/widgets/delete_dialogs.dart`](app/lib/features/account/presentation/widgets/delete_dialogs.dart) | مكوّن واجهة | `showDeleteConfirmDialog`, `showPatientChoiceDialog`, `showLastManagerDialog`, `showCancelRequestDialog`, `_confirm` |
| [`app/lib/features/account/presentation/widgets/sent_request_sheet.dart`](app/lib/features/account/presentation/widgets/sent_request_sheet.dart) | مكوّن واجهة | `_SentRequestSheet`, `_Line`, `showSentRequestSheet` |
| [`app/lib/features/account/presentation/widgets/settings_card.dart`](app/lib/features/account/presentation/widgets/settings_card.dart) | مكوّن واجهة | `SettingsSection`, `SettingsCard`, `InfoRow`, `ActionRow` |
| [`app/lib/features/account/presentation/widgets/sign_out_row.dart`](app/lib/features/account/presentation/widgets/sign_out_row.dart) | مكوّن واجهة | `SignOutRow` |
| [`app/lib/features/appointments/data/appointment_model.dart`](app/lib/features/appointments/data/appointment_model.dart) | وصول وتحويل بيانات | `AppointmentModel` |
| [`app/lib/features/appointments/data/appointment_remote_data_source.dart`](app/lib/features/appointments/data/appointment_remote_data_source.dart) | وصول وتحويل بيانات | `AppointmentRemoteDataSource` |
| [`app/lib/features/appointments/data/appointment_repository.dart`](app/lib/features/appointments/data/appointment_repository.dart) | وصول وتحويل بيانات | `AppointmentRepository` |
| [`app/lib/features/appointments/data/visit_audio_service.dart`](app/lib/features/appointments/data/visit_audio_service.dart) | وصول وتحويل بيانات | `VisitAudioService` |
| [`app/lib/features/appointments/data/visit_model.dart`](app/lib/features/appointments/data/visit_model.dart) | وصول وتحويل بيانات | `VisitModel` |
| [`app/lib/features/appointments/data/visit_remote_data_source.dart`](app/lib/features/appointments/data/visit_remote_data_source.dart) | وصول وتحويل بيانات | `VisitRemoteDataSource` |
| [`app/lib/features/appointments/data/visit_repository.dart`](app/lib/features/appointments/data/visit_repository.dart) | وصول وتحويل بيانات | `VisitRepository` |
| [`app/lib/features/appointments/domain/appointment.dart`](app/lib/features/appointments/domain/appointment.dart) | كيانات وقواعد مجال | `AppointmentKind`, `AppointmentStatus`, `CareAppointment`, `AppointmentCompanion`, `AppointmentDraft` |
| [`app/lib/features/appointments/domain/visit_paper.dart`](app/lib/features/appointments/domain/visit_paper.dart) | كيانات وقواعد مجال | `VisitPaper`, `VisitPaperDraft` |
| [`app/lib/features/appointments/presentation/cubit/appointment_companions_cubit.dart`](app/lib/features/appointments/presentation/cubit/appointment_companions_cubit.dart) | Cubit/حالة | `AppointmentCompanionsState`, `AppointmentCompanionsCubit` |
| [`app/lib/features/appointments/presentation/cubit/appointments_cubit.dart`](app/lib/features/appointments/presentation/cubit/appointments_cubit.dart) | Cubit/حالة | `AppointmentsLoadStatus`, `AppointmentsState`, `AppointmentsCubit` |
| [`app/lib/features/appointments/presentation/cubit/visit_cubit.dart`](app/lib/features/appointments/presentation/cubit/visit_cubit.dart) | Cubit/حالة | `VisitState`, `VisitCubit` |
| [`app/lib/features/appointments/presentation/pages/appointment_form_page.dart`](app/lib/features/appointments/presentation/pages/appointment_form_page.dart) | صفحة | `AppointmentFormPage`, `_AppointmentFormPageState` |
| [`app/lib/features/appointments/presentation/pages/visit_page.dart`](app/lib/features/appointments/presentation/pages/visit_page.dart) | صفحة | `VisitPage`, `_VisitEditSheet`, `_VisitEditSheetState` |
| [`app/lib/features/appointments/presentation/widgets/appointment_sections.dart`](app/lib/features/appointments/presentation/widgets/appointment_sections.dart) | مكوّن واجهة | `AppointmentPlanSection`, `AppointmentCard`, `AppointmentRecordSection`, `_AppointmentRecordSectionState`, `AppointmentTodayRow`, `appointmentTitle`, `appointmentKindTitle`, `appointmentDate`, `appointmentTime` |
| [`app/lib/features/auth/data/datasources/auth_remote_data_source.dart`](app/lib/features/auth/data/datasources/auth_remote_data_source.dart) | وصول وتحويل بيانات | `BaseAuthRemoteDataSource`, `AuthRemoteDataSource` |
| [`app/lib/features/auth/data/models/account_status_response.dart`](app/lib/features/auth/data/models/account_status_response.dart) | وصول وتحويل بيانات | `AccountStatusResponse` |
| [`app/lib/features/auth/data/models/auth_model.dart`](app/lib/features/auth/data/models/auth_model.dart) | وصول وتحويل بيانات | `AuthModel`, `AuthModelMapper` |
| [`app/lib/features/auth/data/models/auth_model.freezed.dart`](app/lib/features/auth/data/models/auth_model.freezed.dart) | مولّد آلي | كود مولّد؛ لا يُعدّل يدويًا |
| [`app/lib/features/auth/data/models/auth_model.g.dart`](app/lib/features/auth/data/models/auth_model.g.dart) | مولّد آلي | كود مولّد؛ لا يُعدّل يدويًا |
| [`app/lib/features/auth/data/models/verify_code_response.dart`](app/lib/features/auth/data/models/verify_code_response.dart) | وصول وتحويل بيانات | `VerifyCodeResponse` |
| [`app/lib/features/auth/data/repositories/auth_repository_data.dart`](app/lib/features/auth/data/repositories/auth_repository_data.dart) | وصول وتحويل بيانات | `AuthRepositoryData` |
| [`app/lib/features/auth/di/auth_di.config.dart`](app/lib/features/auth/di/auth_di.config.dart) | مولّد آلي | كود مولّد؛ لا يُعدّل يدويًا |
| [`app/lib/features/auth/di/auth_di.dart`](app/lib/features/auth/di/auth_di.dart) | حقن اعتماديات | `configureAuth` |
| [`app/lib/features/auth/domain/entities/auth_entity.dart`](app/lib/features/auth/domain/entities/auth_entity.dart) | كيانات وقواعد مجال | `AuthEntity` |
| [`app/lib/features/auth/domain/entities/sign_in_result.dart`](app/lib/features/auth/domain/entities/sign_in_result.dart) | كيانات وقواعد مجال | `SignInResult` |
| [`app/lib/features/auth/domain/failures/invalid_code_failure.dart`](app/lib/features/auth/domain/failures/invalid_code_failure.dart) | كيانات وقواعد مجال | `InvalidCodeFailure` |
| [`app/lib/features/auth/domain/failures/sign_in_failures.dart`](app/lib/features/auth/domain/failures/sign_in_failures.dart) | كيانات وقواعد مجال | `CodeExpiredFailure`, `TooManyAttemptsFailure`, `TooManyCodesFailure`, `StartAgainFailure`, `SmsUnavailableFailure` |
| [`app/lib/features/auth/domain/repositories/auth_repository_domain.dart`](app/lib/features/auth/domain/repositories/auth_repository_domain.dart) | كيانات وقواعد مجال | `AuthRepositoryDomain` |
| [`app/lib/features/auth/domain/use_cases/auth_use_case.dart`](app/lib/features/auth/domain/use_cases/auth_use_case.dart) | كيانات وقواعد مجال | `AuthUseCase` |
| [`app/lib/features/auth/presentation/cubit/auth_cubit.dart`](app/lib/features/auth/presentation/cubit/auth_cubit.dart) | Cubit/حالة | `AuthCubit` |
| [`app/lib/features/auth/presentation/cubit/auth_state.dart`](app/lib/features/auth/presentation/cubit/auth_state.dart) | Cubit/حالة | `AuthState`, `AuthInitialState`, `AuthLoadingState`, `AuthSignedOutState`, `AuthErrorState` |
| [`app/lib/features/auth/presentation/cubit/sign_in_cubit.dart`](app/lib/features/auth/presentation/cubit/sign_in_cubit.dart) | Cubit/حالة | `SignInCubit` |
| [`app/lib/features/auth/presentation/cubit/sign_in_state.dart`](app/lib/features/auth/presentation/cubit/sign_in_state.dart) | Cubit/حالة | `SignInStatus`, `SignInState` |
| [`app/lib/features/auth/presentation/cubit/splash_cubit.dart`](app/lib/features/auth/presentation/cubit/splash_cubit.dart) | Cubit/حالة | `StartDestination`, `SplashCubit` |
| [`app/lib/features/auth/presentation/pages/auth_feature_screen.dart`](app/lib/features/auth/presentation/pages/auth_feature_screen.dart) | صفحة | `_Intro`, `AuthFeatureScreen`, `_AuthFeatureScreenState`, `_TopBar`, `_IntroPage`, `_IntroPageState`, `_SpeechBubble`, `_TailPainter`, `_NextButton`, `_ProgressRingPainter` |
| [`app/lib/features/auth/presentation/pages/code_screen.dart`](app/lib/features/auth/presentation/pages/code_screen.dart) | صفحة | `CodeScreen` |
| [`app/lib/features/auth/presentation/pages/phone_screen.dart`](app/lib/features/auth/presentation/pages/phone_screen.dart) | صفحة | `PhoneScreen`, `_PhoneScreenState` |
| [`app/lib/features/auth/presentation/pages/splash_screen.dart`](app/lib/features/auth/presentation/pages/splash_screen.dart) | صفحة | `SplashScreen` |
| [`app/lib/features/auth/presentation/widgets/auth_widget.dart`](app/lib/features/auth/presentation/widgets/auth_widget.dart) | مكوّن واجهة | `AuthWidget` |
| [`app/lib/features/auth/presentation/widgets/orbit_painter.dart`](app/lib/features/auth/presentation/widgets/orbit_painter.dart) | مكوّن واجهة | `OrbitPainter` |
| [`app/lib/features/auth/presentation/widgets/otp_field.dart`](app/lib/features/auth/presentation/widgets/otp_field.dart) | مكوّن واجهة | `OtpField`, `_OtpFieldState`, `_DigitsFormatter`, `_OtpBox` |
| [`app/lib/features/circles/data/datasources/circles_remote_data_source.dart`](app/lib/features/circles/data/datasources/circles_remote_data_source.dart) | وصول وتحويل بيانات | `BaseCirclesRemoteDataSource`, `CirclesRemoteDataSource` |
| [`app/lib/features/circles/data/models/account_model.dart`](app/lib/features/circles/data/models/account_model.dart) | وصول وتحويل بيانات | `AccountModel` |
| [`app/lib/features/circles/data/models/circle_model.dart`](app/lib/features/circles/data/models/circle_model.dart) | وصول وتحويل بيانات | `CircleModel` |
| [`app/lib/features/circles/data/models/circle_overview_model.dart`](app/lib/features/circles/data/models/circle_overview_model.dart) | وصول وتحويل بيانات | `CircleOverviewModel` |
| [`app/lib/features/circles/data/models/circle_request_model.dart`](app/lib/features/circles/data/models/circle_request_model.dart) | وصول وتحويل بيانات | `NewCircleRequestModel`, `SentCircleRequestModel`, `CircleRequestsModel`, `ReceivedInvitationsModel` |
| [`app/lib/features/circles/data/models/complete_circle_request_model.dart`](app/lib/features/circles/data/models/complete_circle_request_model.dart) | وصول وتحويل بيانات | `CompleteCircleRequestModel` |
| [`app/lib/features/circles/data/models/medical_file_model.dart`](app/lib/features/circles/data/models/medical_file_model.dart) | وصول وتحويل بيانات | `MedicalProfileJson`, `EmergencyContactModel`, `MedicalFileModel`, `MedicalProfileAnswerModel`, `EmergencyCardModel`, `PatientUpdateModel`, `_contacts` |
| [`app/lib/features/circles/data/models/new_patient_circle_model.dart`](app/lib/features/circles/data/models/new_patient_circle_model.dart) | وصول وتحويل بيانات | `NewPatientCircleModel` |
| [`app/lib/features/circles/data/models/new_self_circle_model.dart`](app/lib/features/circles/data/models/new_self_circle_model.dart) | وصول وتحويل بيانات | `NewSelfCircleModel` |
| [`app/lib/features/circles/data/repositories/circles_repository_data.dart`](app/lib/features/circles/data/repositories/circles_repository_data.dart) | وصول وتحويل بيانات | `CirclesRepositoryData` |
| [`app/lib/features/circles/di/circles_di.config.dart`](app/lib/features/circles/di/circles_di.config.dart) | مولّد آلي | كود مولّد؛ لا يُعدّل يدويًا |
| [`app/lib/features/circles/di/circles_di.dart`](app/lib/features/circles/di/circles_di.dart) | حقن اعتماديات | `configureCircles` |
| [`app/lib/features/circles/domain/birth_date_rules.dart`](app/lib/features/circles/domain/birth_date_rules.dart) | كيانات وقواعد مجال | `BirthDateRules` |
| [`app/lib/features/circles/domain/circle_app_mode.dart`](app/lib/features/circles/domain/circle_app_mode.dart) | كيانات وقواعد مجال | `CircleAppMode` |
| [`app/lib/features/circles/domain/entities/account_deletion.dart`](app/lib/features/circles/domain/entities/account_deletion.dart) | كيانات وقواعد مجال | `PatientChoice`, `AccountDeletion` |
| [`app/lib/features/circles/domain/entities/account_summary.dart`](app/lib/features/circles/domain/entities/account_summary.dart) | كيانات وقواعد مجال | `AccountSummary` |
| [`app/lib/features/circles/domain/entities/circle_inbox.dart`](app/lib/features/circles/domain/entities/circle_inbox.dart) | كيانات وقواعد مجال | `CircleInbox` |
| [`app/lib/features/circles/domain/entities/circle_overview.dart`](app/lib/features/circles/domain/entities/circle_overview.dart) | كيانات وقواعد مجال | `CircleOverview`, `CircleMember`, `CirclePendingInvitation` |
| [`app/lib/features/circles/domain/entities/complete_circle_request.dart`](app/lib/features/circles/domain/entities/complete_circle_request.dart) | كيانات وقواعد مجال | `CompleteCircleRequest` |
| [`app/lib/features/circles/domain/entities/emergency_card.dart`](app/lib/features/circles/domain/entities/emergency_card.dart) | كيانات وقواعد مجال | `EmergencyCard` |
| [`app/lib/features/circles/domain/entities/emergency_contact.dart`](app/lib/features/circles/domain/entities/emergency_contact.dart) | كيانات وقواعد مجال | `EmergencyContact`, `ContactDraft` |
| [`app/lib/features/circles/domain/entities/medical_file.dart`](app/lib/features/circles/domain/entities/medical_file.dart) | كيانات وقواعد مجال | `PatientBasics`, `MedicalGap`, `MedicalFile` |
| [`app/lib/features/circles/domain/entities/medical_profile_draft.dart`](app/lib/features/circles/domain/entities/medical_profile_draft.dart) | كيانات وقواعد مجال | `ListAnswer`, `ConditionsDraft`, `AllergiesDraft`, `MedicalProfileDraft` |
| [`app/lib/features/circles/domain/entities/new_circle_request.dart`](app/lib/features/circles/domain/entities/new_circle_request.dart) | كيانات وقواعد مجال | `NewCircleRequest`, `CircleRequestStatus`, `SentCircleRequest` |
| [`app/lib/features/circles/domain/entities/new_patient_circle.dart`](app/lib/features/circles/domain/entities/new_patient_circle.dart) | كيانات وقواعد مجال | `NewPatientCircle` |
| [`app/lib/features/circles/domain/entities/new_self_circle.dart`](app/lib/features/circles/domain/entities/new_self_circle.dart) | كيانات وقواعد مجال | `NewSelfCircle` |
| [`app/lib/features/circles/domain/entities/patient_update.dart`](app/lib/features/circles/domain/entities/patient_update.dart) | كيانات وقواعد مجال | `PatientUpdate` |
| [`app/lib/features/circles/domain/entities/received_circle_request.dart`](app/lib/features/circles/domain/entities/received_circle_request.dart) | كيانات وقواعد مجال | `ReceivedCircleRequest` |
| [`app/lib/features/circles/domain/entities/received_invitation.dart`](app/lib/features/circles/domain/entities/received_invitation.dart) | كيانات وقواعد مجال | `ReceivedInvitation` |
| [`app/lib/features/circles/domain/failures/circle_failures.dart`](app/lib/features/circles/domain/failures/circle_failures.dart) | كيانات وقواعد مجال | `AlreadyHasCircleFailure`, `ProfileIncompleteFailure`, `InvalidBirthDateFailure`, `ModeConflictFailure`, `SelfRequestFailure`, `PatientHasCircleFailure`, `RequestUnavailableFailure`, `AcceptedRequestExistsFailure`, `ReplyModeConflictFailure`, `PatientChoiceRequiredFailure`, `LastManagerFailure`, `TooManyContactsFailure`, `DuplicateContactFailure` |
| [`app/lib/features/circles/domain/medical_form.dart`](app/lib/features/circles/domain/medical_form.dart) | كيانات وقواعد مجال | `MedicalForm` |
| [`app/lib/features/circles/domain/medical_options.dart`](app/lib/features/circles/domain/medical_options.dart) | كيانات وقواعد مجال | `MedicalOptions` |
| [`app/lib/features/circles/domain/repositories/circles_repository_domain.dart`](app/lib/features/circles/domain/repositories/circles_repository_domain.dart) | كيانات وقواعد مجال | `CirclesRepositoryDomain` |
| [`app/lib/features/circles/domain/request_age.dart`](app/lib/features/circles/domain/request_age.dart) | كيانات وقواعد مجال | `RequestAge` |
| [`app/lib/features/circles/domain/saudi_cities.dart`](app/lib/features/circles/domain/saudi_cities.dart) | كيانات وقواعد مجال | `SaudiCities` |
| [`app/lib/features/circles/domain/use_cases/circles_use_case.dart`](app/lib/features/circles/domain/use_cases/circles_use_case.dart) | كيانات وقواعد مجال | `CirclesUseCase` |
| [`app/lib/features/circles/presentation/circle_creation_finish.dart`](app/lib/features/circles/presentation/circle_creation_finish.dart) | تهيئة/أداة | `createCircleAndOpen` |
| [`app/lib/features/circles/presentation/cubit/circle_overview_cubit.dart`](app/lib/features/circles/presentation/cubit/circle_overview_cubit.dart) | Cubit/حالة | `CircleOverviewStatus`, `CircleOverviewState`, `CircleOverviewCubit` |
| [`app/lib/features/circles/presentation/cubit/create_circle_cubit.dart`](app/lib/features/circles/presentation/cubit/create_circle_cubit.dart) | Cubit/حالة | `CreateCircleCubit` |
| [`app/lib/features/circles/presentation/cubit/create_circle_state.dart`](app/lib/features/circles/presentation/cubit/create_circle_state.dart) | Cubit/حالة | `NamePreset`, `CircleFlow`, `AccountLoad`, `CreateStatus`, `CreateCircleState` |
| [`app/lib/features/circles/presentation/cubit/emergency_card_cubit.dart`](app/lib/features/circles/presentation/cubit/emergency_card_cubit.dart) | Cubit/حالة | `EmergencyCardCubit` |
| [`app/lib/features/circles/presentation/cubit/emergency_card_state.dart`](app/lib/features/circles/presentation/cubit/emergency_card_state.dart) | Cubit/حالة | `EmergencyCardStatus`, `EmergencyCardState` |
| [`app/lib/features/circles/presentation/cubit/inbox_cubit.dart`](app/lib/features/circles/presentation/cubit/inbox_cubit.dart) | Cubit/حالة | `InboxCubit` |
| [`app/lib/features/circles/presentation/cubit/inbox_state.dart`](app/lib/features/circles/presentation/cubit/inbox_state.dart) | Cubit/حالة | `InboxStatus`, `InboxState` |
| [`app/lib/features/circles/presentation/cubit/medical_file_cubit.dart`](app/lib/features/circles/presentation/cubit/medical_file_cubit.dart) | Cubit/حالة | `MedicalFileCubit` |
| [`app/lib/features/circles/presentation/cubit/medical_file_edit_cubit.dart`](app/lib/features/circles/presentation/cubit/medical_file_edit_cubit.dart) | Cubit/حالة | `MedicalFileEditCubit` |
| [`app/lib/features/circles/presentation/cubit/medical_file_edit_state.dart`](app/lib/features/circles/presentation/cubit/medical_file_edit_state.dart) | Cubit/حالة | `MedicalFileEditStatus`, `MedicalFileEditState` |
| [`app/lib/features/circles/presentation/cubit/medical_file_state.dart`](app/lib/features/circles/presentation/cubit/medical_file_state.dart) | Cubit/حالة | `MedicalFileStatus`, `ContactForm`, `MedicalFileState` |
| [`app/lib/features/circles/presentation/cubit/request_reply_cubit.dart`](app/lib/features/circles/presentation/cubit/request_reply_cubit.dart) | Cubit/حالة | `RequestReplyCubit` |
| [`app/lib/features/circles/presentation/cubit/request_reply_state.dart`](app/lib/features/circles/presentation/cubit/request_reply_state.dart) | Cubit/حالة | `ReplyOutcome`, `RequestReplyState` |
| [`app/lib/features/circles/presentation/cubit/send_circle_request_cubit.dart`](app/lib/features/circles/presentation/cubit/send_circle_request_cubit.dart) | Cubit/حالة | `SendCircleRequestCubit` |
| [`app/lib/features/circles/presentation/cubit/send_circle_request_state.dart`](app/lib/features/circles/presentation/cubit/send_circle_request_state.dart) | Cubit/حالة | `SendStatus`, `SendCircleRequestState` |
| [`app/lib/features/circles/presentation/pages/approved_circle_basics_screen.dart`](app/lib/features/circles/presentation/pages/approved_circle_basics_screen.dart) | صفحة | `ApprovedCircleBasicsScreen` |
| [`app/lib/features/circles/presentation/pages/circle_tab_screen.dart`](app/lib/features/circles/presentation/pages/circle_tab_screen.dart) | صفحة | `CircleTabScreen`, `_CircleContent`, `CircleCard`, `_Fact`, `_AppMode`, `_CircleFeatureTile`, `_MembersHeader`, `_MembersList`, `_Avatar`, `_MemberRow`, `_YouPill`, `_InvitationRow`, `_SmallAction`, `_InviteMemberSheet`, `_InviteMemberSheetState` |
| [`app/lib/features/circles/presentation/pages/emergency_card_screen.dart`](app/lib/features/circles/presentation/pages/emergency_card_screen.dart) | صفحة | `EmergencyCardScreen`, `_EmergencyCardScreenState`, `_CardText`, `_LanguageSwitch`, `_Segment`, `_Card`, `_Badge`, `_BloodType`, `_AllergyBox`, `_Line`, `_Rule`, `_Medicines`, `_Medicine`, `_Contacts`, `_AmbulanceButton`, `_WhySeparate` |
| [`app/lib/features/circles/presentation/pages/medical_file_edit_screen.dart`](app/lib/features/circles/presentation/pages/medical_file_edit_screen.dart) | صفحة | `MedicalFileEditScreen`, `_EditForm`, `_EditFormState` |
| [`app/lib/features/circles/presentation/pages/medical_file_screen.dart`](app/lib/features/circles/presentation/pages/medical_file_screen.dart) | صفحة | `MedicalFileScreen` |
| [`app/lib/features/circles/presentation/pages/notifications_screen.dart`](app/lib/features/circles/presentation/pages/notifications_screen.dart) | صفحة | `NotificationsScreen` |
| [`app/lib/features/circles/presentation/pages/patient_circle_basics_screen.dart`](app/lib/features/circles/presentation/pages/patient_circle_basics_screen.dart) | صفحة | `PatientCircleBasicsScreen`, `_PatientCircleBasicsScreenState` |
| [`app/lib/features/circles/presentation/pages/request_patient_screen.dart`](app/lib/features/circles/presentation/pages/request_patient_screen.dart) | صفحة | `RequestPatientScreen`, `_RequestPatientScreenState`, `_Notice` |
| [`app/lib/features/circles/presentation/pages/request_reply_screen.dart`](app/lib/features/circles/presentation/pages/request_reply_screen.dart) | صفحة | `RequestReplyScreen`, `_RequestDetails`, `_Row` |
| [`app/lib/features/circles/presentation/pages/self_circle_basics_screen.dart`](app/lib/features/circles/presentation/pages/self_circle_basics_screen.dart) | صفحة | `SelfCircleBasicsScreen`, `_SelfCircleBasicsScreenState` |
| [`app/lib/features/circles/presentation/widgets/account_name_field.dart`](app/lib/features/circles/presentation/widgets/account_name_field.dart) | مكوّن واجهة | `AccountNameField` |
| [`app/lib/features/circles/presentation/widgets/already_has_circle_view.dart`](app/lib/features/circles/presentation/widgets/already_has_circle_view.dart) | مكوّن واجهة | `AlreadyHasCircleView` |
| [`app/lib/features/circles/presentation/widgets/birth_date_city_fields.dart`](app/lib/features/circles/presentation/widgets/birth_date_city_fields.dart) | مكوّن واجهة | `BirthDateCityFields` |
| [`app/lib/features/circles/presentation/widgets/birth_date_sheet.dart`](app/lib/features/circles/presentation/widgets/birth_date_sheet.dart) | مكوّن واجهة | `BirthDateSheet`, `showBirthDateSheet`, `formatBirthDate` |
| [`app/lib/features/circles/presentation/widgets/circle_skeletons.dart`](app/lib/features/circles/presentation/widgets/circle_skeletons.dart) | مكوّن واجهة | `NotificationsSkeleton`, `_RequestCardSkeleton`, `MedicalFileSkeleton`, `_ContactSkeleton`, `EmergencyCardSkeleton`, `_SectionSkeleton`, `MedicalFileEditSkeleton`, `_ChipsSkeleton` |
| [`app/lib/features/circles/presentation/widgets/circle_step_header.dart`](app/lib/features/circles/presentation/widgets/circle_step_header.dart) | مكوّن واجهة | `CircleStepHeader` |
| [`app/lib/features/circles/presentation/widgets/city_sheet.dart`](app/lib/features/circles/presentation/widgets/city_sheet.dart) | مكوّن واجهة | `CitySheet`, `_CitySheetState`, `showCitySheet` |
| [`app/lib/features/circles/presentation/widgets/contact_dialogs.dart`](app/lib/features/circles/presentation/widgets/contact_dialogs.dart) | مكوّن واجهة | `showDeleteContactDialog` |
| [`app/lib/features/circles/presentation/widgets/contact_form_card.dart`](app/lib/features/circles/presentation/widgets/contact_form_card.dart) | مكوّن واجهة | `ContactFormCard`, `_ContactFormCardState` |
| [`app/lib/features/circles/presentation/widgets/contact_tile.dart`](app/lib/features/circles/presentation/widgets/contact_tile.dart) | مكوّن واجهة | `ContactTile` |
| [`app/lib/features/circles/presentation/widgets/emergency_card_export.dart`](app/lib/features/circles/presentation/widgets/emergency_card_export.dart) | مكوّن واجهة | `shareEmergencyCardPdf` |
| [`app/lib/features/circles/presentation/widgets/inbox_cards.dart`](app/lib/features/circles/presentation/widgets/inbox_cards.dart) | مكوّن واجهة | `_InboxCard`, `_ReplyButtons`, `InvitationCard`, `RequestCard`, `AcceptedRequestCard`, `DeclinedRequestCard`, `_initial` |
| [`app/lib/features/circles/presentation/widgets/medical_file_alert.dart`](app/lib/features/circles/presentation/widgets/medical_file_alert.dart) | مكوّن واجهة | `AttentionMark`, `MedicalFileAlert`, `medicalGapsText` |
| [`app/lib/features/circles/presentation/widgets/medical_texts.dart`](app/lib/features/circles/presentation/widgets/medical_texts.dart) | مكوّن واجهة | `MedicalTexts` |
| [`app/lib/features/circles/presentation/widgets/picker_field.dart`](app/lib/features/circles/presentation/widgets/picker_field.dart) | مكوّن واجهة | `PickerField` |
| [`app/lib/features/circles/presentation/widgets/read_only_field.dart`](app/lib/features/circles/presentation/widgets/read_only_field.dart) | مكوّن واجهة | `ReadOnlyField` |
| [`app/lib/features/circles/presentation/widgets/request_sent_view.dart`](app/lib/features/circles/presentation/widgets/request_sent_view.dart) | مكوّن واجهة | `RequestSentView`, `_DetailsCard`, `_DetailRow` |
| [`app/lib/features/circles/presentation/widgets/step_actions.dart`](app/lib/features/circles/presentation/widgets/step_actions.dart) | مكوّن واجهة | `StepActions` |
| [`app/lib/features/home/data/datasources/home_local_data_source.dart`](app/lib/features/home/data/datasources/home_local_data_source.dart) | وصول وتحويل بيانات | `HomeLocalDataSource` |
| [`app/lib/features/home/data/datasources/home_remote_data_source.dart`](app/lib/features/home/data/datasources/home_remote_data_source.dart) | وصول وتحويل بيانات | `BaseHomeRemoteDataSource`, `HomeRemoteDataSource` |
| [`app/lib/features/home/data/models/home_model.dart`](app/lib/features/home/data/models/home_model.dart) | وصول وتحويل بيانات | `HomeModel` |
| [`app/lib/features/home/data/record_pdf_exporter.dart`](app/lib/features/home/data/record_pdf_exporter.dart) | وصول وتحويل بيانات | `RecordPdfRow`, `RecordPdfItem`, `RecordPdfSection`, `RecordPdfExporter` |
| [`app/lib/features/home/data/repositories/home_repository_data.dart`](app/lib/features/home/data/repositories/home_repository_data.dart) | وصول وتحويل بيانات | `HomeRepositoryData` |
| [`app/lib/features/home/di/home_di.config.dart`](app/lib/features/home/di/home_di.config.dart) | مولّد آلي | كود مولّد؛ لا يُعدّل يدويًا |
| [`app/lib/features/home/di/home_di.dart`](app/lib/features/home/di/home_di.dart) | حقن اعتماديات | `configureHome` |
| [`app/lib/features/home/domain/entities/home_entity.dart`](app/lib/features/home/domain/entities/home_entity.dart) | كيانات وقواعد مجال | `CareCircleSummary`, `HomeEntity` |
| [`app/lib/features/home/domain/repositories/home_repository_domain.dart`](app/lib/features/home/domain/repositories/home_repository_domain.dart) | كيانات وقواعد مجال | `HomeRepositoryDomain` |
| [`app/lib/features/home/domain/use_cases/home_use_case.dart`](app/lib/features/home/domain/use_cases/home_use_case.dart) | كيانات وقواعد مجال | `HomeUseCase` |
| [`app/lib/features/home/presentation/cubit/home_cubit.dart`](app/lib/features/home/presentation/cubit/home_cubit.dart) | Cubit/حالة | `HomeCubit` |
| [`app/lib/features/home/presentation/cubit/home_state.dart`](app/lib/features/home/presentation/cubit/home_state.dart) | Cubit/حالة | `HomeStatus`, `HomeState` |
| [`app/lib/features/home/presentation/cubit/record_export_cubit.dart`](app/lib/features/home/presentation/cubit/record_export_cubit.dart) | Cubit/حالة | `RecordExportStatus`, `RecordExportState`, `RecordExportCubit` |
| [`app/lib/features/home/presentation/pages/home_feature_screen.dart`](app/lib/features/home/presentation/pages/home_feature_screen.dart) | صفحة | `HomeFeatureScreen`, `_HomeFeatureScreenState` |
| [`app/lib/features/home/presentation/pages/plan_page.dart`](app/lib/features/home/presentation/pages/plan_page.dart) | صفحة | `PlanPage`, `_PlanPageState` |
| [`app/lib/features/home/presentation/pages/record_page.dart`](app/lib/features/home/presentation/pages/record_page.dart) | صفحة | `RecordPage`, `_RecordPageState` |
| [`app/lib/features/home/presentation/pages/today_page.dart`](app/lib/features/home/presentation/pages/today_page.dart) | صفحة | `TodayPage`, `_TodayPageState`, `_NextTaskCard`, `_SectionTitle`, `_PrayerPeriod` |
| [`app/lib/features/home/presentation/widgets/home_add_sheet.dart`](app/lib/features/home/presentation/widgets/home_add_sheet.dart) | مكوّن واجهة | `_HomeAddSheet`, `_QuickAction`, `_LabelledLine`, `_PlanOption`, `_RowDivider`, `showHomeAddSheet` |
| [`app/lib/features/home/presentation/widgets/home_category_control.dart`](app/lib/features/home/presentation/widgets/home_category_control.dart) | مكوّن واجهة | `HomeCategoryControl` |
| [`app/lib/features/home/presentation/widgets/home_widget.dart`](app/lib/features/home/presentation/widgets/home_widget.dart) | مكوّن واجهة | `HomeWidget`, `_HomeWidgetState` |
| [`app/lib/features/home/presentation/widgets/record_export_sheet.dart`](app/lib/features/home/presentation/widgets/record_export_sheet.dart) | مكوّن واجهة | `_RecordExportSheet`, `_RecordExportSheetState`, `showRecordExportSheet` |
| [`app/lib/features/home/presentation/widgets/selected_circle_builder.dart`](app/lib/features/home/presentation/widgets/selected_circle_builder.dart) | مكوّن واجهة | `SelectedCircleBuilder` |
| [`app/lib/features/measurements/data/measurement_repository.dart`](app/lib/features/measurements/data/measurement_repository.dart) | وصول وتحويل بيانات | `MeasurementRepository` |
| [`app/lib/features/measurements/domain/measurement.dart`](app/lib/features/measurements/domain/measurement.dart) | كيانات وقواعد مجال | `MeasurementKind`, `MeasurementStatus`, `MeasurementTarget`, `MeasurementVersion`, `MeasurementPlan`, `MeasurementReading`, `MeasurementOccurrence`, `MeasurementPlanDraft`, `MeasurementReadingDraft`, `measurementDate`, `_date` |
| [`app/lib/features/measurements/presentation/cubit/measurement_plans_cubit.dart`](app/lib/features/measurements/presentation/cubit/measurement_plans_cubit.dart) | Cubit/حالة | `MeasurementPlansCubit` |
| [`app/lib/features/measurements/presentation/cubit/measurement_readings_cubit.dart`](app/lib/features/measurements/presentation/cubit/measurement_readings_cubit.dart) | Cubit/حالة | `MeasurementReadingsCubit` |
| [`app/lib/features/measurements/presentation/cubit/measurement_states.dart`](app/lib/features/measurements/presentation/cubit/measurement_states.dart) | Cubit/حالة | `MeasurementLoadStatus`, `MeasurementPlansState`, `MeasurementTasksState`, `MeasurementReadingsState` |
| [`app/lib/features/measurements/presentation/cubit/measurement_targets_cubit.dart`](app/lib/features/measurements/presentation/cubit/measurement_targets_cubit.dart) | Cubit/حالة | `MeasurementTargetsState`, `MeasurementTargetsCubit` |
| [`app/lib/features/measurements/presentation/cubit/measurement_tasks_cubit.dart`](app/lib/features/measurements/presentation/cubit/measurement_tasks_cubit.dart) | Cubit/حالة | `MeasurementTasksCubit` |
| [`app/lib/features/measurements/presentation/pages/measurement_plan_form_page.dart`](app/lib/features/measurements/presentation/pages/measurement_plan_form_page.dart) | صفحة | `MeasurementPlanFormPage`, `_MeasurementPlanFormPageState` |
| [`app/lib/features/measurements/presentation/widgets/measurement_plan_section.dart`](app/lib/features/measurements/presentation/widgets/measurement_plan_section.dart) | مكوّن واجهة | `MeasurementPlanSection`, `MeasurementPlanCard`, `_MeasurementPlanCardState` |
| [`app/lib/features/measurements/presentation/widgets/measurement_reading_sheet.dart`](app/lib/features/measurements/presentation/widgets/measurement_reading_sheet.dart) | مكوّن واجهة | `MeasurementReadingSheet`, `_MeasurementReadingSheetState`, `showMeasurementReadingSheet` |
| [`app/lib/features/measurements/presentation/widgets/measurement_record_section.dart`](app/lib/features/measurements/presentation/widgets/measurement_record_section.dart) | مكوّن واجهة | `MeasurementRecordSection`, `_MeasurementRecordSectionState` |
| [`app/lib/features/measurements/presentation/widgets/measurement_today_section.dart`](app/lib/features/measurements/presentation/widgets/measurement_today_section.dart) | مكوّن واجهة | `MeasurementAttentionSection`, `MeasurementTaskRow`, `_title`, `_time` |
| [`app/lib/features/measurements/presentation/widgets/measurement_visuals.dart`](app/lib/features/measurements/presentation/widgets/measurement_visuals.dart) | مكوّن واجهة | `MeasurementChart`, `_MeasurementPainter`, `MeasurementCalendar`, `_MeasurementCalendarState` |
| [`app/lib/features/medications/data/datasources/medications_remote_data_source.dart`](app/lib/features/medications/data/datasources/medications_remote_data_source.dart) | وصول وتحويل بيانات | `BaseMedicationsRemoteDataSource`, `MedicationsRemoteDataSource` |
| [`app/lib/features/medications/data/models/dose_occurrence_model.dart`](app/lib/features/medications/data/models/dose_occurrence_model.dart) | وصول وتحويل بيانات | `DoseOccurrenceModel`, `DoseRecordModel` |
| [`app/lib/features/medications/data/models/medication_plan_model.dart`](app/lib/features/medications/data/models/medication_plan_model.dart) | وصول وتحويل بيانات | `MedicationPlanModel` |
| [`app/lib/features/medications/data/models/medications_model.dart`](app/lib/features/medications/data/models/medications_model.dart) | وصول وتحويل بيانات | يعيد تصدير: `dose_occurrence_model.dart`, `medication_plan_model.dart` |
| [`app/lib/features/medications/data/repositories/medications_repository_data.dart`](app/lib/features/medications/data/repositories/medications_repository_data.dart) | وصول وتحويل بيانات | `MedicationsRepositoryData` |
| [`app/lib/features/medications/di/medications_di.config.dart`](app/lib/features/medications/di/medications_di.config.dart) | مولّد آلي | كود مولّد؛ لا يُعدّل يدويًا |
| [`app/lib/features/medications/di/medications_di.dart`](app/lib/features/medications/di/medications_di.dart) | حقن اعتماديات | `configureMedications` |
| [`app/lib/features/medications/domain/dose_reminders.dart`](app/lib/features/medications/domain/dose_reminders.dart) | كيانات وقواعد مجال | `ReminderCircle`, `DoseReminderTexts`, `DoseReminders`, `isReminderPayload`, `doseMoment`, `planDoseReminders` |
| [`app/lib/features/medications/domain/dose_timing.dart`](app/lib/features/medications/domain/dose_timing.dart) | كيانات وقواعد مجال | دوال عليا: `medicationTimingState` |
| [`app/lib/features/medications/domain/entities/dose_occurrence.dart`](app/lib/features/medications/domain/entities/dose_occurrence.dart) | كيانات وقواعد مجال | `DoseOutcome`, `DoseTimingState`, `DoseSkipReason`, `DoseRecord`, `DoseOccurrence`, `DoseRecordDraft` |
| [`app/lib/features/medications/domain/entities/medication_plan.dart`](app/lib/features/medications/domain/entities/medication_plan.dart) | كيانات وقواعد مجال | `MedicationVersion`, `MedicationPlan`, `MedicationLastRecord`, `MedicationPlanDraft` |
| [`app/lib/features/medications/domain/entities/medication_schedule.dart`](app/lib/features/medications/domain/entities/medication_schedule.dart) | كيانات وقواعد مجال | `DosageForm`, `DoseUnit`, `StrengthUnit`, `DosageFormUnit`, `DoseUnitValue`, `MedicationSchedule`, `MedicationScheduleDraft` |
| [`app/lib/features/medications/domain/entities/medications_entity.dart`](app/lib/features/medications/domain/entities/medications_entity.dart) | كيانات وقواعد مجال | يعيد تصدير: `dose_occurrence.dart`, `medication_plan.dart`, `medication_schedule.dart` |
| [`app/lib/features/medications/domain/repositories/medications_repository_domain.dart`](app/lib/features/medications/domain/repositories/medications_repository_domain.dart) | كيانات وقواعد مجال | `MedicationsRepositoryDomain` |
| [`app/lib/features/medications/domain/use_cases/medications_use_case.dart`](app/lib/features/medications/domain/use_cases/medications_use_case.dart) | كيانات وقواعد مجال | `MedicationsUseCase` |
| [`app/lib/features/medications/presentation/cubit/medication_occurrences_cubit.dart`](app/lib/features/medications/presentation/cubit/medication_occurrences_cubit.dart) | Cubit/حالة | `MedicationOccurrencesCubit` |
| [`app/lib/features/medications/presentation/cubit/medication_occurrences_state.dart`](app/lib/features/medications/presentation/cubit/medication_occurrences_state.dart) | Cubit/حالة | `MedicationOccurrencesStatus`, `MedicationOccurrencesState` |
| [`app/lib/features/medications/presentation/cubit/medications_cubit.dart`](app/lib/features/medications/presentation/cubit/medications_cubit.dart) | Cubit/حالة | `MedicationsCubit` |
| [`app/lib/features/medications/presentation/cubit/medications_state.dart`](app/lib/features/medications/presentation/cubit/medications_state.dart) | Cubit/حالة | `MedicationsStatus`, `MedicationRecordFilter`, `MedicationsState` |
| [`app/lib/features/medications/presentation/dose_reminder_texts.dart`](app/lib/features/medications/presentation/dose_reminder_texts.dart) | تهيئة/أداة | دوال عليا: `DoseReminderTexts` |
| [`app/lib/features/medications/presentation/medication_format.dart`](app/lib/features/medications/presentation/medication_format.dart) | تهيئة/أداة | `formatMedicationNumber`, `formatMedicationDate`, `formatMedicationTime` |
| [`app/lib/features/medications/presentation/models/medication_form_data.dart`](app/lib/features/medications/presentation/models/medication_form_data.dart) | تهيئة/أداة | `MedicationFormField`, `MedicationFormIssue`, `MedicationFormData` |
| [`app/lib/features/medications/presentation/models/medication_schedule_form_data.dart`](app/lib/features/medications/presentation/models/medication_schedule_form_data.dart) | تهيئة/أداة | `ScheduleFormData` |
| [`app/lib/features/medications/presentation/pages/medication_details_page.dart`](app/lib/features/medications/presentation/pages/medication_details_page.dart) | صفحة | `MedicationDetailsPage`, `_Content`, `_PendingRevision` |
| [`app/lib/features/medications/presentation/pages/medication_form_page.dart`](app/lib/features/medications/presentation/pages/medication_form_page.dart) | صفحة | `MedicationFormPage` |
| [`app/lib/features/medications/presentation/pages/medications_feature_screen.dart`](app/lib/features/medications/presentation/pages/medications_feature_screen.dart) | صفحة | يعيد تصدير: `medication_details_page.dart`, `medication_form_page.dart` |
| [`app/lib/features/medications/presentation/today_medication_view.dart`](app/lib/features/medications/presentation/today_medication_view.dart) | تهيئة/أداة | `TodayMedicationView`, `MedicationPeriodSummary` |
| [`app/lib/features/medications/presentation/widgets/dose_actions.dart`](app/lib/features/medications/presentation/widgets/dose_actions.dart) | مكوّن واجهة | `_SkipDoseSheet`, `_SkipDoseSheetState`, `selectTakenTime`, `selectSkippedDose` |
| [`app/lib/features/medications/presentation/widgets/dose_occurrence_card.dart`](app/lib/features/medications/presentation/widgets/dose_occurrence_card.dart) | مكوّن واجهة | `DoseOccurrenceCard`, `_TimeBadge`, `_TimingState`, `_DoseDetails` |
| [`app/lib/features/medications/presentation/widgets/dose_record_controls.dart`](app/lib/features/medications/presentation/widgets/dose_record_controls.dart) | مكوّن واجهة | `DoseControlsLayout`, `DoseRecordControls`, `_RecordingStatus`, `_RecordedStatus` |
| [`app/lib/features/medications/presentation/widgets/medication_basic_fields.dart`](app/lib/features/medications/presentation/widgets/medication_basic_fields.dart) | مكوّن واجهة | `MedicationBasicFields`, `MedicationInstructionsGroup` |
| [`app/lib/features/medications/presentation/widgets/medication_details.dart`](app/lib/features/medications/presentation/widgets/medication_details.dart) | مكوّن واجهة | `MedicationDetails`, `MedicationRevisionHistory`, `_RevisionEntry`, `_ScheduleRow` |
| [`app/lib/features/medications/presentation/widgets/medication_dose_history.dart`](app/lib/features/medications/presentation/widgets/medication_dose_history.dart) | مكوّن واجهة | `MedicationDoseHistory` |
| [`app/lib/features/medications/presentation/widgets/medication_form.dart`](app/lib/features/medications/presentation/widgets/medication_form.dart) | مكوّن واجهة | `MedicationForm`, `_MedicationFormState` |
| [`app/lib/features/medications/presentation/widgets/medication_history_section.dart`](app/lib/features/medications/presentation/widgets/medication_history_section.dart) | مكوّن واجهة | `MedicationHistorySection` |
| [`app/lib/features/medications/presentation/widgets/medication_period_fields.dart`](app/lib/features/medications/presentation/widgets/medication_period_fields.dart) | مكوّن واجهة | `MedicationPeriodFields`, `MedicationEffectiveDateGroup`, `_DateRow` |
| [`app/lib/features/medications/presentation/widgets/medication_photo_field.dart`](app/lib/features/medications/presentation/widgets/medication_photo_field.dart) | مكوّن واجهة | `MedicationPhotoField`, `MedicationPhotoBuilder`, `MedicationPhotoImage`, `_PhotoBorder` |
| [`app/lib/features/medications/presentation/widgets/medication_plan_card.dart`](app/lib/features/medications/presentation/widgets/medication_plan_card.dart) | مكوّن واجهة | `MedicationPlanCard`, `_MedicationPlanCardState`, `_DetailValue`, `_ScheduleLine`, `_PlanState`, `_PlanStatus` |
| [`app/lib/features/medications/presentation/widgets/medication_plan_list.dart`](app/lib/features/medications/presentation/widgets/medication_plan_list.dart) | مكوّن واجهة | `MedicationPlanList` |
| [`app/lib/features/medications/presentation/widgets/medication_plans_section.dart`](app/lib/features/medications/presentation/widgets/medication_plans_section.dart) | مكوّن واجهة | `MedicationPlansSection` |
| [`app/lib/features/medications/presentation/widgets/medication_record_card.dart`](app/lib/features/medications/presentation/widgets/medication_record_card.dart) | مكوّن واجهة | `MedicationRecordCard` |
| [`app/lib/features/medications/presentation/widgets/medication_schedule_editor.dart`](app/lib/features/medications/presentation/widgets/medication_schedule_editor.dart) | مكوّن واجهة | `MedicationScheduleEditor` |
| [`app/lib/features/medications/presentation/widgets/medication_skeletons.dart`](app/lib/features/medications/presentation/widgets/medication_skeletons.dart) | مكوّن واجهة | `TodaySkeleton`, `DoseRowSkeleton`, `PlansSkeleton`, `PlanCardSkeleton`, `_IconLine`, `MedicationDetailsSkeleton`, `_LabelValue`, `MedicationFormSkeleton`, `DoseHistorySkeleton` |
| [`app/lib/features/medications/presentation/widgets/medication_state_view.dart`](app/lib/features/medications/presentation/widgets/medication_state_view.dart) | مكوّن واجهة | `MedicationFailureView` |
| [`app/lib/features/medications/presentation/widgets/medications_widget.dart`](app/lib/features/medications/presentation/widgets/medications_widget.dart) | مكوّن واجهة | يعيد تصدير: `medication_history_section.dart`, `medication_form.dart`, `medication_details.dart`, `medication_dose_history.dart`, `medication_plans_section.dart`, `today_medication_section.dart`, `dose_record_controls.dart` |
| [`app/lib/features/medications/presentation/widgets/today_dose_window.dart`](app/lib/features/medications/presentation/widgets/today_dose_window.dart) | مكوّن واجهة | `TodayDoseWindow` |
| [`app/lib/features/medications/presentation/widgets/today_medication_components.dart`](app/lib/features/medications/presentation/widgets/today_medication_components.dart) | مكوّن واجهة | `TodayMedicationAttentionSection`, `_TodayMedicationAttentionSectionState`, `_AttentionMedicationCard`, `TodayMedicationActionDose`, `_NextDoseInfo`, `TodayMedicationPrayerDoseRow`, `MedicationPeriodMarks`, `_PeriodMark`, `_strength` |
| [`app/lib/features/medications/presentation/widgets/today_medication_section.dart`](app/lib/features/medications/presentation/widgets/today_medication_section.dart) | مكوّن واجهة | `TodayMedicationSection` |
| [`app/lib/features/onboarding/data/datasources/onboarding_remote_data_source.dart`](app/lib/features/onboarding/data/datasources/onboarding_remote_data_source.dart) | وصول وتحويل بيانات | `BaseOnboardingRemoteDataSource`, `OnboardingRemoteDataSource` |
| [`app/lib/features/onboarding/data/models/onboarding_model.dart`](app/lib/features/onboarding/data/models/onboarding_model.dart) | وصول وتحويل بيانات | `OnboardingModel`, `OnboardingModelMapper` |
| [`app/lib/features/onboarding/data/models/onboarding_model.freezed.dart`](app/lib/features/onboarding/data/models/onboarding_model.freezed.dart) | مولّد آلي | كود مولّد؛ لا يُعدّل يدويًا |
| [`app/lib/features/onboarding/data/models/onboarding_model.g.dart`](app/lib/features/onboarding/data/models/onboarding_model.g.dart) | مولّد آلي | كود مولّد؛ لا يُعدّل يدويًا |
| [`app/lib/features/onboarding/data/repositories/onboarding_repository_data.dart`](app/lib/features/onboarding/data/repositories/onboarding_repository_data.dart) | وصول وتحويل بيانات | `OnboardingRepositoryData` |
| [`app/lib/features/onboarding/di/onboarding_di.config.dart`](app/lib/features/onboarding/di/onboarding_di.config.dart) | مولّد آلي | كود مولّد؛ لا يُعدّل يدويًا |
| [`app/lib/features/onboarding/di/onboarding_di.dart`](app/lib/features/onboarding/di/onboarding_di.dart) | حقن اعتماديات | `configureOnboarding` |
| [`app/lib/features/onboarding/domain/entities/onboarding_entity.dart`](app/lib/features/onboarding/domain/entities/onboarding_entity.dart) | كيانات وقواعد مجال | `OnboardingEntity` |
| [`app/lib/features/onboarding/domain/repositories/onboarding_repository_domain.dart`](app/lib/features/onboarding/domain/repositories/onboarding_repository_domain.dart) | كيانات وقواعد مجال | `OnboardingRepositoryDomain` |
| [`app/lib/features/onboarding/domain/use_cases/onboarding_use_case.dart`](app/lib/features/onboarding/domain/use_cases/onboarding_use_case.dart) | كيانات وقواعد مجال | `OnboardingUseCase` |
| [`app/lib/features/onboarding/presentation/cubit/onboarding_cubit.dart`](app/lib/features/onboarding/presentation/cubit/onboarding_cubit.dart) | Cubit/حالة | `OnboardingCubit` |
| [`app/lib/features/onboarding/presentation/cubit/onboarding_state.dart`](app/lib/features/onboarding/presentation/cubit/onboarding_state.dart) | Cubit/حالة | `OnboardingStatus`, `CareTarget`, `OnboardingState` |
| [`app/lib/features/onboarding/presentation/pages/onboarding_feature_screen.dart`](app/lib/features/onboarding/presentation/pages/onboarding_feature_screen.dart) | صفحة | `OnboardingFeatureScreen`, `_OnboardingFeatureScreenState` |
| [`app/lib/features/onboarding/presentation/pages/start_screen.dart`](app/lib/features/onboarding/presentation/pages/start_screen.dart) | صفحة | `StartScreen`, `_PatientQuestion` |
| [`app/lib/features/onboarding/presentation/widgets/choice_card.dart`](app/lib/features/onboarding/presentation/widgets/choice_card.dart) | مكوّن واجهة | `ChoiceCard`, `_RadioMark` |
| [`app/lib/features/onboarding/presentation/widgets/onboarding_widget.dart`](app/lib/features/onboarding/presentation/widgets/onboarding_widget.dart) | مكوّن واجهة | `OnboardingWidget` |
| [`app/lib/features/placeholder/placeholder_screen.dart`](app/lib/features/placeholder/placeholder_screen.dart) | تهيئة/أداة | `PlaceholderScreen` |
| [`app/lib/features/prayer_times/data/prayer_day_model.dart`](app/lib/features/prayer_times/data/prayer_day_model.dart) | وصول وتحويل بيانات | `PrayerDayModel` |
| [`app/lib/features/prayer_times/data/prayer_times_remote_data_source.dart`](app/lib/features/prayer_times/data/prayer_times_remote_data_source.dart) | وصول وتحويل بيانات | `PrayerTimesRemoteDataSource` |
| [`app/lib/features/prayer_times/data/prayer_times_repository.dart`](app/lib/features/prayer_times/data/prayer_times_repository.dart) | وصول وتحويل بيانات | `PrayerTimesRepository` |
| [`app/lib/features/prayer_times/domain/prayer_day.dart`](app/lib/features/prayer_times/domain/prayer_day.dart) | كيانات وقواعد مجال | `Prayer`, `PrayerDay` |
| [`app/lib/features/prayer_times/presentation/cubit/prayer_times_cubit.dart`](app/lib/features/prayer_times/presentation/cubit/prayer_times_cubit.dart) | Cubit/حالة | `PrayerTimesCubit` |
| [`app/lib/features/prayer_times/presentation/cubit/prayer_times_state.dart`](app/lib/features/prayer_times/presentation/cubit/prayer_times_state.dart) | Cubit/حالة | `PrayerTimesStatus`, `PrayerTimesState` |
| [`app/lib/features/prayer_times/presentation/widgets/prayer_times_section.dart`](app/lib/features/prayer_times/presentation/widgets/prayer_times_section.dart) | مكوّن واجهة | `PrayerTimesSection`, `_PrayerTimesSectionState`, `_Failure`, `_PrayerList`, `_PrayerRow` |
| [`app/lib/features/shell/app_shell.dart`](app/lib/features/shell/app_shell.dart) | تهيئة/أداة | `AppShell` |
| [`app/lib/features/shell/widgets/app_bottom_bar.dart`](app/lib/features/shell/widgets/app_bottom_bar.dart) | تهيئة/أداة | `AppBottomBar`, `_FrostedTabBar` |
| [`app/lib/features/shell/widgets/app_top_bar.dart`](app/lib/features/shell/widgets/app_top_bar.dart) | تهيئة/أداة | `AppTopBar`, `_ScrollEdge` |
| [`app/lib/features/shell/widgets/glass_add_button.dart`](app/lib/features/shell/widgets/glass_add_button.dart) | تهيئة/أداة | `GlassAddButton` |
| [`app/lib/main.dart`](app/lib/main.dart) | تهيئة/أداة | `MainApp`, `main` |

### Flask: الخادم (94 ملف)

| الملف | نوعه | التعريفات المباشرة داخله |
|---|---|---|
| [`backend/app/__init__.py`](backend/app/__init__.py) | خادم | `create_app`, `_refuse_in_production`, `_warn_in_staging` |
| [`backend/app/appointments/__init__.py`](backend/app/appointments/__init__.py) | خادم | وحدة: Appointment scheduling and history |
| [`backend/app/appointments/inputs.py`](backend/app/appointments/inputs.py) | خادم | `AppointmentRequest`, `AppointmentStatusRequest`, `ReviseAppointmentRequest` |
| [`backend/app/appointments/queries.py`](backend/app/appointments/queries.py) | قواعد واستعلامات خادم | `appointments_for_circle`, `appointment_view`, `companion_name`, `companion_avatar_code`, `companions_for_circle` |
| [`backend/app/appointments/routes.py`](backend/app/appointments/routes.py) | واجهة API | `_uuid`, `list_appointments`, `list_companions`, `create_appointment`, `revise_appointment`, `set_appointment_status` |
| [`backend/app/appointments/service.py`](backend/app/appointments/service.py) | قواعد واستعلامات خادم | `AppointmentService` |
| [`backend/app/appointments/visit_routes.py`](backend/app/appointments/visit_routes.py) | خادم | `VisitRequest`, `_uuid`, `get_visit`, `save_visit`, `get_visit_audio`, `save_visit_audio`, `remove_visit_audio` |
| [`backend/app/appointments/visit_service.py`](backend/app/appointments/visit_service.py) | خادم | `VisitService`, `visit_view` |
| [`backend/app/auth/__init__.py`](backend/app/auth/__init__.py) | خادم | ملف حزمة فارغ |
| [`backend/app/auth/decorators.py`](backend/app/auth/decorators.py) | خادم | `authenticate_request`, `current_auth`, `require_auth` |
| [`backend/app/auth/inputs.py`](backend/app/auth/inputs.py) | خادم | `_check_phone`, `_check_code` |
| [`backend/app/auth/otp_store.py`](backend/app/auth/otp_store.py) | خادم | `AttemptsExhausted`, `OtpRequest`, `OtpSend`, `SendClaim`, `OtpStore`, `InMemoryOtpStore` |
| [`backend/app/auth/postgres_otp.py`](backend/app/auth/postgres_otp.py) | خادم | `_key`, `_lock_phone`, `PostgresOtpStore` |
| [`backend/app/auth/postgres_sessions.py`](backend/app/auth/postgres_sessions.py) | خادم | `_record`, `PostgresSessionStore` |
| [`backend/app/auth/routes.py`](backend/app/auth/routes.py) | واجهة API | `RefreshRequest`, `RequestCodeRequest`, `VerifyCodeRequest`, `request_code`, `verify_code`, `refresh`, `sign_out`, `session_info` |
| [`backend/app/auth/service.py`](backend/app/auth/service.py) | قواعد واستعلامات خادم | `IssuedAccessToken`, `IssuedSession`, `SessionService` |
| [`backend/app/auth/sign_in.py`](backend/app/auth/sign_in.py) | خادم | `SignInResult`, `SignInService` |
| [`backend/app/auth/store.py`](backend/app/auth/store.py) | خادم | `SessionRecord`, `SessionStore`, `InMemorySessionStore` |
| [`backend/app/auth/tokens.py`](backend/app/auth/tokens.py) | خادم | `AccessClaims`, `encode_access_token`, `decode_access_token`, `new_refresh_token`, `hash_refresh_token` |
| [`backend/app/authz/__init__.py`](backend/app/authz/__init__.py) | خادم | يعيد تصدير تعريفات الحزمة |
| [`backend/app/authz/circle_access.py`](backend/app/authz/circle_access.py) | خادم | `CircleAccess`, `DenyAllCircleAccess`, `InMemoryCircleAccess` |
| [`backend/app/authz/decorators.py`](backend/app/authz/decorators.py) | خادم | `current_circle_role`, `require_circle_role` |
| [`backend/app/authz/postgres.py`](backend/app/authz/postgres.py) | خادم | `PostgresCircleAccess` |
| [`backend/app/authz/roles.py`](backend/app/authz/roles.py) | خادم | `CircleRole` |
| [`backend/app/care.py`](backend/app/care.py) | خادم | `CareService` |
| [`backend/app/circles/__init__.py`](backend/app/circles/__init__.py) | خادم | وحدة: Endpoints for care circles, creation requests, invitations and the
medical file |
| [`backend/app/circles/creation_requests.py`](backend/app/circles/creation_requests.py) | خادم | `send_request`, `list_requests`, `respond`, `complete`, `cancel` |
| [`backend/app/circles/inputs.py`](backend/app/circles/inputs.py) | خادم | `_one_line`, `_text`, `_iso_date_only`, `ConditionsInput`, `AllergiesInput`, `MedicalProfileInput`, `EmergencyContactInput`, `_Point`, `_Place`, `_PatientBasics`, `_OwnBasics`, `CreateSelfCircleInput`, `CreateOfflineCircleInput`, `CompleteRequestInput`, `PatientUpdateInput`, `RenameCircleInput`, `LeaveCircleInput`, `CreationRequestInput`, `InviteInput`, `RespondInput`, `DeleteAccountInput` |
| [`backend/app/circles/invitations.py`](backend/app/circles/invitations.py) | خادم | `list_invitations`, `respond` |
| [`backend/app/circles/naming.py`](backend/app/circles/naming.py) | خادم | `shared_name`, `account_name`, `name_for`, `circle_name` |
| [`backend/app/circles/routes.py`](backend/app/circles/routes.py) | واجهة API | `create_self_circle`, `create_offline_circle`, `get_circle`, `rename_circle`, `update_patient`, `leave_circle`, `delete_circle`, `invite_manager`, `resend_invitation`, `cancel_invitation`, `get_medical_profile`, `get_emergency_card`, `update_medical_profile`, `add_emergency_contact`, `update_emergency_contact`, `delete_emergency_contact` |
| [`backend/app/circles/support.py`](backend/app/circles/support.py) | خادم | `Work`, `care_work`, `answer`, `save_medical`, `parse_id` |
| [`backend/app/circles/views.py`](backend/app/circles/views.py) | واجهة API | `_time`, `patient_view`, `circle_view`, `invitation_view`, `contact_view`, `medical_view`, `emergency_card_view`, `sent_request_view`, `received_request_view`, `creation_requests_view`, `received_invitations_view` |
| [`backend/app/clock.py`](backend/app/clock.py) | خادم | `SystemClock`, `ManualClock` |
| [`backend/app/config.py`](backend/app/config.py) | خادم | `ConfigError`, `_int_from_env`, `load_config` |
| [`backend/app/cors.py`](backend/app/cors.py) | خادم | `register_development_cors` |
| [`backend/app/database.py`](backend/app/database.py) | خادم | `Base`, `transaction`, `initialize_database` |
| [`backend/app/demo_data.py`](backend/app/demo_data.py) | خادم | `Summary`, `_schedule`, `_plan`, `DemoBuilder`, `remove_demo_accounts`, `demo_data_command` |
| [`backend/app/errors.py`](backend/app/errors.py) | خادم | `ApiError`, `BadRequest`, `Unauthorized`, `Forbidden`, `NotFound`, `ValidationFailed`, `Conflict`, `TooManyRequests`, `ServiceUnavailable`, `error_response`, `_handle_database_conflict`, `_handle_database_failure`, `_handle_api_error`, `_handle_http_exception`, `_handle_unexpected_error`, `register_error_handlers` |
| [`backend/app/extensions.py`](backend/app/extensions.py) | خادم | `get_clock`, `get_sms_sender`, `get_session_service`, `get_circle_access`, `get_sign_in_service`, `get_user_store`, `get_push_sender` |
| [`backend/app/health.py`](backend/app/health.py) | خادم | `expected_revision`, `_database_revision`, `health` |
| [`backend/app/home.py`](backend/app/home.py) | خادم | `home`, `_circles` |
| [`backend/app/measurements/__init__.py`](backend/app/measurements/__init__.py) | خادم | وحدة: Measurement plan and reading operations |
| [`backend/app/measurements/inputs.py`](backend/app/measurements/inputs.py) | خادم | `PlanRequest`, `RevisePlanRequest`, `ReadingRequest`, `ReadingQuery` |
| [`backend/app/measurements/queries.py`](backend/app/measurements/queries.py) | قواعد واستعلامات خادم | `version_response`, `reading_response`, `MeasurementQueries` |
| [`backend/app/measurements/routes.py`](backend/app/measurements/routes.py) | واجهة API | `_uuid`, `_date`, `_range`, `list_plans`, `list_targets`, `create_plan`, `revise_plan`, `stop_plan`, `list_occurrences`, `list_readings`, `export_readings`, `create_standalone_reading`, `record_task`, `follow_up` |
| [`backend/app/measurements/service.py`](backend/app/measurements/service.py) | قواعد واستعلامات خادم | `patient_for_circle`, `weekday_mask`, `outside_target`, `MeasurementService` |
| [`backend/app/medical.py`](backend/app/medical.py) | خادم | `_Unset`, `Conditions`, `Allergies`, `MedicalUpdate`, `MedicalProfile`, `_invalid`, `_ordered`, `_check_codes`, `_check_other`, `MedicalService` |
| [`backend/app/medications/__init__.py`](backend/app/medications/__init__.py) | خادم | وحدة: Medication-plan and dose-tracking HTTP feature |
| [`backend/app/medications/availability.py`](backend/app/medications/availability.py) | خادم | `require_available_name` |
| [`backend/app/medications/doses.py`](backend/app/medications/doses.py) | خادم | `MedicationDoseService` |
| [`backend/app/medications/inputs.py`](backend/app/medications/inputs.py) | خادم | `_english_decimal`, `ScheduleRequest`, `PlanRequest`, `RevisePlanRequest`, `CancelPendingRequest`, `DoseRecordRequest`, `OccurrenceQuery` |
| [`backend/app/medications/occurrence_builder.py`](backend/app/medications/occurrence_builder.py) | خادم | `build_occurrences`, `_version_applies`, `_timing_state` |
| [`backend/app/medications/plan_versions.py`](backend/app/medications/plan_versions.py) | خادم | `add_plan_version`, `same_definition` |
| [`backend/app/medications/plans.py`](backend/app/medications/plans.py) | قواعد واستعلامات خادم | `normalize_medication_name`, `MedicationPlanService` |
| [`backend/app/medications/queries.py`](backend/app/medications/queries.py) | قواعد واستعلامات خادم | `MedicationQueries` |
| [`backend/app/medications/representations.py`](backend/app/medications/representations.py) | خادم | `plain_number`, `schedule_responses`, `plan_response`, `occurrence_response` |
| [`backend/app/medications/route_helpers.py`](backend/app/medications/route_helpers.py) | خادم | `uuid_value`, `occurrence_query`, `dose_record_response` |
| [`backend/app/medications/routes.py`](backend/app/medications/routes.py) | واجهة API | `list_plans`, `create_plan`, `get_plan`, `revise_plan`, `discontinue_plan`, `cancel_pending_plan`, `list_occurrences`, `record_dose` |
| [`backend/app/models/__init__.py`](backend/app/models/__init__.py) | نموذج قاعدة بيانات | وحدة: Persistence models registered with SQLAlchemy metadata |
| [`backend/app/models/account.py`](backend/app/models/account.py) | نموذج قاعدة بيانات | `Account` |
| [`backend/app/models/appointment.py`](backend/app/models/appointment.py) | نموذج قاعدة بيانات | `Appointment`, `AppointmentVisit` |
| [`backend/app/models/auth.py`](backend/app/models/auth.py) | نموذج قاعدة بيانات | `AccountSession`, `OtpChallenge`, `OtpSendAttempt` |
| [`backend/app/models/circle.py`](backend/app/models/circle.py) | نموذج قاعدة بيانات | `CareCircle` |
| [`backend/app/models/creation_request.py`](backend/app/models/creation_request.py) | نموذج قاعدة بيانات | `CareCircleCreationRequest` |
| [`backend/app/models/invitation.py`](backend/app/models/invitation.py) | نموذج قاعدة بيانات | `CareCircleManagerInvitation` |
| [`backend/app/models/manager.py`](backend/app/models/manager.py) | نموذج قاعدة بيانات | `CareCircleManager` |
| [`backend/app/models/measurement.py`](backend/app/models/measurement.py) | نموذج قاعدة بيانات | `MeasurementPlan`, `MeasurementTarget`, `MeasurementPlanVersion`, `MeasurementRecord` |
| [`backend/app/models/medical.py`](backend/app/models/medical.py) | نموذج قاعدة بيانات | `PatientCondition`, `PatientAllergy`, `EmergencyContact` |
| [`backend/app/models/medication_dose_record.py`](backend/app/models/medication_dose_record.py) | نموذج قاعدة بيانات | `MedicationDoseRecord` |
| [`backend/app/models/medication_plan.py`](backend/app/models/medication_plan.py) | نموذج قاعدة بيانات | `MedicationPlan`, `MedicationPlanVersion` |
| [`backend/app/models/medication_schedule.py`](backend/app/models/medication_schedule.py) | نموذج قاعدة بيانات | `MedicationSchedule`, `MedicationScheduleDay` |
| [`backend/app/models/patient.py`](backend/app/models/patient.py) | نموذج قاعدة بيانات | `Patient` |
| [`backend/app/models/photo.py`](backend/app/models/photo.py) | نموذج قاعدة بيانات | `Photo` |
| [`backend/app/models/push.py`](backend/app/models/push.py) | نموذج قاعدة بيانات | `PushDevice` |
| [`backend/app/photo_routes.py`](backend/app/photo_routes.py) | خادم | `AvatarRequest`, `_uuid`, `_png`, `_image`, `_account`, `_patient`, `_patient_write`, `my_photo`, `save_my_photo`, `save_my_avatar`, `clear_my_avatar`, `member_photo`, `patient_photo`, `save_patient_photo`, `save_patient_avatar`, `clear_patient_avatar`, `_plan`, `medication_photo`, `save_medication_photo`, `remove_medication_photo` |
| [`backend/app/photos.py`](backend/app/photos.py) | خادم | `valid_photo`, `PhotoService` |
| [`backend/app/prayer_times/__init__.py`](backend/app/prayer_times/__init__.py) | خادم | وحدة: Prayer times for the city selected in a care circle |
| [`backend/app/prayer_times/routes.py`](backend/app/prayer_times/routes.py) | واجهة API | `prayer_times` |
| [`backend/app/prayer_times/service.py`](backend/app/prayer_times/service.py) | قواعد واستعلامات خادم | `prayer_times_for`, `_fetch_day` |
| [`backend/app/push/__init__.py`](backend/app/push/__init__.py) | خادم | `create_push_sender` |
| [`backend/app/push/messages.py`](backend/app/push/messages.py) | خادم | `_account_with_phone`, `_display_name`, `invitation_push`, `circle_request_push`, `request_answer_push`, `circle_ready_push` |
| [`backend/app/push/notify.py`](backend/app/push/notify.py) | خادم | `Push`, `notify`, `_send` |
| [`backend/app/push/routes.py`](backend/app/push/routes.py) | واجهة API | `PushDeviceInput`, `register_push_device` |
| [`backend/app/push/sender.py`](backend/app/push/sender.py) | خادم | `PushMessage`, `PushSender`, `NoPushSender`, `RecordingPushSender`, `ApnsPushSender` |
| [`backend/app/request_context.py`](backend/app/request_context.py) | خادم | `register_request_id` |
| [`backend/app/sms/__init__.py`](backend/app/sms/__init__.py) | خادم | `create_sms_sender` |
| [`backend/app/sms/authentica.py`](backend/app/sms/authentica.py) | خادم | `_NoRedirect`, `_parse_json`, `urllib_post`, `_field`, `AuthenticaSmsSender` |
| [`backend/app/sms/base.py`](backend/app/sms/base.py) | خادم | `SmsDeliveryError`, `SmsSender` |
| [`backend/app/sms/fake.py`](backend/app/sms/fake.py) | خادم | `SentSms`, `FakeSmsSender` |
| [`backend/app/users/__init__.py`](backend/app/users/__init__.py) | خادم | ملف حزمة فارغ |
| [`backend/app/users/postgres.py`](backend/app/users/postgres.py) | خادم | `as_user`, `PostgresUserStore` |
| [`backend/app/users/routes.py`](backend/app/users/routes.py) | واجهة API | `_one_line`, `_name`, `ProfileRequest`, `save_profile`, `read_account`, `_patient_circle_id`, `delete_account` |
| [`backend/app/users/store.py`](backend/app/users/store.py) | خادم | `User`, `UserStore`, `InMemoryUserStore` |
| [`backend/app/validation.py`](backend/app/validation.py) | خادم | `Dto`, `parse_json_body`, `parse_optional_json_body` |

### قاعدة البيانات: المهاجرات (17 ملف)

| الملف | نوعه | التعريفات المباشرة داخله |
|---|---|---|
| [`backend/migrations/versions/0001_create_six_core_care_entities.py`](backend/migrations/versions/0001_create_six_core_care_entities.py) | مهاجرة قاعدة بيانات | `upgrade`, `downgrade` |
| [`backend/migrations/versions/0002_require_accepted_consent.py`](backend/migrations/versions/0002_require_accepted_consent.py) | مهاجرة قاعدة بيانات | `upgrade`, `downgrade` |
| [`backend/migrations/versions/0003_serialize_patient_profile.py`](backend/migrations/versions/0003_serialize_patient_profile.py) | مهاجرة قاعدة بيانات | `upgrade`, `downgrade` |
| [`backend/migrations/versions/0004_persist_authentication.py`](backend/migrations/versions/0004_persist_authentication.py) | مهاجرة قاعدة بيانات | `_sessions`, `_challenges`, `_sends`, `upgrade`, `downgrade` |
| [`backend/migrations/versions/0005_add_medical_profile.py`](backend/migrations/versions/0005_add_medical_profile.py) | مهاجرة قاعدة بيانات | `_patient_id`, `_id`, `upgrade`, `downgrade` |
| [`backend/migrations/versions/0006_add_medications.py`](backend/migrations/versions/0006_add_medications.py) | مهاجرة قاعدة بيانات | `_create_plan_tables`, `_create_schedule_tables`, `_create_dose_records`, `upgrade`, `downgrade` |
| [`backend/migrations/versions/0007_refine_medications.py`](backend/migrations/versions/0007_refine_medications.py) | مهاجرة قاعدة بيانات | `_drop_rules`, `_add_structured_strength`, `_replace_revision_period`, `_remove_duplicated_plan_name`, `_constrain_skip_reasons`, `upgrade`, `downgrade` |
| [`backend/migrations/versions/0008_medication_timing_and_pending.py`](backend/migrations/versions/0008_medication_timing_and_pending.py) | مهاجرة قاعدة بيانات | `_rule`, `upgrade`, `downgrade` |
| [`backend/migrations/versions/0009_account_birth_date_city.py`](backend/migrations/versions/0009_account_birth_date_city.py) | مهاجرة قاعدة بيانات | `upgrade`, `downgrade` |
| [`backend/migrations/versions/0010_add_measurements.py`](backend/migrations/versions/0010_add_measurements.py) | مهاجرة قاعدة بيانات | `upgrade`, `downgrade` |
| [`backend/migrations/versions/0011_add_appointments.py`](backend/migrations/versions/0011_add_appointments.py) | مهاجرة قاعدة بيانات | `upgrade`, `downgrade` |
| [`backend/migrations/versions/0012_add_appointment_visits.py`](backend/migrations/versions/0012_add_appointment_visits.py) | مهاجرة قاعدة بيانات | `upgrade`, `downgrade` |
| [`backend/migrations/versions/0013_custom_appointment_type.py`](backend/migrations/versions/0013_custom_appointment_type.py) | مهاجرة قاعدة بيانات | `upgrade`, `downgrade` |
| [`backend/migrations/versions/0014_free_measurement_targets.py`](backend/migrations/versions/0014_free_measurement_targets.py) | مهاجرة قاعدة بيانات | `upgrade`, `downgrade` |
| [`backend/migrations/versions/0015_measurement_target_and_unique_plan.py`](backend/migrations/versions/0015_measurement_target_and_unique_plan.py) | مهاجرة قاعدة بيانات | `upgrade`, `downgrade` |
| [`backend/migrations/versions/0016_private_photos_and_avatars.py`](backend/migrations/versions/0016_private_photos_and_avatars.py) | مهاجرة قاعدة بيانات | `upgrade`, `downgrade` |
| [`backend/migrations/versions/0017_push_devices.py`](backend/migrations/versions/0017_push_devices.py) | مهاجرة قاعدة بيانات | `upgrade`, `downgrade` |

### اختبارات Flutter (42 ملف)

| الملف | نوعه | التعريفات المباشرة داخله |
|---|---|---|
| [`app/test/account_cubit_test.dart`](app/test/account_cubit_test.dart) | اختبار | `_Auth`, `_Onboarding`, `main` |
| [`app/test/app_shell_test.dart`](app/test/app_shell_test.dart) | اختبار | `_FileAssetLoader`, `_SignedInTokens`, `_OfflineAuthRepository`, `_EmptyMedicationsRepository`, `_EmptyMeasurementsRepository`, `_EmptyAppointmentsRepository`, `_OfflinePrayerTimes`, `_OfflineOnboardingRepository`, `pumpApp`, `tapInSheet`, `chooseCircle`, `openAddCircle`, `main` |
| [`app/test/auth_session_test.dart`](app/test/auth_session_test.dart) | اختبار | `_Tokens`, `_Remote`, `main` |
| [`app/test/birth_date_rules_test.dart`](app/test/birth_date_rules_test.dart) | اختبار | `main` |
| [`app/test/circle_overview_model_test.dart`](app/test/circle_overview_model_test.dart) | اختبار | `_circle`, `main` |
| [`app/test/circles_data_test.dart`](app/test/circles_data_test.dart) | اختبار | `_Remote`, `_requestAnswer`, `main` |
| [`app/test/circles_remote_test.dart`](app/test/circles_remote_test.dart) | اختبار | `_Call`, `_FakeClient`, `_contact`, `_medicalFile`, `_request`, `main` |
| [`app/test/create_circle_cubit_test.dart`](app/test/create_circle_cubit_test.dart) | اختبار | `main` |
| [`app/test/design_system_boundaries_test.dart`](app/test/design_system_boundaries_test.dart) | اختبار | `main` |
| [`app/test/design_system_theme_test.dart`](app/test/design_system_theme_test.dart) | اختبار | `contrast`, `main` |
| [`app/test/design_system_visual_regression_test.dart`](app/test/design_system_visual_regression_test.dart) | اختبار | `_Showcase`, `main` |
| [`app/test/dose_reminders_test.dart`](app/test/dose_reminders_test.dart) | اختبار | `_Medications`, `main` |
| [`app/test/emergency_card_cubit_test.dart`](app/test/emergency_card_cubit_test.dart) | اختبار | `main` |
| [`app/test/glass_accessibility_test.dart`](app/test/glass_accessibility_test.dart) | اختبار | `main` |
| [`app/test/home_cubit_test.dart`](app/test/home_cubit_test.dart) | اختبار | `main` |
| [`app/test/home_repository_test.dart`](app/test/home_repository_test.dart) | اختبار | `_Storage`, `_Remote`, `main` |
| [`app/test/inbox_cubit_test.dart`](app/test/inbox_cubit_test.dart) | اختبار | `main` |
| [`app/test/input_behavior_test.dart`](app/test/input_behavior_test.dart) | اختبار | `main` |
| [`app/test/intro_memory_test.dart`](app/test/intro_memory_test.dart) | اختبار | `main` |
| [`app/test/measurement_cubits_test.dart`](app/test/measurement_cubits_test.dart) | اختبار | `_Repository`, `main` |
| [`app/test/measurement_models_test.dart`](app/test/measurement_models_test.dart) | اختبار | `main` |
| [`app/test/medical_data_test.dart`](app/test/medical_data_test.dart) | اختبار | `_Remote`, `main` |
| [`app/test/medical_file_cubit_test.dart`](app/test/medical_file_cubit_test.dart) | اختبار | `main` |
| [`app/test/medical_file_edit_cubit_test.dart`](app/test/medical_file_edit_cubit_test.dart) | اختبار | `main` |
| [`app/test/medical_file_saves_test.dart`](app/test/medical_file_saves_test.dart) | اختبار | `main` |
| [`app/test/medical_form_test.dart`](app/test/medical_form_test.dart) | اختبار | `main` |
| [`app/test/medication_models_test.dart`](app/test/medication_models_test.dart) | اختبار | `main` |
| [`app/test/medication_occurrences_cubit_test.dart`](app/test/medication_occurrences_cubit_test.dart) | اختبار | `_Repository`, `main` |
| [`app/test/medication_schedule_editor_test.dart`](app/test/medication_schedule_editor_test.dart) | اختبار | `_Translations`, `main` |
| [`app/test/medications_cubit_test.dart`](app/test/medications_cubit_test.dart) | اختبار | `_PlansRepository`, `main` |
| [`app/test/network_exceptions_test.dart`](app/test/network_exceptions_test.dart) | اختبار | `_body`, `main` |
| [`app/test/onboarding_cubit_test.dart`](app/test/onboarding_cubit_test.dart) | اختبار | `_Onboarding`, `main` |
| [`app/test/push_registration_test.dart`](app/test/push_registration_test.dart) | اختبار | `main` |
| [`app/test/request_reply_cubit_test.dart`](app/test/request_reply_cubit_test.dart) | اختبار | `main` |
| [`app/test/route_guard_test.dart`](app/test/route_guard_test.dart) | اختبار | `main` |
| [`app/test/saudi_cities_test.dart`](app/test/saudi_cities_test.dart) | اختبار | `main` |
| [`app/test/send_circle_request_cubit_test.dart`](app/test/send_circle_request_cubit_test.dart) | اختبار | `main` |
| [`app/test/support/circles_fakes.dart`](app/test/support/circles_fakes.dart) | اختبار | `CirclesFakeRepository` |
| [`app/test/support/home_fakes.dart`](app/test/support/home_fakes.dart) | اختبار | `HomeFakeRepository` |
| [`app/test/support/phone_fakes.dart`](app/test/support/phone_fakes.dart) | اختبار | `FakePhoneNotifications` |
| [`app/test/token_auth_test.dart`](app/test/token_auth_test.dart) | اختبار | `_FakeTokenStorage`, `_Seen`, `_FakeServer`, `_Client`, `main` |
| [`app/test/verify_code_response_test.dart`](app/test/verify_code_response_test.dart) | اختبار | `main` |

### اختبارات الخادم (23 ملف)

| الملف | نوعه | التعريفات المباشرة داخله |
|---|---|---|
| [`backend/tests/__init__.py`](backend/tests/__init__.py) | اختبار | ملف حزمة فارغ |
| [`backend/tests/config.py`](backend/tests/config.py) | اختبار | `ConfigError`, `_int_from_env`, `load_config` |
| [`backend/tests/conftest.py`](backend/tests/conftest.py) | اختبار | `isolate_database_environment`, `isolate_sms_environment`, `block_network`, `clock`, `circle_access`, `otp_store`, `user_store`, `app`, `client`, `sms`, `sessions`, `signed_in_account`, `signed_in`, `bearer` |
| [`backend/tests/test_authentica.py`](backend/tests/test_authentica.py) | اختبار | `FakeTransport`, `make_sender`, `test_send_code_asks_for_template_5_by_sms_and_sends_no_code_of_its_own`, `test_the_template_can_be_changed`, `test_send_code_raises_when_authentica_does_not_confirm`, `test_a_wrong_key_says_where_to_look`, `test_check_code_sends_the_phone_and_the_code_to_verify_otp`, `test_a_refused_code_is_false_whatever_the_reason`, `test_a_refusal_is_decided_by_the_status_even_if_the_body_cannot_be_read`, `test_status_false_with_http_200_is_a_refusal_too`, `test_an_answer_we_do_not_know_never_grants_access`, `test_a_failure_of_the_provider_is_an_error_and_not_a_wrong_code`, `test_no_answer_is_an_error_that_does_not_repeat_the_text_of_the_failure`, `test_nothing_secret_is_logged`, `test_an_empty_key_is_refused`, `test_the_address_must_be_https_so_the_key_never_travels_in_clear`, `test_a_slash_at_the_end_of_the_address_is_harmless`, `FakeResponse`, `test_the_default_function_sends_json_with_the_key_in_the_header`, `test_the_default_function_returns_a_422_answer_instead_of_raising`, `test_the_default_function_copes_with_an_answer_that_is_not_json`, `test_a_redirect_is_never_followed_because_the_key_would_follow_it` |
| [`backend/tests/test_authorization.py`](backend/tests/test_authorization.py) | اختبار | `circle_app`, `circle_client`, `test_member_with_an_allowed_role_gets_in`, `test_member_with_a_role_that_is_not_allowed_is_refused`, `test_role_in_one_circle_gives_nothing_in_another`, `test_a_different_role_in_each_circle_is_respected`, `test_non_member_and_unknown_circle_get_the_same_answer`, `test_no_roles_listed_accepts_any_member`, `test_not_signed_in_is_401_not_403`, `test_signed_out_user_is_refused_even_if_still_a_member`, `test_default_circle_access_refuses_everyone` |
| [`backend/tests/test_circle_inputs.py`](backend/tests/test_circle_inputs.py) | اختبار | `error_of`, `test_every_endpoint_needs_a_sign_in`, `test_a_circle_you_are_not_in_is_refused`, `test_a_simplified_patient_cannot_manage_the_circle`, `test_the_account_page_reads_the_signed_in_account`, `test_a_bad_body_is_refused_before_any_work`, `test_a_valid_body_needs_the_database`, `test_leaving_needs_no_body`, `test_leaving_checks_a_body_when_one_is_sent`, `test_a_bad_creation_request_is_refused`, `test_responding_needs_a_real_yes_or_no`, `test_an_emergency_contact_needs_a_saudi_mobile_number` |
| [`backend/tests/test_config.py`](backend/tests/test_config.py) | اختبار | `test_default_token_lifetimes_are_the_proposal_of_tfqd_11`, `test_token_lifetimes_can_be_changed_by_environment_variable`, `test_bad_token_lifetime_is_refused`, `test_unknown_environment_is_refused`, `test_app_environment_comes_from_app_env_by_default`, `test_staging_and_production_need_a_real_secret_key`, `test_a_short_secret_key_is_refused`, `test_development_works_without_any_setup`, `test_production_refuses_the_in_memory_session_store`, `test_staging_starts_with_a_warning_about_the_in_memory_store`, `test_a_given_session_store_is_used_without_warning`, `test_default_code_validity_is_300_seconds_like_the_authentica_dashboard`, `test_code_validity_can_be_changed_by_environment_variable`, `test_bad_otp_numbers_are_refused`, `test_default_authentica_template_is_5`, `test_authentica_template_can_be_changed_by_environment_variable`, `test_the_authentica_key_is_read_from_the_environment_outside_tests`, `test_the_testing_environment_never_reads_the_authentica_key`, `test_default_sign_in_limits_are_the_ones_of_tfqd_13`, `test_sign_in_limits_can_be_changed_by_environment_variable`, `test_bad_sign_in_limits_are_refused`, `test_production_refuses_the_in_memory_code_and_user_stores`, `test_staging_warns_about_every_in_memory_store` |
| [`backend/tests/test_cors.py`](backend/tests/test_cors.py) | اختبار | `preflight`, `dev_client`, `test_the_browser_check_before_a_call_is_answered`, `test_the_browser_may_use_every_method_the_api_has`, `test_addresses_of_this_computer_are_allowed`, `test_error_answers_carry_the_headers_too`, `test_the_page_can_read_the_retry_after_and_request_id_headers`, `test_other_websites_are_not_allowed`, `test_a_call_without_an_origin_gets_no_cors_headers`, `test_no_other_environment_sends_the_headers` |
| [`backend/tests/test_database_config.py`](backend/tests/test_database_config.py) | اختبار | `test_testing_does_not_inherit_database_credentials`, `test_plain_postgres_urls_select_psycopg3`, `test_other_database_backends_are_rejected`, `test_invalid_url_does_not_echo_secrets` |
| [`backend/tests/test_errors.py`](backend/tests/test_errors.py) | اختبار | `assert_error_shape`, `test_unknown_url_uses_the_error_format`, `test_wrong_method_uses_the_error_format_and_lists_allowed_methods`, `test_api_error_uses_the_error_format`, `test_unexpected_exception_returns_500_without_leaking_details`, `test_401_carries_the_www_authenticate_header`, `test_every_response_has_a_request_id`, `test_a_safe_client_request_id_is_kept`, `test_an_unsafe_client_request_id_is_replaced`, `test_retry_after_is_in_the_body_and_in_the_header`, `test_an_error_without_retry_after_has_no_such_field_or_header`, `test_service_unavailable_is_a_503` |
| [`backend/tests/test_health.py`](backend/tests/test_health.py) | اختبار | `test_health_endpoint_responds`, `test_health_needs_no_sign_in`, `test_no_static_route_is_exposed` |
| [`backend/tests/test_measurement_inputs.py`](backend/tests/test_measurement_inputs.py) | اختبار | `test_plan_requires_user_target_and_unique_days`, `test_reading_shape_and_blood_pressure_order` |
| [`backend/tests/test_medication_inputs.py`](backend/tests/test_medication_inputs.py) | اختبار | `schedule`, `plan`, `test_name_normalization_preserves_a_single_comparison_key`, `test_plan_rejects_a_unit_that_does_not_match_its_form`, `test_plan_rejects_duplicate_time_on_the_same_weekday`, `test_plan_rejects_localized_or_ambiguous_decimal_text`, `test_injection_accepts_volume_or_units`, `test_occurrence_query_accepts_at_most_thirty_two_days`, `test_taken_dose_requires_time_and_rejects_skip_details`, `test_skipped_dose_does_not_accept_a_taken_time`, `test_skip_note_requires_the_other_reason`, `test_missed_threshold_accepts_only_the_three_visible_choices`, `test_dose_status_changes_at_due_and_missed_boundaries` |
| [`backend/tests/test_medication_numbers.py`](backend/tests/test_medication_numbers.py) | اختبار | `test_plain_number_has_no_exponent` |
| [`backend/tests/test_otp_store.py`](backend/tests/test_otp_store.py) | اختبار | `store`, `claim`, `test_resend_rechecks_attempt_limit_inside_reservation`, `test_claim_without_a_request_id_creates_a_request`, `test_claim_with_a_request_id_uses_that_request`, `test_claim_with_an_unknown_request_id_is_an_error`, `test_get_request_of_an_unknown_id_is_none`, `test_claim_is_refused_after_the_maximum_and_says_when_to_come_back`, `test_the_limit_is_per_phone_number`, `test_the_window_slides`, `test_a_send_exactly_on_the_window_start_is_outside_the_window`, `test_sends_of_the_same_request_all_count`, `test_releasing_a_send_gives_the_place_back`, `test_releasing_the_only_send_retains_failed_delivery_history`, `test_releasing_one_send_keeps_a_request_that_has_another`, `test_releasing_an_unknown_send_does_nothing`, `test_latest_send_at_is_the_time_of_the_last_send_of_the_request`, `test_latest_send_at_ignores_the_sends_of_other_requests`, `test_latest_send_at_of_an_unknown_request_is_none`, `test_tries_are_counted_up_to_the_maximum`, `test_claim_try_of_an_unknown_request_is_false`, `test_release_try_gives_a_try_back`, `test_release_try_never_goes_below_zero`, `test_tries_of_one_request_do_not_touch_another`, `test_a_request_is_closed_once`, `test_marking_an_unknown_request_verified_is_false`, `run_in_threads`, `test_twenty_claims_at_once_get_exactly_three_places`, `test_twenty_tries_at_once_get_exactly_three_places` |
| [`backend/tests/test_prayer_times.py`](backend/tests/test_prayer_times.py) | اختبار | `_payload`, `test_selected_city_and_date_are_sent_once`, `test_invalid_provider_method_is_not_cached`, `test_unsupported_city_never_contacts_provider`, `test_wrong_timezone_is_not_cached` |
| [`backend/tests/test_profile.py`](backend/tests/test_profile.py) | اختبار | `sign_in`, `save`, `error_of`, `test_the_profile_needs_a_signed_in_user`, `test_saving_the_profile_returns_the_user_with_a_complete_profile`, `test_the_profile_is_kept_in_the_user_store`, `test_arabic_names_are_accepted`, `test_spaces_around_the_names_are_removed`, `test_saving_again_replaces_the_names`, `test_each_user_has_their_own_profile`, `test_the_names_cannot_choose_a_different_user`, `test_every_name_is_required`, `test_a_name_cannot_be_empty_or_only_spaces`, `test_names_have_a_maximum_length`, `test_a_name_is_one_line_without_control_characters`, `test_unknown_fields_are_refused`, `test_a_signed_out_session_cannot_save_the_profile`, `test_a_token_of_a_user_that_does_not_exist_gets_a_clear_answer`, `test_onboarding_sends_the_birth_date_and_city`, `test_the_names_alone_keep_the_saved_birth_date_and_city`, `test_a_wrong_birth_date_or_city_is_refused` |
| [`backend/tests/test_push.py`](backend/tests/test_push.py) | اختبار | `key`, `pem`, `apns`, `test_nothing_is_sent_unless_set_up`, `test_tests_never_use_apple`, `test_an_unknown_backend_stops_the_app`, `test_apple_needs_every_setting`, `test_apple_with_its_key`, `test_the_request_apple_expects`, `test_production_goes_to_apples_main_server`, `test_the_provider_token_is_reused`, `test_apples_answers`, `test_apple_out_of_reach`, `test_registering_needs_a_sign_in`, `test_a_token_that_is_not_apples_is_refused`, `test_without_a_database_the_token_cannot_be_kept`, `test_the_app_can_be_given_a_sender` |
| [`backend/tests/test_sessions.py`](backend/tests/test_sessions.py) | اختبار | `error_code`, `test_valid_access_token_reaches_a_protected_endpoint`, `test_missing_header_is_rejected`, `test_wrong_scheme_is_rejected`, `test_garbage_token_is_rejected`, `test_token_signed_with_another_key_is_rejected`, `test_token_with_algorithm_none_is_rejected`, `test_tampered_token_is_rejected`, `test_refresh_token_cannot_be_used_as_an_access_token`, `test_access_token_lives_15_minutes`, `test_expired_access_token_can_be_replaced_with_a_refresh`, `test_refresh_response_has_the_new_expiry_time`, `test_unknown_refresh_token_is_rejected`, `test_refresh_token_lives_30_days`, `test_sign_out_returns_204`, `test_sign_out_needs_a_valid_access_token`, `test_refresh_token_of_a_revoked_session_is_rejected`, `test_access_token_of_a_revoked_session_is_rejected_at_once`, `test_access_token_issued_by_a_refresh_dies_with_the_session`, `test_signing_out_twice_does_not_break_anything`, `test_sign_out_ends_only_that_session`, `test_the_store_keeps_only_a_hash_of_the_refresh_token`, `test_no_device_or_ip_is_stored_with_a_session` |
| [`backend/tests/test_sign_in.py`](backend/tests/test_sign_in.py) | اختبار | `request_code`, `verify_code`, `start`, `last_code`, `wrong_code_for`, `error_of`, `arabic_indic`, `provider_calls`, `provider_is_down`, `test_request_code_sends_one_sms_and_returns_a_verification_id`, `test_request_code_without_a_verification_id_starts_a_new_request_each_time`, `test_a_resend_keeps_the_same_request_and_sends_another_sms`, `test_the_answer_is_the_same_for_a_new_and_a_known_phone_number`, `test_a_bad_phone_number_is_refused_and_nothing_is_sent`, `test_a_bad_phone_number_is_never_repeated_in_the_answer`, `test_a_phone_number_with_spaces_around_it_is_accepted`, `test_request_code_needs_a_phone_number`, `test_request_code_refuses_unknown_fields`, `test_request_code_needs_a_json_body`, `test_the_fourth_code_in_an_hour_is_refused_and_nothing_is_sent`, `test_resends_count_toward_the_same_limit`, `test_the_limit_belongs_to_the_phone_number`, `test_the_window_slides_and_the_answer_says_when_to_come_back`, `test_a_refused_request_is_not_counted_again`, `test_an_unknown_verification_id_is_refused`, `test_a_verification_id_of_another_phone_number_is_refused`, `test_a_finished_verification_id_cannot_be_used_for_a_resend`, `test_no_sms_is_sent_into_a_request_that_has_no_tries_left`, `test_a_provider_failure_gives_503`, `test_a_rejected_send_does_not_count_toward_the_hourly_limit`, `test_a_rejected_first_send_retains_history_without_otp_expiration`, `test_a_failed_resend_keeps_the_request_so_the_user_can_try_again`, `test_the_right_code_signs_the_user_in`, `test_the_access_token_from_verify_code_works`, `test_the_refresh_token_from_verify_code_works`, `test_the_same_phone_number_is_the_same_user_every_time`, `test_different_phone_numbers_are_different_users`, `test_the_profile_of_a_returning_user_is_returned`, `test_arabic_digits_are_accepted_for_the_code`, `test_spaces_around_the_code_are_ignored`, `test_a_wrong_code_is_refused_and_the_request_stays_open`, `test_the_right_code_still_works_on_the_third_try`, `test_after_three_wrong_tries_even_the_right_code_is_refused`, `test_a_resend_does_not_give_new_tries`, `test_a_new_request_has_its_own_three_tries`, `test_a_code_made_for_another_phone_number_is_wrong`, `test_a_code_works_until_300_seconds_after_it_was_sent`, `test_a_wrong_code_is_expired_only_after_300_seconds`, `test_an_expired_code_is_reported_as_expired_and_costs_no_try`, `test_expired_attempts_never_lock_the_request`, `test_a_resend_restarts_the_five_minutes_of_the_request`, `test_a_finished_request_cannot_sign_in_again`, `test_after_signing_in_a_new_request_works`, `test_an_unknown_verification_id_is_refused`, `test_a_badly_formed_code_is_refused_without_costing_a_try`, `test_a_badly_formed_code_is_never_repeated_in_the_answer`, `test_verify_code_needs_both_fields_and_refuses_unknown_ones`, `test_a_provider_failure_while_checking_gives_503_and_costs_no_try` |
| [`backend/tests/test_sms.py`](backend/tests/test_sms.py) | اختبار | `test_the_app_under_test_uses_the_fake_sender`, `test_fake_sender_keeps_what_would_have_been_sent`, `test_the_code_has_6_digits_and_keeps_its_leading_zeros`, `test_codes_are_not_always_the_same`, `test_last_message_to_finds_the_latest_for_that_number`, `test_fake_sender_does_not_log_the_code_in_tests`, `test_in_development_the_fake_sender_logs_the_message_so_the_developer_can_read_the_code`, `test_the_correct_code_is_accepted`, `test_a_code_works_once`, `test_a_wrong_code_is_refused`, `test_a_code_of_the_wrong_length_or_kind_is_refused_like_a_wrong_code`, `test_the_fake_never_blocks_wrong_tries_like_authentica`, `test_a_code_is_valid_for_300_seconds`, `test_a_code_is_refused_after_300_seconds`, `test_the_validity_comes_from_the_setting`, `test_a_code_of_another_phone_number_is_refused`, `test_a_number_that_got_no_code_has_nothing_to_check`, `test_a_new_code_replaces_the_old_code_of_the_same_number`, `test_tests_cannot_open_a_network_connection`, `test_testing_environment_refuses_any_sender_but_the_fake_one`, `test_testing_environment_ignores_the_sms_backend_environment_variable`, `test_production_refuses_the_fake_sender`, `test_unknown_backend_is_refused`, `test_authentica_backend_needs_the_api_key`, `test_an_empty_api_key_is_refused_like_a_missing_one`, `test_authentica_backend_with_a_key_builds_the_real_sender_without_any_call`, `test_production_may_use_authentica` |
| [`backend/tests/test_user_store.py`](backend/tests/test_user_store.py) | اختبار | `store`, `test_a_new_phone_number_creates_a_user_without_a_profile`, `test_the_same_phone_number_gives_the_same_user`, `test_different_phone_numbers_give_different_users`, `test_get_finds_a_user_by_id`, `test_update_profile_replaces_the_three_names`, `test_update_profile_of_an_unknown_user_is_none`, `test_the_public_form_of_a_user_has_no_secret_fields`, `test_twenty_sign_ins_at_once_create_one_user` |
| [`backend/tests/test_validation.py`](backend/tests/test_validation.py) | اختبار | `post_refresh`, `test_body_that_is_not_json_is_rejected`, `test_malformed_json_is_rejected`, `test_empty_object_reports_the_missing_field`, `test_wrong_type_is_rejected`, `test_unknown_field_is_rejected`, `test_body_that_is_not_an_object_is_rejected`, `test_error_does_not_echo_the_value_that_was_sent` |

### اختبارات التكامل (16 ملف)

| الملف | نوعه | التعريفات المباشرة داخله |
|---|---|---|
| [`backend/integration_tests/conftest.py`](backend/integration_tests/conftest.py) | اختبار | `database_app`, `database`, `account` |
| [`backend/integration_tests/helpers.py`](backend/integration_tests/helpers.py) | اختبار | `run`, `count`, `offline_circle`, `add_manager`, `Api`, `error_code` |
| [`backend/integration_tests/test_account_api.py`](backend/integration_tests/test_account_api.py) | اختبار | `test_the_account_page_reads_the_real_account`, `test_onboarding_saves_the_birth_date_and_city`, `test_a_birth_date_in_the_future_is_not_saved`, `test_deleting_an_account_without_circles_ends_its_sign_in`, `test_a_bad_body_is_refused_before_anything_is_deleted`, `test_a_patient_must_choose_what_happens_to_their_circle`, `test_continued_care_keeps_the_circle_and_the_patient_name`, `test_a_patient_can_delete_the_circle_with_the_account`, `test_the_only_manager_must_agree_to_delete_the_circle`, `test_a_member_leaves_other_circles_untouched` |
| [`backend/integration_tests/test_auth_persistence.py`](backend/integration_tests/test_auth_persistence.py) | اختبار | `auth_app`, `restarted`, `start`, `verify`, `headers`, `test_signup_profile_and_returning_account_are_persisted`, `test_session_and_logout_survive_app_restart`, `test_logout_preserves_another_session`, `test_pending_challenge_and_quotas_survive_restart`, `test_new_challenge_supersedes_previous_request`, `test_concurrent_quota_claims_cannot_exceed_three`, `test_resend_rechecks_attempts_before_reserving_delivery`, `test_concurrent_verification_attempts_cannot_exceed_three`, `test_concurrent_success_creates_one_session`, `test_refresh_expiry_ends_access_even_before_jwt_expiry`, `test_account_deletion_removes_sessions`, `test_failed_session_insert_rolls_back_account_and_verification`, `test_delivery_uncertainty_retains_quota` |
| [`backend/integration_tests/test_circle_api.py`](backend/integration_tests/test_circle_api.py) | اختبار | `circle_url`, `simplified_circle`, `test_self_care_circle_is_created_and_listed`, `test_the_account_page_tells_which_circle_the_account_receives_care_in`, `test_managing_the_circle_of_someone_else_is_not_receiving_care`, `test_a_second_self_care_circle_is_refused`, `test_a_self_care_circle_needs_only_its_name_after_onboarding`, `test_a_self_care_circle_without_a_saved_birth_date_asks_for_it`, `test_an_account_without_a_profile_cannot_create_a_circle`, `test_a_birth_date_in_the_future_is_refused`, `test_a_bad_medical_part_creates_nothing`, `test_circle_for_a_patient_without_an_account`, `test_circle_for_a_patient_without_an_account_needs_both_names`, `test_a_stranger_gets_the_same_refusal_for_any_circle`, `test_the_circle_page_lists_members_you_first`, `test_a_simplified_patient_sees_the_circle_without_invitations`, `test_a_manager_cannot_rename_an_automatic_name`, `test_a_blank_circle_name_is_refused`, `test_a_simplified_patient_renames_their_own_circle`, `test_a_manager_edits_the_data_of_a_patient_without_an_account`, `test_a_patient_without_an_account_keeps_both_names_required`, `test_names_of_a_patient_with_an_account_come_from_the_account`, `test_a_simplified_patient_edits_their_own_data`, `test_a_manager_leaves_and_loses_access`, `test_the_last_manager_must_confirm_deleting_the_circle`, `test_deleting_a_circle_needs_the_confirmation_in_the_url`, `test_a_manager_cannot_delete_a_circle_that_has_other_managers`, `test_the_patient_can_delete_their_circle`, `test_nothing_is_left_when_a_circle_is_deleted`, `test_invitation_from_sending_to_accepting`, `test_declining_an_invitation_gives_no_access`, `test_an_invitation_is_hidden_from_everyone_else`, `test_inviting_yourself_or_a_current_manager_is_refused`, `test_inviting_the_same_number_again_sends_the_same_invitation`, `test_resending_and_canceling_an_invitation`, `test_an_invitation_cannot_be_reached_through_another_circle` |
| [`backend/integration_tests/test_circle_naming.py`](backend/integration_tests/test_circle_naming.py) | اختبار | `test_your_own_circle_shows_your_name_only_to_you` وغيرها |
| [`backend/integration_tests/test_core.py`](backend/integration_tests/test_core.py) | اختبار | `test_circle_access_joins_an_existing_transaction`, `test_migrations_create_care_authentication_and_medical_tables`, `test_incomplete_accounts_cannot_start_care`, `test_self_care_has_patient_and_manager`, `test_no_account_patient_does_not_create_an_account`, `test_deferred_checks_reject_incomplete_circles`, `test_database_rejects_non_detailed_managers`, `test_account_mode_is_immutable`, `test_names_have_one_source`, `test_detailed_patient_must_remain_a_manager`, `test_creation_requires_consent_and_completion`, `test_completion_supersedes_competing_requests`, `test_self_creation_supersedes_pending_request`, `test_invitation_resend_and_acceptance_are_idempotent`, `test_simplified_account_cannot_accept_management`, `test_wrong_account_cannot_respond`, `test_last_manager_requires_explicit_deletion`, `test_patient_controls_circle_deletion`, `test_continued_care_detaches_names_atomically`, `test_invitation_survives_sender_account_deletion`, `test_parallel_departures_cannot_remove_both_managers`, `test_parallel_self_and_request_creation_make_one_circle`, `test_postgres_adapter_preserves_user_contract`, `test_schema_rejects_completed_request_without_circle` |
| [`backend/integration_tests/test_database_errors.py`](backend/integration_tests/test_database_errors.py) | اختبار | `test_conflict_is_safe_and_next_request_still_works`, `test_connection_failure_does_not_log_parameters`, `test_patient_activation_waits_for_account_profile_update`, `test_programming_error_is_not_database_unavailability` |
| [`backend/integration_tests/test_demo_data.py`](backend/integration_tests/test_demo_data.py) | اختبار | `_count`, `_run`, `_sign_in`, `test_demo_data_makes_the_whole_story`, `test_the_demo_account_reads_it_like_the_app`, `test_it_runs_once_and_resets_on_request`, `test_a_reset_works_after_lina_joined_saras_circle`, `test_a_reset_leaves_other_accounts_alone`, `test_it_needs_the_fake_sms` |
| [`backend/integration_tests/test_home.py`](backend/integration_tests/test_home.py) | اختبار | `signed_in`, `test_home_requires_authentication`, `test_home_returns_empty_circles_and_own_identity`, `test_home_excludes_other_circles_and_pending_invitations`, `test_home_lists_patient_manager_circle_once`, `test_home_includes_patient_without_management`, `test_home_rechecks_membership_on_each_request`, `test_incomplete_profile_does_not_start_home`, `test_signed_out_session_cannot_read_home` |
| [`backend/integration_tests/test_lifecycle.py`](backend/integration_tests/test_lifecycle.py) | اختبار | `test_simplified_patient_can_edit_own_profile`, `test_patient_can_delete_circle_without_deleting_account`, `test_manager_cannot_delete_another_patients_circle`, `test_failed_creation_rolls_back_mode_assignment`, `test_canceling_consent_does_not_change_assigned_mode`, `test_deleting_patient_account_cancels_accepted_request`, `test_only_one_accepted_incomplete_request`, `test_other_manager_can_cancel_pending_invitation`, `test_direct_parallel_deletes_cannot_bypass_integrity`, `test_concurrent_first_sign_ins_create_one_account`, `test_api_registration_and_profile_use_postgres`, `test_migrations_round_trip`, `test_sign_in_survives_deletion_before_account_read`, `test_completion_handles_deletion_before_request_lock` |
| [`backend/integration_tests/test_measurements.py`](backend/integration_tests/test_measurements.py) | اختبار | `close_app_session`, `signed_in`, `test_plan_occurrence_reading_and_export`, `test_plan_validation_and_authorization`, `test_future_plan_can_be_edited_before_its_first_task`, `test_concurrent_task_records_keep_one_outcome` |
| [`backend/integration_tests/test_medical_api.py`](backend/integration_tests/test_medical_api.py) | اختبار | `url`, `profile_url`, `setup`, `test_a_new_circle_has_an_unknown_medical_file`, `test_blood_type_conditions_and_allergies_are_saved`, `test_no_conditions_and_no_allergies_are_different_from_unknown`, `test_only_the_parts_in_the_body_change`, `test_null_clears_a_part_back_to_unknown`, `test_a_new_list_replaces_the_old_one`, `test_wrong_medical_data_is_refused_and_nothing_changes`, `test_a_service_error_names_the_field`, `test_only_members_of_the_circle_reach_the_medical_file`, `test_the_patient_and_every_manager_can_edit_the_medical_file`, `test_a_manager_who_left_loses_the_medical_file`, `contact`, `test_emergency_contacts_are_added_listed_changed_and_removed`, `test_the_same_number_cannot_be_a_contact_twice`, `test_a_patient_has_at_most_five_contacts`, `test_a_wrong_contact_is_refused`, `test_a_contact_is_only_reachable_through_its_own_circle`, `card_url`, `test_a_new_card_shows_the_name_and_unknown_health_data`, `test_the_card_carries_only_what_a_helper_needs`, `test_an_edit_of_the_medical_file_shows_on_the_card`, `test_every_manager_and_the_simplified_patient_can_read_the_card`, `test_a_stranger_and_a_manager_who_left_cannot_read_the_card`, `test_the_card_cannot_be_changed`, `test_database_rules_hold_without_the_api`, `test_the_database_keeps_each_choice_once`, `test_two_managers_editing_at_the_same_time_do_not_collide` |
| [`backend/integration_tests/test_medications.py`](backend/integration_tests/test_medications.py) | اختبار | `signed_in`, `plan_body`, `create_plan`, `test_manager_creates_and_lists_a_complete_plan`, `test_overlapping_current_name_is_rejected_but_later_period_is_allowed`, `test_recording_a_dose_is_idempotent_and_conflicting_change_is_rejected`, `test_revision_keeps_history_and_requires_the_expected_version`, `test_future_revision_and_immediate_stop_keep_only_earlier_dose`, `test_parallel_creation_keeps_one_overlapping_name` |
| [`backend/integration_tests/test_push_api.py`](backend/integration_tests/test_push_api.py) | اختبار | `Phone`, `pushes`, `devices`, `test_a_phone_registers_its_token`, `test_a_token_moves_with_the_phone`, `test_an_invitation_reaches_the_invited_phone`, `test_a_number_without_the_app_gets_no_push`, `test_a_signed_out_phone_is_not_told`, `test_a_circle_request_from_sending_to_the_circle`, `test_a_declined_request_is_told`, `test_a_token_apple_forgot_is_deleted`, `test_without_a_push_service_the_request_still_works`, `test_a_broken_push_never_breaks_the_request`, `test_deleting_the_account_deletes_its_tokens` |
| [`backend/integration_tests/test_request_api.py`](backend/integration_tests/test_request_api.py) | اختبار | `send`, `test_request_from_sending_to_the_new_circle`, `test_a_detailed_patient_also_manages_the_circle`, `test_the_basic_data_and_medical_profile_are_saved_together`, `test_a_failed_completion_keeps_the_accepted_request`, `test_completing_twice_returns_the_same_circle`, `test_a_circle_needs_the_consent_first`, `test_the_sender_cannot_give_the_consent`, `test_a_request_is_hidden_from_strangers`, `test_declining_is_shown_to_the_sender_for_a_week`, `test_asking_the_same_person_twice_returns_the_open_request`, `test_sender_and_patient_can_cancel_an_open_request`, `test_you_cannot_ask_for_a_circle_for_your_own_number`, `test_a_person_who_already_has_a_circle_cannot_be_asked`, `test_an_incomplete_profile_cannot_send_a_request`, `test_a_request_waits_for_a_person_who_signs_up_later`, `test_a_finished_request_cannot_be_answered_the_other_way`, `test_a_patient_who_finished_onboarding_completes_without_basics` |
| [`backend/integration_tests/test_schema_health.py`](backend/integration_tests/test_schema_health.py) | اختبار | `test_a_migrated_database_is_healthy`, `test_the_expected_revision_is_where_a_migrated_database_is`, `test_a_database_that_is_not_migrated_is_reported` |

## ملفات الربط والإعداد المهمة

| الملف | دوره |
|---|---|
| [`app/assets/translations/ar.json`](app/assets/translations/ar.json) | كل النصوص العربية الظاهرة |
| [`app/pubspec.yaml`](app/pubspec.yaml) | حزم Flutter والأصول |
| [`app/ios/Runner/AppDelegate.swift`](app/ios/Runner/AppDelegate.swift) | ربط iOS بإشعارات الهاتف وAPNs |
| [`app/ios/Runner/Info.plist`](app/ios/Runner/Info.plist) | أذونات iOS وإعدادات التطبيق |
| [`backend/.env.example`](backend/.env.example) | أسماء متغيرات البيئة، دون أسرار |
| [`backend/requirements.txt`](backend/requirements.txt) | حزم الخادم |
| [`.github/workflows/testflight.yml`](.github/workflows/testflight.yml) | بناء TestFlight |
| [`AGENTS.md`](AGENTS.md) | قواعد العمل على المشروع |

_الفهرس آلي من تعريفات المستوى الأعلى؛ بعض المكونات الصغيرة والدوال الخاصة موجودة داخل الملفات المدرجة ولا يعني غياب اسمها من العمود أنها غير موجودة._

## بقية ملفات المشروع (201 ملف)

هذا الملحق يكمل الفهرس بكل الملفات المتتبعة وغير المتتبعة الظاهرة محليًا، باستثناء ملفات البيئة السرية والمجلدات المولّدة/المتجاهلة مثل `.worktrees` و`.venv` و`build`.

| الملف | دوره |
|---|---|
| [`.github/pull_request_template.md`](.github/pull_request_template.md) | قالب GitHub |
| [`.github/workflows/ios-build.yml`](.github/workflows/ios-build.yml) | سير عمل البناء الآلي |
| [`.github/workflows/testflight.yml`](.github/workflows/testflight.yml) | سير عمل البناء الآلي |
| [`.gitignore`](.gitignore) | تهيئة أو أصل مشروع |
| [`AGENTS.md`](AGENTS.md) | توثيق أو قواعد المشروع |
| [`README.md`](README.md) | توثيق أو قواعد المشروع |
| [`app/.env.example`](app/.env.example) | تهيئة أو أصل مشروع |
| [`app/.gitignore`](app/.gitignore) | تهيئة أو أصل مشروع |
| [`app/.metadata`](app/.metadata) | تهيئة أو أصل مشروع |
| [`app/README.md`](app/README.md) | توثيق أو قواعد المشروع |
| [`app/analysis_options.yaml`](app/analysis_options.yaml) | تهيئة أو أصل مشروع |
| [`app/android/.gitignore`](app/android/.gitignore) | ملفات منصة Android موجودة في المشروع |
| [`app/android/app/build.gradle.kts`](app/android/app/build.gradle.kts) | ملفات منصة Android موجودة في المشروع |
| [`app/android/app/src/debug/AndroidManifest.xml`](app/android/app/src/debug/AndroidManifest.xml) | ملفات منصة Android موجودة في المشروع |
| [`app/android/app/src/main/AndroidManifest.xml`](app/android/app/src/main/AndroidManifest.xml) | ملفات منصة Android موجودة في المشروع |
| [`app/android/app/src/main/kotlin/com/tfaqud/app/MainActivity.kt`](app/android/app/src/main/kotlin/com/tfaqud/app/MainActivity.kt) | ملفات منصة Android موجودة في المشروع |
| [`app/android/app/src/main/kotlin/com/tfaqud/tfaqud/MainActivity.kt`](app/android/app/src/main/kotlin/com/tfaqud/tfaqud/MainActivity.kt) | ملفات منصة Android موجودة في المشروع |
| [`app/android/app/src/main/res/drawable-v21/launch_background.xml`](app/android/app/src/main/res/drawable-v21/launch_background.xml) | ملفات منصة Android موجودة في المشروع |
| [`app/android/app/src/main/res/drawable/launch_background.xml`](app/android/app/src/main/res/drawable/launch_background.xml) | ملفات منصة Android موجودة في المشروع |
| [`app/android/app/src/main/res/mipmap-hdpi/ic_launcher.png`](app/android/app/src/main/res/mipmap-hdpi/ic_launcher.png) | ملفات منصة Android موجودة في المشروع |
| [`app/android/app/src/main/res/mipmap-mdpi/ic_launcher.png`](app/android/app/src/main/res/mipmap-mdpi/ic_launcher.png) | ملفات منصة Android موجودة في المشروع |
| [`app/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`](app/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png) | ملفات منصة Android موجودة في المشروع |
| [`app/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`](app/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png) | ملفات منصة Android موجودة في المشروع |
| [`app/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`](app/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png) | ملفات منصة Android موجودة في المشروع |
| [`app/android/app/src/main/res/values-night/styles.xml`](app/android/app/src/main/res/values-night/styles.xml) | ملفات منصة Android موجودة في المشروع |
| [`app/android/app/src/main/res/values/styles.xml`](app/android/app/src/main/res/values/styles.xml) | ملفات منصة Android موجودة في المشروع |
| [`app/android/app/src/profile/AndroidManifest.xml`](app/android/app/src/profile/AndroidManifest.xml) | ملفات منصة Android موجودة في المشروع |
| [`app/android/build.gradle.kts`](app/android/build.gradle.kts) | ملفات منصة Android موجودة في المشروع |
| [`app/android/gradle.properties`](app/android/gradle.properties) | ملفات منصة Android موجودة في المشروع |
| [`app/android/gradle/wrapper/gradle-wrapper.properties`](app/android/gradle/wrapper/gradle-wrapper.properties) | ملفات منصة Android موجودة في المشروع |
| [`app/android/settings.gradle.kts`](app/android/settings.gradle.kts) | ملفات منصة Android موجودة في المشروع |
| [`app/assets/avatars/LICENSE_fluentui-emoji.txt`](app/assets/avatars/LICENSE_fluentui-emoji.txt) | شخصية أو ترخيص صور الشخصيات |
| [`app/assets/avatars/m1_1.png`](app/assets/avatars/m1_1.png) | شخصية أو ترخيص صور الشخصيات |
| [`app/assets/avatars/m1_3.png`](app/assets/avatars/m1_3.png) | شخصية أو ترخيص صور الشخصيات |
| [`app/assets/avatars/m2_1.png`](app/assets/avatars/m2_1.png) | شخصية أو ترخيص صور الشخصيات |
| [`app/assets/avatars/m2_3.png`](app/assets/avatars/m2_3.png) | شخصية أو ترخيص صور الشخصيات |
| [`app/assets/avatars/m6_1.png`](app/assets/avatars/m6_1.png) | شخصية أو ترخيص صور الشخصيات |
| [`app/assets/avatars/m6_3.png`](app/assets/avatars/m6_3.png) | شخصية أو ترخيص صور الشخصيات |
| [`app/assets/avatars/w1_1.png`](app/assets/avatars/w1_1.png) | شخصية أو ترخيص صور الشخصيات |
| [`app/assets/avatars/w1_3.png`](app/assets/avatars/w1_3.png) | شخصية أو ترخيص صور الشخصيات |
| [`app/assets/avatars/w6_1.png`](app/assets/avatars/w6_1.png) | شخصية أو ترخيص صور الشخصيات |
| [`app/assets/avatars/w6_3.png`](app/assets/avatars/w6_3.png) | شخصية أو ترخيص صور الشخصيات |
| [`app/assets/avatars/w7_1.png`](app/assets/avatars/w7_1.png) | شخصية أو ترخيص صور الشخصيات |
| [`app/assets/avatars/w7_3.png`](app/assets/avatars/w7_3.png) | شخصية أو ترخيص صور الشخصيات |
| [`app/assets/fonts/IBMPlexSansArabic-Bold.ttf`](app/assets/fonts/IBMPlexSansArabic-Bold.ttf) | أصل بصري أو خط للتطبيق |
| [`app/assets/fonts/IBMPlexSansArabic-Medium.ttf`](app/assets/fonts/IBMPlexSansArabic-Medium.ttf) | أصل بصري أو خط للتطبيق |
| [`app/assets/fonts/IBMPlexSansArabic-Regular.ttf`](app/assets/fonts/IBMPlexSansArabic-Regular.ttf) | أصل بصري أو خط للتطبيق |
| [`app/assets/fonts/IBMPlexSansArabic-SemiBold.ttf`](app/assets/fonts/IBMPlexSansArabic-SemiBold.ttf) | أصل بصري أو خط للتطبيق |
| [`app/assets/fonts/OFL.txt`](app/assets/fonts/OFL.txt) | أصل بصري أو خط للتطبيق |
| [`app/assets/icons/.gitkeep`](app/assets/icons/.gitkeep) | أصل بصري أو خط للتطبيق |
| [`app/assets/images/.gitkeep`](app/assets/images/.gitkeep) | أصل بصري أو خط للتطبيق |
| [`app/assets/images/owl_follow.png`](app/assets/images/owl_follow.png) | أصل بصري أو خط للتطبيق |
| [`app/assets/images/owl_organize.png`](app/assets/images/owl_organize.png) | أصل بصري أو خط للتطبيق |
| [`app/assets/images/owl_share.png`](app/assets/images/owl_share.png) | أصل بصري أو خط للتطبيق |
| [`app/assets/translations/ar.json`](app/assets/translations/ar.json) | نصوص الواجهة المترجمة |
| [`app/devtools_options.yaml`](app/devtools_options.yaml) | تهيئة أو أصل مشروع |
| [`app/ios/.gitignore`](app/ios/.gitignore) | بناء وإعداد تطبيق iOS |
| [`app/ios/Flutter/AppFrameworkInfo.plist`](app/ios/Flutter/AppFrameworkInfo.plist) | بناء وإعداد تطبيق iOS |
| [`app/ios/Flutter/Debug.xcconfig`](app/ios/Flutter/Debug.xcconfig) | بناء وإعداد تطبيق iOS |
| [`app/ios/Flutter/Release.xcconfig`](app/ios/Flutter/Release.xcconfig) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner.xcodeproj/project.pbxproj`](app/ios/Runner.xcodeproj/project.pbxproj) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner.xcodeproj/project.xcworkspace/contents.xcworkspacedata`](app/ios/Runner.xcodeproj/project.xcworkspace/contents.xcworkspacedata) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist`](app/ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings`](app/ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme`](app/ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner.xcworkspace/contents.xcworkspacedata`](app/ios/Runner.xcworkspace/contents.xcworkspacedata) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist`](app/ios/Runner.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings`](app/ios/Runner.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/AppDelegate.swift`](app/ios/Runner/AppDelegate.swift) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json`](app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`](app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png`](app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png`](app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png`](app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png`](app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png`](app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png`](app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png`](app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png`](app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png`](app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png`](app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png`](app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png`](app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png`](app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png`](app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json`](app/ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png`](app/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png`](app/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png`](app/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md`](app/ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Assets.xcassets/tab_add.imageset/Contents.json`](app/ios/Runner/Assets.xcassets/tab_add.imageset/Contents.json) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Assets.xcassets/tab_add.imageset/tab_add.svg`](app/ios/Runner/Assets.xcassets/tab_add.imageset/tab_add.svg) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Assets.xcassets/tab_circle.imageset/Contents.json`](app/ios/Runner/Assets.xcassets/tab_circle.imageset/Contents.json) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Assets.xcassets/tab_circle.imageset/tab_circle.svg`](app/ios/Runner/Assets.xcassets/tab_circle.imageset/tab_circle.svg) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Assets.xcassets/tab_plan.imageset/Contents.json`](app/ios/Runner/Assets.xcassets/tab_plan.imageset/Contents.json) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Assets.xcassets/tab_plan.imageset/tab_plan.svg`](app/ios/Runner/Assets.xcassets/tab_plan.imageset/tab_plan.svg) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Assets.xcassets/tab_record.imageset/Contents.json`](app/ios/Runner/Assets.xcassets/tab_record.imageset/Contents.json) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Assets.xcassets/tab_record.imageset/tab_record.svg`](app/ios/Runner/Assets.xcassets/tab_record.imageset/tab_record.svg) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Assets.xcassets/tab_today.imageset/Contents.json`](app/ios/Runner/Assets.xcassets/tab_today.imageset/Contents.json) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Assets.xcassets/tab_today.imageset/tab_today.svg`](app/ios/Runner/Assets.xcassets/tab_today.imageset/tab_today.svg) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Base.lproj/LaunchScreen.storyboard`](app/ios/Runner/Base.lproj/LaunchScreen.storyboard) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Base.lproj/Main.storyboard`](app/ios/Runner/Base.lproj/Main.storyboard) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Info.plist`](app/ios/Runner/Info.plist) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Runner-Bridging-Header.h`](app/ios/Runner/Runner-Bridging-Header.h) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/Runner.entitlements`](app/ios/Runner/Runner.entitlements) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/RunnerRelease.entitlements`](app/ios/Runner/RunnerRelease.entitlements) | بناء وإعداد تطبيق iOS |
| [`app/ios/Runner/SceneDelegate.swift`](app/ios/Runner/SceneDelegate.swift) | بناء وإعداد تطبيق iOS |
| [`app/ios/RunnerTests/RunnerTests.swift`](app/ios/RunnerTests/RunnerTests.swift) | بناء وإعداد تطبيق iOS |
| [`app/linux/.gitignore`](app/linux/.gitignore) | ملفات منصة Linux مولّدة أو موروثة |
| [`app/linux/CMakeLists.txt`](app/linux/CMakeLists.txt) | ملفات منصة Linux مولّدة أو موروثة |
| [`app/linux/flutter/CMakeLists.txt`](app/linux/flutter/CMakeLists.txt) | ملفات منصة Linux مولّدة أو موروثة |
| [`app/linux/flutter/generated_plugin_registrant.cc`](app/linux/flutter/generated_plugin_registrant.cc) | ملفات منصة Linux مولّدة أو موروثة |
| [`app/linux/flutter/generated_plugin_registrant.h`](app/linux/flutter/generated_plugin_registrant.h) | ملفات منصة Linux مولّدة أو موروثة |
| [`app/linux/flutter/generated_plugins.cmake`](app/linux/flutter/generated_plugins.cmake) | ملفات منصة Linux مولّدة أو موروثة |
| [`app/linux/runner/CMakeLists.txt`](app/linux/runner/CMakeLists.txt) | ملفات منصة Linux مولّدة أو موروثة |
| [`app/linux/runner/main.cc`](app/linux/runner/main.cc) | ملفات منصة Linux مولّدة أو موروثة |
| [`app/linux/runner/my_application.cc`](app/linux/runner/my_application.cc) | ملفات منصة Linux مولّدة أو موروثة |
| [`app/linux/runner/my_application.h`](app/linux/runner/my_application.h) | ملفات منصة Linux مولّدة أو موروثة |
| [`app/macos/.gitignore`](app/macos/.gitignore) | ملفات منصة macOS مولّدة أو موروثة |
| [`app/macos/Flutter/Flutter-Debug.xcconfig`](app/macos/Flutter/Flutter-Debug.xcconfig) | ملفات منصة macOS مولّدة أو موروثة |
| [`app/macos/Flutter/Flutter-Release.xcconfig`](app/macos/Flutter/Flutter-Release.xcconfig) | ملفات منصة macOS مولّدة أو موروثة |
| [`app/macos/Flutter/GeneratedPluginRegistrant.swift`](app/macos/Flutter/GeneratedPluginRegistrant.swift) | ملفات منصة macOS مولّدة أو موروثة |
| [`app/macos/Runner.xcodeproj/project.pbxproj`](app/macos/Runner.xcodeproj/project.pbxproj) | ملفات منصة macOS مولّدة أو موروثة |
| [`app/macos/Runner.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist`](app/macos/Runner.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist) | ملفات منصة macOS مولّدة أو موروثة |
| [`app/macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme`](app/macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme) | ملفات منصة macOS مولّدة أو موروثة |
| [`app/macos/Runner.xcworkspace/contents.xcworkspacedata`](app/macos/Runner.xcworkspace/contents.xcworkspacedata) | ملفات منصة macOS مولّدة أو موروثة |
| [`app/macos/Runner.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist`](app/macos/Runner.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist) | ملفات منصة macOS مولّدة أو موروثة |
| [`app/macos/Runner/AppDelegate.swift`](app/macos/Runner/AppDelegate.swift) | ملفات منصة macOS مولّدة أو موروثة |
| [`app/macos/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json`](app/macos/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json) | ملفات منصة macOS مولّدة أو موروثة |
| [`app/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png`](app/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png) | ملفات منصة macOS مولّدة أو موروثة |
| [`app/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png`](app/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png) | ملفات منصة macOS مولّدة أو موروثة |
| [`app/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png`](app/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png) | ملفات منصة macOS مولّدة أو موروثة |
| [`app/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png`](app/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png) | ملفات منصة macOS مولّدة أو موروثة |
| [`app/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png`](app/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png) | ملفات منصة macOS مولّدة أو موروثة |
| [`app/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png`](app/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png) | ملفات منصة macOS مولّدة أو موروثة |
| [`app/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png`](app/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png) | ملفات منصة macOS مولّدة أو موروثة |
| [`app/macos/Runner/Base.lproj/MainMenu.xib`](app/macos/Runner/Base.lproj/MainMenu.xib) | ملفات منصة macOS مولّدة أو موروثة |
| [`app/macos/Runner/Configs/AppInfo.xcconfig`](app/macos/Runner/Configs/AppInfo.xcconfig) | ملفات منصة macOS مولّدة أو موروثة |
| [`app/macos/Runner/Configs/Debug.xcconfig`](app/macos/Runner/Configs/Debug.xcconfig) | ملفات منصة macOS مولّدة أو موروثة |
| [`app/macos/Runner/Configs/Release.xcconfig`](app/macos/Runner/Configs/Release.xcconfig) | ملفات منصة macOS مولّدة أو موروثة |
| [`app/macos/Runner/Configs/Warnings.xcconfig`](app/macos/Runner/Configs/Warnings.xcconfig) | ملفات منصة macOS مولّدة أو موروثة |
| [`app/macos/Runner/DebugProfile.entitlements`](app/macos/Runner/DebugProfile.entitlements) | ملفات منصة macOS مولّدة أو موروثة |
| [`app/macos/Runner/Info.plist`](app/macos/Runner/Info.plist) | ملفات منصة macOS مولّدة أو موروثة |
| [`app/macos/Runner/MainFlutterWindow.swift`](app/macos/Runner/MainFlutterWindow.swift) | ملفات منصة macOS مولّدة أو موروثة |
| [`app/macos/Runner/Release.entitlements`](app/macos/Runner/Release.entitlements) | ملفات منصة macOS مولّدة أو موروثة |
| [`app/macos/RunnerTests/RunnerTests.swift`](app/macos/RunnerTests/RunnerTests.swift) | ملفات منصة macOS مولّدة أو موروثة |
| [`app/pubspec.lock`](app/pubspec.lock) | تهيئة أو أصل مشروع |
| [`app/pubspec.yaml`](app/pubspec.yaml) | تهيئة أو أصل مشروع |
| [`app/test/goldens/design_system/contrast_default.png`](app/test/goldens/design_system/contrast_default.png) | صورة أو بيانات مساعدة للاختبارات |
| [`app/test/goldens/design_system/contrast_large.png`](app/test/goldens/design_system/contrast_large.png) | صورة أو بيانات مساعدة للاختبارات |
| [`app/test/goldens/design_system/light_default.png`](app/test/goldens/design_system/light_default.png) | صورة أو بيانات مساعدة للاختبارات |
| [`app/test/goldens/design_system/light_large.png`](app/test/goldens/design_system/light_large.png) | صورة أو بيانات مساعدة للاختبارات |
| [`app/test/goldens/preview/plan.png`](app/test/goldens/preview/plan.png) | صورة أو بيانات مساعدة للاختبارات |
| [`app/test/goldens/preview/today.png`](app/test/goldens/preview/today.png) | صورة أو بيانات مساعدة للاختبارات |
| [`app/web/favicon.png`](app/web/favicon.png) | ملفات منصة الويب مولّدة أو موروثة |
| [`app/web/icons/Icon-192.png`](app/web/icons/Icon-192.png) | ملفات منصة الويب مولّدة أو موروثة |
| [`app/web/icons/Icon-512.png`](app/web/icons/Icon-512.png) | ملفات منصة الويب مولّدة أو موروثة |
| [`app/web/icons/Icon-maskable-192.png`](app/web/icons/Icon-maskable-192.png) | ملفات منصة الويب مولّدة أو موروثة |
| [`app/web/icons/Icon-maskable-512.png`](app/web/icons/Icon-maskable-512.png) | ملفات منصة الويب مولّدة أو موروثة |
| [`app/web/index.html`](app/web/index.html) | ملفات منصة الويب مولّدة أو موروثة |
| [`app/web/manifest.json`](app/web/manifest.json) | ملفات منصة الويب مولّدة أو موروثة |
| [`app/windows/.gitignore`](app/windows/.gitignore) | ملفات منصة Windows مولّدة أو موروثة |
| [`app/windows/CMakeLists.txt`](app/windows/CMakeLists.txt) | ملفات منصة Windows مولّدة أو موروثة |
| [`app/windows/flutter/CMakeLists.txt`](app/windows/flutter/CMakeLists.txt) | ملفات منصة Windows مولّدة أو موروثة |
| [`app/windows/flutter/generated_plugin_registrant.cc`](app/windows/flutter/generated_plugin_registrant.cc) | ملفات منصة Windows مولّدة أو موروثة |
| [`app/windows/flutter/generated_plugin_registrant.h`](app/windows/flutter/generated_plugin_registrant.h) | ملفات منصة Windows مولّدة أو موروثة |
| [`app/windows/flutter/generated_plugins.cmake`](app/windows/flutter/generated_plugins.cmake) | ملفات منصة Windows مولّدة أو موروثة |
| [`app/windows/runner/CMakeLists.txt`](app/windows/runner/CMakeLists.txt) | ملفات منصة Windows مولّدة أو موروثة |
| [`app/windows/runner/Runner.rc`](app/windows/runner/Runner.rc) | ملفات منصة Windows مولّدة أو موروثة |
| [`app/windows/runner/flutter_window.cpp`](app/windows/runner/flutter_window.cpp) | ملفات منصة Windows مولّدة أو موروثة |
| [`app/windows/runner/flutter_window.h`](app/windows/runner/flutter_window.h) | ملفات منصة Windows مولّدة أو موروثة |
| [`app/windows/runner/main.cpp`](app/windows/runner/main.cpp) | ملفات منصة Windows مولّدة أو موروثة |
| [`app/windows/runner/resource.h`](app/windows/runner/resource.h) | ملفات منصة Windows مولّدة أو موروثة |
| [`app/windows/runner/resources/app_icon.ico`](app/windows/runner/resources/app_icon.ico) | ملفات منصة Windows مولّدة أو موروثة |
| [`app/windows/runner/runner.exe.manifest`](app/windows/runner/runner.exe.manifest) | ملفات منصة Windows مولّدة أو موروثة |
| [`app/windows/runner/utils.cpp`](app/windows/runner/utils.cpp) | ملفات منصة Windows مولّدة أو موروثة |
| [`app/windows/runner/utils.h`](app/windows/runner/utils.h) | ملفات منصة Windows مولّدة أو موروثة |
| [`app/windows/runner/win32_window.cpp`](app/windows/runner/win32_window.cpp) | ملفات منصة Windows مولّدة أو موروثة |
| [`app/windows/runner/win32_window.h`](app/windows/runner/win32_window.h) | ملفات منصة Windows مولّدة أو موروثة |
| [`backend/.dockerignore`](backend/.dockerignore) | تهيئة أو توثيق الخادم |
| [`backend/.env.example`](backend/.env.example) | تهيئة أو توثيق الخادم |
| [`backend/.gitignore`](backend/.gitignore) | تهيئة أو توثيق الخادم |
| [`backend/Dockerfile`](backend/Dockerfile) | تهيئة أو توثيق الخادم |
| [`backend/README.md`](backend/README.md) | تهيئة أو توثيق الخادم |
| [`backend/docker-compose.yml`](backend/docker-compose.yml) | تهيئة أو توثيق الخادم |
| [`backend/docs/api-contracts.md`](backend/docs/api-contracts.md) | توثيق خادم |
| [`backend/docs/authentica-test-guide.md`](backend/docs/authentica-test-guide.md) | توثيق خادم |
| [`backend/migrations/README`](backend/migrations/README) | تهيئة Alembic للمهاجرات |
| [`backend/migrations/alembic.ini`](backend/migrations/alembic.ini) | تهيئة Alembic للمهاجرات |
| [`backend/migrations/env.py`](backend/migrations/env.py) | تهيئة Alembic للمهاجرات |
| [`backend/migrations/script.py.mako`](backend/migrations/script.py.mako) | تهيئة Alembic للمهاجرات |
| [`backend/migrations/versions/0001_core_rules.sql`](backend/migrations/versions/0001_core_rules.sql) | تهيئة Alembic للمهاجرات |
| [`backend/migrations/versions/0006_medication_rules.sql`](backend/migrations/versions/0006_medication_rules.sql) | تهيئة Alembic للمهاجرات |
| [`backend/migrations/versions/0007_medication_rules.sql`](backend/migrations/versions/0007_medication_rules.sql) | تهيئة Alembic للمهاجرات |
| [`backend/pytest.ini`](backend/pytest.ini) | تهيئة أو توثيق الخادم |
| [`backend/requirements-dev.txt`](backend/requirements-dev.txt) | تهيئة أو توثيق الخادم |
| [`backend/requirements.txt`](backend/requirements.txt) | تهيئة أو توثيق الخادم |
| [`backend/wsgi.py`](backend/wsgi.py) | تهيئة أو توثيق الخادم |
| [`docs/project-charter.md`](docs/project-charter.md) | توثيق أو قواعد المشروع |
| [`docs/stage-1-report.md`](docs/stage-1-report.md) | توثيق أو قواعد المشروع |
| [`docs/stage-3-technical-documentation.md`](docs/stage-3-technical-documentation.md) | توثيق أو قواعد المشروع |
