import 'package:drift/drift.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/features/onboarding/domain/entities/onboarding_step.dart';
import 'package:nestling/features/onboarding/domain/onboarding_repository.dart';

/// Drift-backed [OnboardingRepository].
class OnboardingRepositoryImpl implements OnboardingRepository {
  new({required this._db});

  final AppDatabase _db;

  @override
  Future<List<OnboardingStep>> getItems() => Future.value(_steps);

  @override
  Stream<List<OnboardingStep>> watchItems() => Stream.value(_steps);

  @override
  Stream<bool> watchComplete() {
    return _db.watchAppState().map((s) => s?.onboardingComplete ?? false);
  }

  @override
  Future<void> completeOnboarding() {
    return (_db.update(_db.appState)..where((a) => a.id.equals(1))).write(
      const AppStateCompanion(onboardingComplete: Value(true)),
    );
  }

  // The step-1 detail mirrors the design's typographic punctuation
  // (ORCHESTRATOR_NOTES 2) so the loaded copy matches the view's static
  // pre-load copy character by character.
  static const List<OnboardingStep> _steps = <OnboardingStep>[
    OnboardingStep(
      id: 'quests',
      title: 'Set quests in seconds',
      detail:
          'Pick from 40+ ready-made jobs like “Put the bins out” — or make '
          'your own.',
    ),
    OnboardingStep(
      id: 'pip',
      title: 'Pip grows as they help',
      detail: 'Every finished quest feeds Pip the bird, from egg to songbird.',
    ),
    OnboardingStep(
      id: 'money',
      title: 'Pocket money, sorted',
      detail: 'No bank card needed — we keep score, you pay your way.',
    ),
  ];
}
