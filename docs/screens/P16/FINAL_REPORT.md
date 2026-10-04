# P16 Settings — final fixes report

Scope: `4_review.md` findings 1–3 and 6 only. Feature code only
(`app/lib/features/settings/**`, `app/test/features/settings/**`).
No `app/lib/core/**` edits, no simulator, no `flutter clean`.

## 1. Move banner zones (major, finding 1)

`settings_view.dart`: `_MoveBanner` took only the device `zone` and
hard-coded `History keeps London times`. It now takes the stored family zone
too — `_MoveBanner(zone: state.pendingZone!, fromZone: state.familyZoneId)` —
and interpolates both short labels:

`History keeps {familyShort} times; future days follow {deviceShort}.`

`shortZoneLabel('Europe/London') == 'London'`, so the seeded default renders
the orchestrator sentence byte-for-byte (`settings_responsive_test.dart`
still green). New pins in `settings_final_fixes_test.dart`:

- family `Asia/Dubai` + device `Europe/London` →
  `History keeps Dubai times; future days follow London.`
- family `Asia/Dubai` + device `Asia/Karachi` →
  `History keeps Dubai times; future days follow Karachi.`
- seeded default (family London + device Dubai) unchanged.

## 2. Lock glyph colour (minor, finding 2)

`_LockHint`: `NestIcon(NestIcons.lock, color: tokens.ink2)` →
`tokens.ink`. `.lockhint` sets no `color`, inheriting `var(--ink)` from
`.screen` (`components.css:26`); the glyph is row text, not subtitle grey.
Pinned for both themes in `settings_final_fixes_test.dart`.

## 3. Chevron type (minor, finding 3)

`settingsChevron` was `NestType.h3` (Nunito 18 w800). `.list-trail`
(`components.css:119`) is Inter w600 ink-3 — 16 px on list rows, 15 px inside
`.linkrow` (`P16-settings.html:9`). Now:

- `settingsChevron` → Inter 16 w600 `ink-3`
  (`NestType.body(...).copyWith(fontWeight: w600)`)
- `settingsChevronSmall` → Inter 15 w600 `ink-3`
  (`NestType.bodySmallStrong`) for the subscription linkrow only.

Same centre/right edge within the ±2 px rule; glyph shape is now Inter.
Pinned for both themes (sizes 16 / 15, `ink-3`, zero tracking). Shared-token
follow-up stays in `SHARED_REQUEST.md`; `app/lib/core/**` untouched.

## 6. Static Family row semantics (minor, finding 6)

`SettingsRow` with `onTap == null` returned the bare row, so Sarah/James
folded into the Invite button's node. Now returns
`Semantics(container: true, child: row)` — plain container, no label, no
`excludeSemantics`, no `onTap`. Each static row is its own group; the
ACCESSIBILITY-ACTIONS rule is untouched.
`settings_a11y_test.dart`: Sarah/James leave `kP16Controls` (tappable only);
new test pins two distinct non-tappable nodes, empty tappable matches for
both, and an Invite node free of static copy.

## Gates

```
$ cd app && dart format .        # 565 files, 0 changed (final run)
$ flutter analyze                # No issues found!
$ flutter test --timeout 120s test/features/settings
                                 # +158: All tests passed!
$ flutter test --timeout 120s    # 3541 passed, ~2 skipped (K01/P12): All tests passed!
```

Commit: `P16: final fixes (move banner zones, lockhint, chevron, row semantics)`.

VERDICT: PASS
