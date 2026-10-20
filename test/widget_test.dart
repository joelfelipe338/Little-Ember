import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:little_ember/app.dart';

void main() {
  testWidgets('App renderiza sem erros', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: LittleEmberApp()),
    );
    expect(find.text('Little Ember'), findsOneWidget);
  });
}
