"""The server's settings: `load_config` reads them from the environment and
refuses settings that are missing or unsafe with `ConfigError`.

Environments:
  development - local work. Configurable SMS, a default development secret.
  testing     - automated tests. Fake SMS only, a fixed secret key.
  staging     - the shared test server (TFQD-10, Render). Needs a real
                SECRET_KEY; logs the fake sender's codes when
                FAKE_SMS_LOG_CODES=true.
  production  - the real server. Needs a real SECRET_KEY, refuses the fake SMS
                sender and the in-memory session store.
"""

from app.config.errors import ConfigError
from app.config.settings import load_config

__all__ = ["ConfigError", "load_config"]
