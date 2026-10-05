# Nestling Architecture

Feature-first Flutter app. BLoC for state, go_router for routing,
get_it for DI. `provider` exposes two app-wide controllers only
(ThemeMode, AppMode). BLoCs are provided with BlocProvider.

## Structure

```
lib/
|-- main.dart
|-- app/
|   |-- app.dart
|   |-- controllers.dart
|   |-- di.dart
|   `-- router.dart
|-- core/
|   `-- design_system/
|       `-- design_system.dart
`-- features/
    |-- onboarding/
    |   |-- onboarding.dart
    |   |-- onboarding_di.dart
    |   |-- onboarding_routes.dart
    |   |-- data/
    |   |   |-- models/
    |   |   |   `-- onboarding_step_model.dart
    |   |   |-- onboarding_fake_data_source.dart
    |   |   `-- onboarding_repository_impl.dart
    |   |-- domain/
    |   |   |-- entities/
    |   |   |   `-- onboarding_step.dart
    |   |   `-- onboarding_repository.dart
    |   `-- presentation/
    |       |-- bloc/
    |       |   |-- onboarding_bloc.dart
    |       |   |-- onboarding_event.dart
    |       |   `-- onboarding_state.dart
    |       |-- views/
    |       |   `-- *_view.dart (one per route)
    |       `-- widgets/
    |           `-- onboarding_placeholder_card.dart
    ├── onboarding/
    ├── auth/
    ├── privacy_consent/
    ├── family/
    ├── pocket_money/
    ├── paywall/
    ├── parental_gate/
    ├── today/
    ├── quests/
    ├── approvals/
    ├── rewards/
    ├── settings/
    ├── kid_home/
    ├── pip/
    ├── kid_shop/
    ├── kid_jar/
    ├── badges/
    ├── design_system_gallery/
```

Every feature follows the onboarding shape exactly.

## Per-feature contract

```
features/<feature>/
  data/            models (fromJson/toJson) + <feature>_repository_impl.dart
                   + <feature>_fake_data_source.dart (in-memory, UK sample data)
  domain/          entities + abstract <feature>_repository.dart ONLY
  presentation/
    bloc/          <feature>_bloc.dart, <feature>_event.dart, <feature>_state.dart
    views/         full screens, one per route
    widgets/       feature-private widgets
  <feature>_di.dart      void register<Feature>(GetIt sl): repository + blocs (factory)
  <feature>_routes.dart  List<RouteBase> <feature>Routes + name/path constants
  <feature>.dart         barrel exporting di + routes + public views
```

Rules:

- No use-case classes, no extra folders per feature.
- Entities are Equatable value objects; models extend entities with fromJson/toJson.
- One bloc per feature: `<Feature>LoadRequested` event, Status initial/loading/loaded/failure.
- Views are placeholder Scaffolds titled `<screen id> <name>`, wrapped in
  `BlocProvider(create: (_) => sl<...>()..add(...))` at the route level.
- All lib imports use `package:nestling/...`.
- No `utils` dumping ground. `lib/core` holds the design-system barrel only.

## App shell

- `lib/app/app.dart`: NestlingApp (MaterialApp.router, light/dark themes
  from the design system, MultiProvider for the two controllers).
- `lib/app/controllers.dart`: AppModeController (parent/kid) and
  ThemeModeController (extra file to avoid an app <-> router import cycle).
- `lib/app/di.dart`: `Future<void> configureDependencies()` calling every
  `register<Feature>`; controllers registered first as lazy singletons.
- `lib/app/router.dart`: GoRouter composing every `<feature>Routes`.
  StatefulShellRoute.indexedStack hosts the parent tab bar
  (Today/Quests/Money/Family). Tab roots live inside branches; every other
  route is top-level, so no path is registered twice. Redirect guard sends
  kid mode away from parent-only locations to the parental gate.
- `lib/main.dart`: ensureInitialized, configureDependencies, runApp.
- Initial route: `/`, resolved by the router redirect to the family's start
  screen (not onboarded → `/welcome`, onboarded parent → `/today`, onboarded
  kid → `/kid-home`; `INITIAL_ROUTE` overrides it). The design-system
  gallery, motion lab and pip lab are developer tools registered only in
  debug/profile builds (or with `--dart-define=DEV_ROUTES=1`).

## Screen coverage

- onboarding (P01, P02), auth (P03), privacy_consent (P04),
  family (P05, P15), pocket_money (P06, P12, P13), paywall (P07),
  parental_gate (P17), today (P08, P08b), quests (P09, P10),
  approvals (P11), rewards (P14), settings (P16),
  kid_home (K01, K02, K03, K03b, K04, K05), pip (K06, K07),
  kid_shop (K08), kid_jar (K09, K10), badges (K11),
  design_system_gallery (dev-only `/design-system`).

## Route table

| Route path | View | Feature | Bloc |
|---|---|---|---|
| `/welcome` | WelcomeView | onboarding | OnboardingBloc |
| `/value-tour` | ValueTourView | onboarding | OnboardingBloc |
| `/create-account` | CreateAccountView | auth | AuthBloc |
| `/privacy` | PrivacyConsentView | privacy_consent | PrivacyConsentBloc |
| `/add-children` | AddChildrenView | family | FamilyBloc |
| `/child-profile` | ChildProfileView | family | FamilyBloc |
| `/pocket-money-setup` | PocketMoneySetupView | pocket_money | PocketMoneyBloc |
| `/money` | MoneyLedgerView | pocket_money | PocketMoneyBloc |
| `/payout` | PayoutView | pocket_money | PocketMoneyBloc |
| `/paywall` | PaywallView | paywall | PaywallBloc |
| `/parental-gate` | ParentalGateView | parental_gate | ParentalGateBloc |
| `/today` | TodayView | today | TodayBloc |
| `/today-empty` | TodayEmptyView | today | TodayBloc |
| `/quest-editor` | QuestEditorView | quests | QuestsBloc |
| `/quests` | QuestLibraryView | quests | QuestsBloc |
| `/approvals` | ApprovalsView | approvals | ApprovalsBloc |
| `/rewards` | RewardsView | rewards | RewardsBloc |
| `/settings` | SettingsView | settings | SettingsBloc |
| `/who-is-playing` | ProfilePickerView | kid_home | KidHomeBloc |
| `/kid-pin` | KidPinView | kid_home | KidHomeBloc |
| `/kid-home` | KidHomeView | kid_home | KidHomeBloc |
| `/kid-home-done` | KidHomeDoneView | kid_home | KidHomeBloc |
| `/quest-detail` | QuestDetailView | kid_home | KidHomeBloc |
| `/quest-complete` | QuestCompleteView | kid_home | KidHomeBloc |
| `/pip` | PipNestView | pip | PipBloc |
| `/pip-evolution` | PipEvolutionView | pip | PipBloc |
| `/reward-shop` | RewardShopView | kid_shop | KidShopBloc |
| `/my-jar` | MyJarView | kid_jar | KidJarBloc |
| `/payout-day` | PayoutDayView | kid_jar | KidJarBloc |
| `/badges` | BadgesView | badges | BadgesBloc |
| `/design-system` | DesignSystemGalleryView | design_system_gallery | DesignSystemGalleryBloc |
