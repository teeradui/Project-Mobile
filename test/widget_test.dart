// Basic Flutter widget test for Smart Kitchen Assistant

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_project/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:mobile_project/providers/grocery_provider.dart';

void main() {
  testWidgets('Smart Kitchen App initializes correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => GroceryProvider(),
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    // Verify that the app title appears
    expect(find.text('Smart Kitchen'), findsOneWidget);

    // Verify that the budget overview section exists
    expect(find.text('Budget Overview'), findsOneWidget);
  });

  testWidgets('Voice record button is present', (WidgetTester tester) async {
    // Build our app with provider
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => GroceryProvider()..initialize(),
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    // Verify that the "Hold to Speak" button is present
    expect(find.text('Hold to Speak'), findsOneWidget);
  });

  testWidgets('Empty state displays correctly', (WidgetTester tester) async {
    // Build our app with provider
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => GroceryProvider()..initialize(),
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    // Verify empty state message
    expect(find.text('No items yet'), findsOneWidget);
  });
}
