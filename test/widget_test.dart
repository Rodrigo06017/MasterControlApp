import 'package:flutter_test/flutter_test.dart';
import 'package:master_control_app/main.dart';

void main() {
  testWidgets('MasterControlApp loads properly and displays title', (WidgetTester tester) async {
    await tester.pumpWidget(const MasterControlApp());
    expect(find.text('MANDO JUEGOS'), findsOneWidget);
    expect(find.text('PELÍCULAS / MEDIA'), findsOneWidget);
  });
}
