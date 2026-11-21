import 'package:app/core/network/legal_page.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «بالمتابعة توافق على الشروط وسياسة الخصوصية», where the two names open
/// their pages.
class LegalLinksNote extends StatelessWidget {
  const LegalLinksNote({super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.bodySmall;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text('${context.tr('legal.agree_lead')} ', style: style),
        _link(context, style, 'legal.terms_link', LegalPage.terms),
        Text(' ${context.tr('legal.and')}', style: style),
        _link(context, style, 'legal.privacy_link', LegalPage.privacy),
      ],
    );
  }
}

/// One of the two names: underlined, and as tall as a tap target.
Widget _link(
  BuildContext context,
  TextStyle? style,
  String key,
  LegalPage page,
) => Semantics(
  link: true,
  child: InkWell(
    onTap: page.open,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizes.touch),
      child: Center(
        widthFactor: 1,
        child: Text(
          context.tr(key),
          style: style?.copyWith(
            color: AppSemanticColors.actionStrong,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    ),
  ),
);
