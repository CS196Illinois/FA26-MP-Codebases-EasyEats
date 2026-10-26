import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:easyeats/main.dart';
import 'package:easyeats/pages/favorites_page.dart';
import 'package:easyeats/pages/history_page.dart';

void main() {
  testWidgets('shows the sign in screen when nobody is logged in',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    // Wait past the splash screen delay
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
  });

  testWidgets('history page asks to log in when nobody is logged in',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MaterialApp(home: HistoryPage()));
    await tester.pumpAndSettle();

    expect(find.text('Meal History'), findsOneWidget);
    expect(find.text('Please log in first'), findsOneWidget);
  });

  testWidgets('favorites page asks to log in when nobody is logged in',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MaterialApp(home: FavoritesPage()));
    await tester.pumpAndSettle();

    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Please log in first'), findsOneWidget);
  });
}
