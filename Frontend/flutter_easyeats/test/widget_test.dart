import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easyeats/pages/dining_halls.dart';
import 'package:easyeats/pages/favorites_page.dart';
import 'package:easyeats/services/user_service.dart';

void main() {
  testWidgets('Tapping Favorites opens FavoritesPage', (WidgetTester tester) async {
    // FavoritesPage pops itself when nobody is logged in.
    await UserService.setCurrentUser(1, null);

    await tester.pumpWidget(const MaterialApp(home: MainPage()));
    expect(find.byType(FavoritesPage), findsNothing);

    await tester.tap(find.text('Favorites'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(FavoritesPage), findsOneWidget);
  });

  testWidgets('Tapping History shows Coming soon', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainPage()));

    await tester.tap(find.text('History'));
    await tester.pump();

    expect(find.text('Coming soon'), findsOneWidget);
  });
}
