# TFAQUD mobile application

Flutter client of TFAQUD, a care-circle application. The interface is Arabic only (right-to-left). The target platform is iPhone (iOS). The `android` folder is kept only to run the application on an Android emulator during development.

The client communicates with the Flask API under the `/api/v1` prefix (see [`../backend/README.md`](../backend/README.md)).

## Requirements

- Flutter 3.47 (stable) with Dart 3.13 or later. The SDK constraint is declared in `pubspec.yaml`.
- A Mac with Xcode to build for iOS or to use the iOS simulator. Static analysis and the tests run on Windows.
- A running instance of the API for any feature that calls it.

## Setup

```text
flutter pub get
copy .env.example .env
```

Set `API_BASE_URL` in `.env` to the address of the API, without the `/api/v1` prefix. The file is read at start-up by `flutter_dotenv` (`lib/app/bootstrap.dart`), is bundled as an application asset, and is excluded from version control. It must not contain secrets.

## Run

```text
flutter run
```

In debug mode the route `/gallery` shows the shared components and a `GET /health` button that checks the connection to the API.

## Analysis and tests

```text
flutter analyze
flutter test
```

The tests cover the token handling (header rules, renewal on expiry, retry once, session end), the mapping of API errors to failures, and the application shell.

## Structure

The app follows the Cleany layout (feature-based clean architecture). The
full rules are in `docs/code-conventions.md`.

```text
lib/
  main.dart      starts the app
  app/           bootstrap, dependency injection (get_it), router, app services
  core/          network, errors, storage, localization, theme, constants,
                 utils, shared widgets
  features/<feature>/
    data/        datasources, models, repositories (implementations)
    domain/      entities, repositories (contracts), usecases
    presentation/ cubit, pages, widgets
    di/          the feature's get_it registrations
    routing/     the feature's routes
assets/
  translations/  ar.json
test/
```

There is no code generation: dependencies are registered by hand in each
feature's `di/<feature>_dependencies.dart`.

## Authentication handling

- The access token is attached to every request except `/health` and `/auth/refresh`.
- When the API answers `401` with the code `access_token_expired`, the client requests a new access token with the stored refresh token and retries the original request once.
- The codes `missing_token`, `invalid_token`, `session_revoked` and `invalid_refresh_token` end the session: the tokens are removed and the `sessionEnded` stream emits.
- Tokens are kept in the platform secure storage (Keychain on iOS).
- The refresh token has no end date: only a sign-out ends the session. iOS keeps the Keychain when the app is deleted, so the first start of a new install takes the old tokens out and signs that session out on the server (`lib/app/services/fresh_install.dart`). The server also signs out a phone whose app Apple says was deleted.
- Calendar sync puts its events in the app's own «تفقُد» calendar. Signing out deletes that calendar with all its events, and repeating events repeat only two weeks ahead (renewed while the app is used), so after the app is deleted their alerts stop within two weeks.

## Status

Sprint 0 foundation. The sign-in screens are not implemented yet, so `sessionEnded` is not connected to navigation. The Today, Plan, Record and Circle tabs are placeholders.