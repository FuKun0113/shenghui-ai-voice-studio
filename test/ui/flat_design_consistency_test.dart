import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:voice_clone_app/src/ui/widgets/app_panel.dart';

void main() {
  testWidgets('icon badges render as line icons without colored blocks', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: IconBadge(icon: HugeIcons.strokeRoundedVoice)),
        ),
      ),
    );

    final decoratedBlocks = find.descendant(
      of: find.byType(IconBadge),
      matching: find.byType(DecoratedBox),
    );

    expect(decoratedBlocks, findsNothing);
  });
}
