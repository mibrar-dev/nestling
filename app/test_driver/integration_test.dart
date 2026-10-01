// Driver half of the visual QA harness. `flutter drive` runs the test on the
// device; every `binding.takeScreenshot(...)` is buffered in the test report
// and handed to this file when the run ends. The PNGs are written to
// design/qa/sim/<RUN_LABEL>/, which is what tools/sim_shots.sh then turns into
// contact sheets.
//
// Note: this Flutter version has no `onScreenshot` parameter on
// `integrationDriver` (it survives only in integration_test_driver_extended,
// for web). The supported equivalent is the response data callback, so that is
// what pulls `reportData['screenshots']` out. `writeResponseOnFailure` is on so
// a run that dies half way through still leaves the shots it did take.
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() async {
  final label = _label(Platform.environment['RUN_LABEL']);
  final outDir = Directory('${Directory.current.path}/../design/qa/sim/$label')
    ..createSync(recursive: true);

  stdout.writeln('[qa] writing screenshots to ${outDir.path}');
  var count = 0;

  await integrationDriver(
    writeResponseOnFailure: true,
    responseDataCallback: (data) async {
      final shots = data?['screenshots'] as List<dynamic>?;
      for (final shot in shots ?? <dynamic>[]) {
        final map = Map<String, dynamic>.from(shot! as Map);
        final name = map['screenshotName']! as String;
        final bytes = (map['bytes']! as List<dynamic>).cast<int>();
        final file = File('${outDir.path}/$name.png')..writeAsBytesSync(bytes);
        count++;
        stdout.writeln('[qa] ${file.path} (${bytes.length} bytes)');
      }
    },
  );

  stdout.writeln('[qa] $count screenshots written to design/qa/sim/$label/');
}

String _label(String? raw) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) {
    return DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
  }
  return trimmed.replaceAll(RegExp('[^A-Za-z0-9._-]'), '-');
}
