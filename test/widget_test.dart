import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chamma/app.dart';

void main() {
  testWidgets('App renderiza sem erros', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ChammaApp()),
    );
    expect(find.text('CHAMMA'), findsOneWidget);
  });
}
