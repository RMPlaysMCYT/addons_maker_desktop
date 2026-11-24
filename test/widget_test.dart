import 'package:flutter_test/flutter_test.dart';

import 'package:addons_maker_desktop/main.dart';

void main() {
  testWidgets('renders the project welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const Application());

    expect(
      find.text('Hello, Welcome to Minecraft Addons Maker Ultimate!'),
      findsOneWidget,
    );
    expect(find.text('Open Project'), findsOneWidget);
  });
}
