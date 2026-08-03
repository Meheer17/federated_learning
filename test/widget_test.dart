import 'package:federated_chat/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FedChatApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FedChatApp()));
    expect(find.byType(FedChatApp), findsOneWidget);
  });
}
