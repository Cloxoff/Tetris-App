import 'package:flutter_test/flutter_test.dart';
import 'package:tetris_mobile/main.dart';

void main() {
  testWidgets('Tetris app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TetrisApp());
    expect(find.text('TETRIS'), findsOneWidget);
    expect(find.text('СЧЁТ'), findsOneWidget);
    expect(find.text('РЕКОРД'), findsOneWidget);
  });
}
