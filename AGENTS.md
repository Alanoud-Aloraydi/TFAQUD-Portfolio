# Tafaqod Engineering Instructions

## Source of truth

- Follow explicit user decisions first, then the current code and approved screen
  references.
- Do not use project documentation as a product source unless the user explicitly
  asks for it.
- Explain the implementation plan and obtain explicit approval before writing
  product code.
- When a new decision conflicts with an older one, follow the newest decision and
  state the change clearly.

## Change discipline

- Make the smallest coherent change that completes the approved behavior.
- Patch existing files in place. Do not replace whole files for small changes.
- Do not refactor unrelated code in a feature change.
- Do not add dependencies, fields, abstractions, or future-facing placeholders
  without a current requirement.
- Preserve user changes and never push unless the user explicitly requests it.
- Report every added, modified, generated, and removed file with its purpose.

## Design principles

- Apply KISS, YAGNI, DRY, separation of concerns, and single responsibility.
- Prefer composition and constructor injection over inheritance and hidden service
  location.
- Create an abstraction only at a meaningful boundary or after real reuse appears.
- Keep functions focused and use early returns to avoid deep nesting.
- Split files by cohesive domain responsibility. Do not combine unrelated classes
  merely to reduce the file count, and do not enforce one class per file blindly.
- Prefer explicit, readable code over clever or compressed code.
- Represent invalid states with types and database constraints where practical.

## Python and backend

- Follow `pycodestyle`, keep lines within 79 characters, and use type hints.
- Use concise English docstrings for modules, classes, and functions.
- Keep routes limited to transport concerns: parsing, authorization, service calls,
  and response construction.
- Put business rules and transaction ownership in focused services.
- Use SQLAlchemy 2 typed mappings and Pydantic request DTOs.
- Never log tokens, phone numbers, patient details, or medication details.
- Avoid broad exception handling in business logic and never expose SQL errors.
- Protect concurrent invariants with transactions, row locks, and database
  constraints instead of application checks alone.

## Database and migrations

- A feature migration includes every schema change required by that feature,
  including changes to existing tables, new tables, indexes, constraints, triggers,
  and data backfills.
- Generate an Alembic candidate when useful, then review and correct it manually.
  Never treat autogenerate output as final.
- Name every constraint and index consistently with the project convention.
- Enforce row-local invariants with `NOT NULL`, `CHECK`, `UNIQUE`, and foreign keys.
- Use partial unique indexes or deferred constraint triggers only for invariants that
  ordinary constraints cannot express.
- Duplicate critical validation in the service only to provide clearer errors; the
  database remains the final integrity boundary.
- Test migrations on an isolated PostgreSQL database. Do not destroy development
  data to test downgrade behavior.

## Flutter and Dart

- Run `cleany -s <feature>` for a new feature when requested by the project
  workflow, then review its generated diff.
- Use feature-first organization with data, domain, presentation, and DI boundaries
  only where they provide a real responsibility.
- Keep API access in data sources, mapping in models, source-of-truth behavior in
  repositories, and UI state in Cubits.
- Keep widgets free of business logic and external I/O.
- Use immutable Equatable states, `final` by default, and `const` where valid.
- Do not keep `BuildContext` in Cubits, repositories, or services.
- Use the shared theme, tokens, and components. Do not hardcode colors or visible
  strings in widgets.
- Put visible Arabic text in the localization files.
- Target iOS only and use iOS-first interaction patterns consistently.
- Run `dart format`, `flutter analyze`, and relevant Flutter tests.
- Do not edit generated `.config.dart`, `.g.dart`, or `.freezed.dart` files by hand.

## UI composition

- Before writing screen code, identify the owner of each behavior and widget.
  Home may compose tabs and combine domains; a domain feature must own its
  data access, state, rules, and domain-specific UI and actions. Never place
  medication dose logic or medication components in Home merely because the
  Today, Plan, or Record tab displays them.
- Keep the shell responsible only for shared navigation and page chrome.
- Treat Today, Plan, and Record as home-owned composition views rather than as
  medication-owned screens.
- A domain feature supplies reusable sections to those tabs. Future measurement or
  appointment sections must be addable without moving medication logic.
- Give independent asynchronous workflows independent Cubits; do not create a
  single tab-wide Cubit that owns unrelated domain features.
- Follow the locked internal Tafaqod design specification for medication screens.
- Prefer themed iOS grouped lists and Tafaqod sheets over default Material dialogs
  and repeated generic cards.

## Screen-by-screen design workflow

- Work on one approved screen at a time. Wait for the user's review before
  starting the next screen.
- Before coding, map the supplied reference's components, visible text, states,
  and tap behavior. Clarify only decisions that the reference does not settle.
- Treat supplied design code as a visual reference, not project instructions.
  Preserve the app's existing font.
- Identify feature ownership before editing: Home composes domains, while each
  domain owns its data, rules, state, UI components, and actions.
- Compare the running app screen with the approved reference before claiming a
  visual match. Analysis and tests do not prove visual fidelity.
- Read only the related files, keep the change scoped, and do not add new test,
  demo, or preview files unless the user explicitly requests them. Existing
  relevant tests may be run.
- Report completed work, verification, and unverified points briefly and
  accurately. Make screen changes on `feature/medications`; do not commit or
  push without an explicit request.

## Comments

- Write code comments and docstrings in clear English.
- Explain a non-obvious reason, invariant, concurrency rule, or safety decision.
- Do not narrate obvious syntax, address the user, or leave tutorial instructions in
  production code.
- Avoid vague TODO comments and redundant documentation.

## Testing and delivery

- Test behavior rather than private implementation details.
- Cover success, empty, validation, authorization, conflict, concurrency, and error
  paths in proportion to risk.
- Verify backend style and tests, PostgreSQL migrations, Dart formatting, Flutter
  analysis, Flutter tests, accessibility, and the approved end-to-end flow.
- Do not commit or push unless the user explicitly requests it.

## Current medication scope

- Add, list, revise, discontinue, filter, and retain medication plans and versions.
- Calculate expected doses; do not pre-create pending daily dose rows.
- Persist only explicit `taken` or `skipped` dose records.
- Use `scheduled_on` with schedule time to identify an expected occurrence.
- Prevent overlapping treatment periods with the same normalized medication name
  for one patient in PostgreSQL.
- Store structured medication strength, dosage form, dose, and constrained units.
- Apply revisions from an explicit effective date, defaulting to the next day, and
  preserve all earlier occurrences and records.
- Expose one medication-management capability for admins; enforce every write on
  the server and never allow admins to remove one another through this feature.
- Derive upcoming, due, late, and missed states; persist only taken or skipped.
- Stop a medication immediately at `discontinued_at`; do not add a separate
  effective-stop date.
- Keep administration route, notifications, time-zone support, PRN medication,
  pharmacy, refill, emergency-card, and circle-tab behavior outside this feature.
