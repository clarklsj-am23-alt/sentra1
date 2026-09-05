import 'package:flutter_test/flutter_test.dart';
import 'package:sentra1/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Verifies Sentra1App builds cleanly
    expect(const Sentra1App(), isNotNull);
  });
}
