import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mol_app/main.dart';

void main() {
  testWidgets('App renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const MolApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
