import 'package:driver_workflow/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows separate driver and admin authentication routes', (
    tester,
  ) async {
    await tester.pumpWidget(const HaulFlowApp());
    expect(find.text('Driver sign in'), findsOneWidget);
    expect(find.text('Driver onboarding'), findsOneWidget);
    expect(find.text('Admin login'), findsOneWidget);
  });
}
