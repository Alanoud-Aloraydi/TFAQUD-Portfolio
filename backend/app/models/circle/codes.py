"""The avatar codes and blood types a circle's patient may have."""


AVATAR_CODES = (
    "w1_1", "w1_3", "w6_1", "w6_3", "w7_1", "w7_3",
    "m1_1", "m1_3", "m2_1", "m2_3", "m6_1", "m6_3",
)
BLOOD_TYPES = ("A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-")
AVATARS_SQL = ", ".join(f"'{code}'" for code in AVATAR_CODES)
BLOOD_SQL = ", ".join(f"'{code}'" for code in BLOOD_TYPES)
