import 'package:flutter_test/flutter_test.dart';
import 'package:maquitrace/main.dart';

void main() {
  testWidgets('MaquiTrace smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaquiTraceApp());
    expect(find.byType(MaquiTraceApp), findsOneWidget);
  });
}
