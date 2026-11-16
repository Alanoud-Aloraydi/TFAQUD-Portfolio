import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/presentation/cubit/contact_choice.dart';

/// The members a contact can be picked from: those with a Saudi number,
/// the patient left out, since the patient is who the contacts are for.
List<ContactChoice> contactChoicesOf(CircleOverview overview) =>
    <ContactChoice>[
      for (final CircleMember member in overview.members)
        if (!member.isPatient &&
            member.phoneNumber != null &&
            SaudiMobile.isValid(SaudiMobile.national(member.phoneNumber!)))
          ContactChoice(
            name: member.name,
            phone: SaudiMobile.national(member.phoneNumber!),
            accountId: member.accountId,
            avatarCode: member.avatarCode,
          ),
    ];
