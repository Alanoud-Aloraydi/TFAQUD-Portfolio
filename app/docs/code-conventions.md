# Code conventions — `app`

The rules every change to the Flutter client follows. `tool/check_structure.dart`
enforces the ones that can be checked mechanically, and runs in CI
(`.github/workflows/ci.yml`).

## 1. One responsibility per file

A file holds one thing and is named after it. A file that needs the word "and"
to be described holds two things.

- One public widget per file, named like the file:
  `dose_timing_badge.dart` holds `DoseTimingBadge`.
- A private helper widget (`_Row`, `_Card`) stays in the file only while it is
  used by that file alone **and** the file stays within the size limit.
  Otherwise it becomes a file of its own under `widgets/`.
- A page builds a tree out of widgets; it does not declare them.

`features/medications/presentation/widgets/` is the reference: thirty files,
one widget each.

## 2. Size limits

| Scope | Limit |
|---|---|
| `presentation/` (pages, widgets, cubits) | 70 lines |
| any other file | 120 lines |

The limit is on responsibilities, not on lines: a file at 65 lines doing two
jobs still gets split. Exempt, because splitting them makes them worse:

- Generated files: `*.g.dart`, `*.freezed.dart`, `*.config.dart`.
- Lookup tables with one entry per line: `core/constants/app_icons.dart`.
- Design-system token files: one `abstract final class` of constants.

An exemption is recorded in `tool/structure_baseline.txt` with its reason. A
new file never joins that list.

## 3. Layers

```text
presentation  ->  domain  ->  data
```

- **presentation** (widget, page, cubit) may import `domain` only. A cubit
  calls a use case; it never sees a repository implementation, a data source,
  a model, or Dio.
- **domain** imports nothing from `data` or `presentation`. It declares the
  entities, the repository interfaces, and the use cases.
- **data** implements the domain repository interfaces and owns the models and
  the data sources.

Every feature has the same shape:

```text
features/<feature>/
  data/datasources/      <feature>_remote_data_source.dart
  data/models/           <thing>_model.dart
  data/repositories/     <feature>_repository_data.dart
  di/                    <feature>_di.dart
  domain/entities/       <thing>.dart
  domain/repositories/   <feature>_repository_domain.dart
  domain/use_cases/      <feature>_use_case.dart
  presentation/cubit/    <thing>_cubit.dart, <thing>_state.dart
  presentation/pages/    <thing>_page.dart
  presentation/widgets/  <thing>.dart
```

`features/medications` and `features/circles` follow it; new work matches them.

## 4. State

`flutter_bloc` with `Cubit` only, never `Bloc` with events. One cubit per
screen concern, its state in its own file beside it. State classes are
immutable and extend `Equatable`. A cubit returns `Result` from
`multiple_result`; it does not throw across layers.

Dependencies come from `get_it` (`GetIt.I<T>()`), registered by the feature's
`di/<feature>_di.dart`. A widget does not reach into `GetIt` except at the
point where it creates a `BlocProvider`.

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
