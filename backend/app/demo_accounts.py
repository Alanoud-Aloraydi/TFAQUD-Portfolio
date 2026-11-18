"""The demo accounts' numbers and names, shared by the demo story
(app/demo_data/) and the sign-in of those numbers (app/sms/demo.py).

The numbers are made up (+96650000000x), so no real SMS may ever reach
them: they sign in with the demo code instead (DEMO_SIGN_IN_CODE). The
team's own phones can be added to that sign-in in Render, never here
(DEMO_SIGN_IN_PHONES).
"""

from datetime import date

# Phone, first name, last name, display name, and the birth date and city
# that onboarding asks for.
#   - Lina manages her own care, her mother's and her uncle's: the
#     detailed mode.
#   - Sara manages her grandfather's care and helps with Lina's uncle.
#   - Khaled is Lina's uncle, the patient of his own circle: the
#     simplified mode.
DEMO_ACCOUNTS = (
    ("+966500000001", "لينا", "العتيبي", "لينا", date(1994, 3, 12), "الرياض"),
    ("+966500000002", "سارة", "القحطاني", "سارة", date(1990, 9, 2), "جدة"),
    ("+966500000004", "خالد", "العتيبي", "خالد", date(1952, 6, 1), "الرياض"),
)
DEMO_PHONES = tuple(phone for phone, *_ in DEMO_ACCOUNTS)

# The story's other made-up number, which Lina asks for a circle
# (app/demo_data/story.py). It signs in with the demo code as well, so the
# request can be answered on a phone, and no SMS can reach a stranger.
REQUEST_DEMO_PHONE = "+966500000003"

# Every made-up number that signs in with the demo code.
SIGN_IN_DEMO_PHONES = (*DEMO_PHONES, REQUEST_DEMO_PHONE)
