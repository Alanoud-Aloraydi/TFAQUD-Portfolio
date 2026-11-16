"""The error that keeps the server from starting with bad settings."""


class ConfigError(RuntimeError):
    """The settings are missing or unsafe. The app must not start."""
