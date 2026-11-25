# Code conventions — `app`

The rules every change to the Flutter client follows. `tool/check_structure.dart`
enforces the ones that can be checked mechanically, and runs in CI
(`.github/workflows/ci.yml`).

## 1. Files

A file holds code that is really connected, and is named after its main
class.

- Keep together what changes together: a class and its state, a widget and
  the small widgets only it uses, a data source and the models it reads.
- Never join code just to have fewer files. Two classes share a file only
  when one exists to serve the other.
- A helper used by several files lives in its own file, beside them.
- Code of different layers never shares a file (see §3).

## 2. Size limit

Aim for about 200 lines per file; never more than 300 (generated files
excepted: `*.g.dart`, `*.freezed.dart`, `*.config.dart`). A class is not cut
into mixins to meet the limit: a file that outgrows it holds two jobs, and
is split by meaning.

## 3. Layout and layers

The layout follows Cleany (feature-based clean architecture):

```text
lib/
  main.dart                  starts the app: bootstrap(), then runApp
  app/
    app.dart                 the MaterialApp
    bootstrap.dart           everything ready before the first frame
    di/injection.dart        configureDependencies(): calls every feature
    router/                  the GoRouter and the shared route helpers
    services/                app-wide services (reminders, notifications, push)
  core/                      shared code: network, errors, storage,
                             localization, theme, constants, utils, widgets
  features/<feature>/
    data/datasources/        API and device data sources
    data/models/             JSON models
    data/repositories/       <feature>_repository_impl.dart
    domain/entities/         plain Dart classes
    domain/repositories/     <feature>_repository.dart (the contract)
    domain/usecases/         <feature>_use_case.dart
    presentation/cubit/      cubits, their states, presentation logic
    presentation/pages/      one page per screen
    presentation/widgets/    the widgets of the pages
    di/                      <feature>_dependencies.dart
    routing/                 <feature>_routes.dart
```

```text
presentation  ->  domain  <-  data
```

- **presentation** imports `domain` only: a cubit calls a use case; it never
  sees a repository implementation, a data source, a model, or Dio.
- **domain** imports nothing from `data` or `presentation`.
- **data** implements the domain contracts and owns models and data sources.

## 4. State and dependencies

`flutter_bloc` with `Cubit` only. State classes are immutable and extend
`Equatable`. Repositories and use cases return `Result` from
`multiple_result`; they do not throw across layers.

Dependencies come from `get_it`. Each feature registers its own in
`di/<feature>_dependencies.dart`
(`void register<Feature>Dependencies(GetIt getIt)`), and
`app/di/injection.dart` calls them all once at start-up. A widget reaches
into `GetIt` only where it creates a `BlocProvider`.

## 5. Comments

A comment says what the code cannot. Short, direct, present tense.

Write one when there is a reason, a rule, or a consequence that is not visible
in the code:

```dart
/// Where a dose stands against its time: upcoming, due, late, or not
/// recorded. A missed dose of today or yesterday still says «غير مسجلة»,
/// because it is not proof the dose was skipped.
```

Do not restate the declaration:

```dart
/// Renders the circle content element of circle tab screen.   // delete this
class _CircleContent extends StatelessWidget {
```

- A doc comment on a public class or member, where it adds something.
- No comment that repeats the name.
- No section banners, no `// ---`, no commented-out code, no change history.
- Arabic interface text inside a comment goes in «guillemets».

## 6. Format and analysis

`dart format` with the default 80-column width decides the layout; it is not a
matter of taste. `flutter analyze` must be clean — no new `// ignore:`
without a comment giving the reason.

Explicit types on fields, parameters, and return types. `final` by default.

## 7. Tests

A change to a cubit comes with a cubit test. A change to a widget's rendering
comes with a widget test using `test/support/widget_harness.dart`. Golden
images are made on Windows (see `README.md`); a change to the design system
updates `test/core/goldens/`.

## 8. Before pushing

```text
dart format lib test
flutter analyze
dart run tool/check_structure.dart
flutter test
```
