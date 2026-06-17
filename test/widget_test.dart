import 'package:flutter_test/flutter_test.dart';
import 'package:agile_project/main.dart';

void main() {
  testWidgets('AspiraNila role selection smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Trigger frame updates
    await tester.pumpAndSettle();

    // Verify that the role selection screen subtitle is present.
    expect(find.text('Suara Civitas Akademika Universitas Lampung'), findsOneWidget);
    
    // Verify that the multi-role buttons exist.
    expect(find.text('Mahasiswa'), findsOneWidget);
    expect(find.text('Dosen'), findsOneWidget);
    expect(find.text('Administrator'), findsOneWidget);
  });
}
