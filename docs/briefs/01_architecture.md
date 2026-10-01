ROLE: Flutter Architect (sub-agent). Working dir = the Nestling repo root (current directory). Flutter 3.47.5 / Dart 3.13. The app was created with `flutter create` at `app/` and already has: flutter_bloc, bloc, equatable, go_router, get_it, provider, flutter_svg, google_fonts, lottie, rive (+ dev: bloc_test, mocktail, very_good_analysis). Assets are in app/assets/{icons,illustrations,images,brand,animations}. Product spec: docs/DESIGN_SPEC.md (30 screens; read §4 navigation map and §5 screen list). Design PNGs: design/screens/light/*.png.

TASK 1 — write `docs/ARCHITECTURE.md` (concise, with ASCII tree + rules):
- Feature-first. State management: BLoC (flutter_bloc). Routing: go_router. DI: get_it. `provider` is used only for app-wide lightweight state exposed to the widget tree (ThemeMode controller and AppMode parent/kid) — BLoCs are provided with BlocProvider.
- Per feature, EXACTLY these folders, nothing more:
  features/<feature>/
    data/            -> models (fromJson/toJson) + <feature>_repository_impl.dart (+ an in-memory/fake data source for now)
    domain/          -> entities + abstract <feature>_repository.dart ONLY (no use-case classes, no extra folders)
    presentation/
      bloc/          -> <x>_bloc.dart, <x>_event.dart, <x>_state.dart
      views/         -> full screens (one per route)
      widgets/       -> feature-private widgets
    <feature>_di.dart      -> `void register<Feature>(GetIt sl)` registering repository + blocs (factory)
    <feature>_routes.dart  -> `List<RouteBase> <feature>Routes` + route name/path constants
    <feature>.dart         -> feature barrel exporting di + routes (+ public views)
- App shell: lib/app/app.dart (MaterialApp.router with light/dark themes from the design system), lib/app/di.dart (outer barrel: `Future<void> configureDependencies()` calling every register<Feature>), lib/app/router.dart (outer barrel: GoRouter composing every <feature>Routes, ShellRoute/StatefulShellRoute for the parent tab bar Today/Quests/Money/Family, redirect guard for kid mode → parental gate), lib/main.dart.
- lib/core/: design_system/ (built by another agent — leave a placeholder `design_system.dart` barrel only), and nothing else unless essential (e.g. core/constants). No `utils` dumping ground.
- Features (map every screen): onboarding (P01,P02), auth (P03), privacy_consent (P04), family (P05, P15), pocket_money (P06, P12, P13), paywall (P07), parental_gate (P17), today (P08, P08b), quests (P09, P10), approvals (P11), rewards (P14), settings (P16), kid_home (K01, K02, K03, K03b, K04, K05), pip (K06, K07), kid_shop (K08), kid_jar (K09, K10), badges (K11), design_system_gallery (dev-only showcase route `/design-system`).
- Include a table: route path → view → feature → bloc.
TASK 2 — scaffold it for real inside app/lib: create every folder and file above with minimal compiling code: each feature has its entity, abstract repo, impl with fake in-memory data using the spec's UK sample data (Sarah, James, Maya 9, Leo 6, Biscuit; Maya 120 coins, owed £4.20, Lego goal £15.50/£24.99), one bloc with events/states (equatable), each view is a placeholder Scaffold titled with the screen id + name, wired to its bloc via BlocProvider(create: (_) => sl<...>()). Initial route for now: `/design-system`.
- Use `package:nestling/...` imports. Replace app/lib/main.dart and the default widget test (test/widget_test.dart) with a smoke test that pumps the app.
- analysis_options.yaml: include very_good_analysis, but disable `public_member_api_docs` and `lines_longer_than_80_chars`.
TASK 3 — run in app/: `dart format .`, `flutter analyze` (MUST be 0 errors, 0 warnings, 0 infos — fix everything, never use ignore comments), `flutter test`. Repeat until clean.
FINAL REPLY: the tree (depth 4 of lib/), analyze + test output tail, and any decisions you made.
