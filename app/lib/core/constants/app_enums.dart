/// Defines the supported loading state values.
enum LoadingState { initial, loading, success, error }

/// Defines the supported network status values.
enum NetworkStatus { connected, disconnected, unknown }

/// Defines the supported state load user values.
enum StateLoadUser { local, remote }

/// Defines the supported auth status values.
enum AuthStatus { authenticated, unauthenticated, unknown }

/// Defines the supported languages enum values.
enum LanguagesEnum {
  ar,
  en;

  String get displayCode => name.toUpperCase();
  String get displayName {
    switch (name) {
      case 'ar':
        return "العربية";
      default:
        return "English";
    }
  }
}
