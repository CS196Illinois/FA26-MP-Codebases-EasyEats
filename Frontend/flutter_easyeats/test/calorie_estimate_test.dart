import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easyeats/pages/questionnaire_screen.dart';

void main() {
  group('estimateCalories', () {
    test('female, losing weight', () {
      expect(
        estimateCalories(goal: 'Losing weight', sex: 'Female', age: 20,
            heightFeet: 5, heightInches: 6, weight: 140),
        1455,
      );
    });

    test('male, gaining weight', () {
      expect(
        estimateCalories(goal: 'Gaining weight', sex: 'Male', age: 20,
            heightFeet: 5, heightInches: 10, weight: 170),
        2758,
      );
    });

    test('"Other" falls between male and female', () {
      int est(String sex) => estimateCalories(goal: 'Becoming fit', sex: sex,
          age: 20, heightFeet: 5, heightInches: 8, weight: 150);
      expect(est('Other'), greaterThan(est('Female')));
      expect(est('Other'), lessThan(est('Male')));
    });

    test('absurd input is clamped', () {
      expect(
        estimateCalories(goal: 'Losing weight', sex: 'Female', age: 90,
            heightFeet: 1, heightInches: 0, weight: 1),
        1200,
      );
    });
  });

  testWidgets('cannot continue with height but no weight', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: QuestionnaireScreen(userId: 1)),
    );

    Future<void> next() async {
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }

    ElevatedButton button() =>
        tester.widget<ElevatedButton>(find.byType(ElevatedButton));

    await tester.tap(find.text('Losing weight'));
    await tester.pump();
    await next();
    await tester.tap(find.text('Female'));
    await tester.pump();
    await next();
    await tester.enterText(find.widgetWithText(TextField, 'Age'), '20');
    await tester.pump();
    await next();

    await tester.enterText(find.widgetWithText(TextField, 'Feet'), '5');
    await tester.pump();
    expect(button().onPressed, isNull);

    await tester.enterText(find.widgetWithText(TextField, 'Weight'), '140');
    await tester.pump();
    expect(button().onPressed, isNotNull);
  });
}
