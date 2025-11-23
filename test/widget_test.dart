import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fog_cast_app/main.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FogCastApp(),
      ),
    );

    expect(find.byType(FogCastApp), findsOneWidget);
  });
}
