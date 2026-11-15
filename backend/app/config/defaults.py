"""The environments and the default value of every number setting."""

ENVIRONMENTS = ("development", "testing", "staging", "production")

# Default access-token lifetime, overridable through an environment variable.
# A refresh token has none: it works until its session is signed out.
DEFAULT_ACCESS_TOKEN_MINUTES = 15

# OTP validity matches the provider's configured lifetime.
DEFAULT_OTP_VALID_SECONDS = 300
DEFAULT_AUTHENTICA_TEMPLATE_ID = 5  # Arabic text, code of 6 digits

# Server-side limits are configurable per environment.
DEFAULT_OTP_MAX_WRONG_TRIES = 3  # per verification request
# Codes to one phone number in 24 hours, counted since its last sign-in.
DEFAULT_OTP_MAX_SENDS_PER_DAY = 20
# Seconds to wait after the 1st, 2nd, 3rd ... code before the next one; the
# last one repeats. Someone who types another person's number can then only
# slow the owner (at most 10 minutes), never lock them out.
DEFAULT_OTP_RESEND_WAITS = (30, 60, 120, 300, 600)
# Codes one device (X-Device-Id) and one IP may ask for in an hour, for any
# numbers, so one phone or one network cannot send codes to many people.
DEFAULT_OTP_MAX_SENDS_PER_DEVICE_HOUR = 10
DEFAULT_OTP_MAX_SENDS_PER_IP_HOUR = 30

# Every database call has a deadline, like every call to another service:
# a hung query or a held lock must not hold a request (and a gunicorn
# worker) until gunicorn kills it after 120 seconds.
DEFAULT_DATABASE_STATEMENT_TIMEOUT_MS = 5_000
DEFAULT_DATABASE_LOCK_TIMEOUT_MS = 3_000
# A transaction left open and idle (a bug) is ended after this.
DEFAULT_DATABASE_IDLE_IN_TRANSACTION_MS = 30_000
DEFAULT_DATABASE_CONNECT_TIMEOUT_SECONDS = 5
# Waiting for a free connection of the pool.
DEFAULT_DATABASE_POOL_TIMEOUT_SECONDS = 5

MIN_SECRET_KEY_LENGTH = 32

DEV_SECRET_KEY = "development-only-secret-key-not-for-real-use"
TEST_SECRET_KEY = "testing-only-secret-key-not-for-real-use!!"
