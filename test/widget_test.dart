import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ultimatetetris/main.dart';
import 'package:ultimatetetris/providers/game_state.dart';

void main() {
  testWidgets('Game renders score and level', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => GameState(),
        child: const TetrisApp(),
      ),
    );

    expect(find.text('SCORE'), findsOneWidget);
    expect(find.text('LEVEL'), findsOneWidget);
  });
}
