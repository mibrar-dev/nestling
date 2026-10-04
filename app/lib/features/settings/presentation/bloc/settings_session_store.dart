/// Session-scoped P16 dismissal store (P16-B02).
///
/// `dismissedZones` outlives the route-scoped settings bloc: every
/// `/settings` visit builds a new bloc, but the ORCHESTRATOR_NOTES move
/// prompt shows "exactly once (until confirmed or dismissed for the
/// session)", so "Not now" dismissals live here — registered as a lazy
/// singleton in `registerSettings`, never in the database.
class SettingsSessionStore {
  new();

  /// Zones dismissed via "Not now" this session.
  final Set<String> dismissedZones = <String>{};
}
