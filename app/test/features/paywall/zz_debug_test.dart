import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_scope.dart';

void main() {
  testWidgets('zz sem dump2', (tester) async {
    await setUpTestScope();
    await pumpAppRoute(tester, '/paywall');
    final owner = tester.binding.pipelineOwner.semanticsOwner;
    final dump =
        owner?.rootSemanticsNode?.toStringDeep() ?? 'no semantics tree';
    final lines = dump.split('\n');
    final start = lines.indexWhere((l) => l.contains('Subscription'));
    debugPrint('SEM:\n${lines.sublist(start - 8, start + 14).join('\n')}');
    await disposeApp(tester);
  });
}
