import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/src/widgets/student_card_item.dart';
import 'package:gym_app/src/models/user_model.dart';

void main() {
  testWidgets('StudentCardItem displays student info and buttons', (WidgetTester tester) async {
    // 1. Arrange
    final student = User(
      id: '123',
      email: 'juan@test.com',
      role: 'student',
      firstName: 'Juan',
      lastName: 'Perez',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudentCardItem(
            student: student,
            onDelete: () {},
          ),
        ),
      ),
    );

    // 2. Act
    final nameFinder = find.text('Juan Perez');
    final emailFinder = find.text('juan@test.com');
    final assignButtonFinder = find.text('Asignar Plan');
    final plansButtonFinder = find.text('Planes');
    final deleteIconFinder = find.byIcon(Icons.delete_outline);

    // 3. Assert
    expect(nameFinder, findsOneWidget);
    expect(emailFinder, findsOneWidget);
    expect(assignButtonFinder, findsOneWidget);
    expect(plansButtonFinder, findsOneWidget);
    expect(deleteIconFinder, findsOneWidget);
  });
}
