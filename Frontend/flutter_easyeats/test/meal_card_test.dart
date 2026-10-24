import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easyeats/models/meal_entry.dart';
import 'package:easyeats/widgets/meal_card.dart';

MealEntry _sampleMeal() {
  return MealEntry(
    id: 1,
    userId: 1,
    mealType: 'Lunch',
    diningHall: 'Ikenberry',
    consumedAt: DateTime(2026, 10, 24, 12),
    foods: [],
    totals: NutritionTotals(
      calories: 650,
      protein: 40,
      fat: 20,
      carbs: 70,
      fiber: 5,
    ),
  );
}

void main() {
  testWidgets('MealCard shows the meal and a delete button',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MealCard(meal: _sampleMeal(), onDelete: () {})),
    ));

    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('650 cal'), findsOneWidget);
    expect(find.byTooltip('Delete meal'), findsOneWidget);
  });

  testWidgets('Tapping delete calls onDelete', (WidgetTester tester) async {
    var deleted = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MealCard(meal: _sampleMeal(), onDelete: () => deleted = true),
      ),
    ));

    await tester.tap(find.byTooltip('Delete meal'));
    expect(deleted, isTrue);
  });
}
