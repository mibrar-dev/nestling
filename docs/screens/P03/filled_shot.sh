#!/usr/bin/env bash
# P03 filled-state capture (ORCHESTRATOR_NOTES.md QA item 3, open since
# iteration 2).
#
# The design PNGs show the FILLED state; the app correctly launches empty, so
# comparing the launch frame with the design compares two different states.
# `idb ui text` cannot be used here — its HID path needs SimulatorKit, which
# this machine's Xcode install does not ship — so the values are typed by a
# throwaway `flutter drive` target and the frame is captured with
# `IntegrationTestWidgetsFlutterBinding.takeScreenshot`.
#
# The target and driver are generated here and deleted on exit: they are a
# capture harness, not tests, and a permanent `*_test.dart` in the feature's
# test directory would be picked up by `flutter test` and by `flutter analyze`.
#
#   docs/screens/P03/filled_shot.sh [light|dark …]   # defaults to both
#
# Writes docs/screens/P03/ui/filled-<theme>.png. Never runs an interactive
# `flutter run`.
set -uo pipefail

UDID="${P03_SIM:-BC440E48-B3A3-43BC-971B-0EF5DB621874}"
THEMES="${*:-light dark}"
REPO="$(cd "$(dirname "$0")/../../.." && pwd)"
APP="$REPO/app"
UI="$REPO/docs/screens/P03/ui"
TARGET="$APP/test/features/auth/zz_filled_capture_target.dart"
DRIVER="$APP/test/features/auth/zz_filled_capture_driver.dart"
LOG="${TMPDIR:-/tmp}/p03_filled_drive.log"

cleanup() { rm -f "$TARGET" "$DRIVER"; }
trap cleanup EXIT
mkdir -p "$UI"

cat >"$DRIVER" <<'DART'
// Throwaway capture driver (written by docs/screens/P03/filled_shot.sh).
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot:
        (String name, List<int> bytes, [Map<String, Object?>? args]) async {
          final out = File('docs/screens/P03/ui/$name.png');
          out.parent.createSync(recursive: true);
          out.writeAsBytesSync(bytes);
          stdout.writeln('driver: wrote ${out.path}');
          return true;
        },
  );
}
DART

{
  echo "// Throwaway capture target (written by docs/screens/P03/filled_shot.sh)."
  cat <<'DART'
// P03's filled state: the design PNGs show it, the app launches empty.
//
// The values go in through the fields' controllers and the bloc, never by
// tapping — a tap focuses a field, the scroll view scrolls it into view, and
// the capture then shows a scrolled form with the password field under the
// CTA panel, which is a picture of an interaction rather than of the design.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nestling/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nestling/features/auth/presentation/bloc/auth_event.dart';
import 'package:nestling/features/auth/presentation/views/create_account_view.dart';

import '../../test_scope.dart';

const String _email = 'sarah@example.co.uk';
const String _password = 'hunter2hunter2hunter2';

Finder _input(String key) => find.descendant(
  of: find.byKey(ValueKey(key)),
  matching: find.byType(TextField),
);

Future<void> _fill(WidgetTester tester) async {
  tester.widget<TextField>(_input('p03_email')).controller!.text = _email;
  tester.widget<TextField>(_input('p03_password')).controller!.text = _password;
  BlocProvider.of<AuthBloc>(tester.element(find.byType(CreateAccountView)))
    ..add(const AuthEmailChanged(_email))
    ..add(const AuthPasswordChanged(_password));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('P03 filled state', (tester) async {
    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      if (const {'light', 'dark'}.difference(<String>{for (final t in THEMES) t}).isNotEmpty &&
          !THEMES.contains(theme == ThemeMode.light ? 'light' : 'dark')) {
        continue;
      }
      await setUpTestScope();
      await pumpAppRoute(tester, '/create-account', theme: theme);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await _fill(tester);
      expect(find.byType(CreateAccountView), findsOneWidget);
      stdout.writeln('P03-FILLED-READY $theme');
      await binding.takeScreenshot(
        'filled-${theme == ThemeMode.light ? 'light' : 'dark'}',
      );
      await disposeApp(tester);
    }
  });
}
DART
} >"$TARGET"

# The target reads the requested themes from the environment.
python3 - "$TARGET" "$THEMES" <<'PY'
import sys
path, themes = sys.argv[1], sys.argv[2].split()
s = open(path).read()
s = s.replace(
    "void main() {",
    "const List<String> THEMES = <String>[%s];\n\nvoid main() {" % ', '.join(
        "'%s'" % t for t in themes),
)
open(path, 'w').write(s)
PY

cd "$APP"
flutter drive \
  --driver=test/features/auth/zz_filled_capture_driver.dart \
  --target=test/features/auth/zz_filled_capture_target.dart \
  -d "$UDID" 2>&1 | tee "$LOG" | grep -E "P03-FILLED-READY|driver: wrote|All tests passed|Some tests"

grep -c "driver: wrote" "$LOG" >/dev/null || {
  echo "filled: no screenshot written — see $LOG" >&2
  exit 1
}
echo "filled: captures in $UI"