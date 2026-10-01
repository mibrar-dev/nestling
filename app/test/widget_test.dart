import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/di.dart';

void main() {
  testWidgets('App launches to the design system gallery', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await configureDependencies();
    await tester.pumpWidget(const NestlingApp());
    await tester.pumpAndSettle();
    expect(find.text('Design system'), findsOneWidget);
  });
}
