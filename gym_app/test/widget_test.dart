import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_app/app.dart';
import 'package:gym_app/data/db/app_database.dart';
import 'package:gym_app/data/providers.dart';
import 'package:drift/native.dart';

void main() {
  testWidgets('shell mostra tab Palestra', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const GymApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Palestra'), findsWidgets);
    expect(find.text('Dieta'), findsOneWidget);
    expect(find.text('Spesa'), findsOneWidget);

    await db.close();
  });
}
