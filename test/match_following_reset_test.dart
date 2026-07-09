import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/match_following_game_screen.dart';

Widget _harness() => MaterialApp(
      home: MatchFollowingGameScreen(
        exerciseId: 'x',
        title: 'T',
        subject: 'S',
        pairsData: const [
          {'left': 'A1', 'right': 'B1'},
          {'left': 'A2', 'right': 'B2'},
        ],
      ),
    );

void main() {
  testWidgets('Reset clears matches, lines, and card state', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // No matches yet -> no clear (X) buttons.
    expect(find.byIcon(Icons.close), findsNothing);

    // Make a match.
    await tester.tap(find.text('A1'));
    await tester.pump();
    await tester.tap(find.text('B1'));
    await tester.pumpAndSettle();

    // A match now exists: exactly one X button is rendered.
    expect(find.byIcon(Icons.close), findsOneWidget,
        reason: 'a match should render its clear button');

    // Tap Reset.
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    // The match is gone: no X buttons remain.
    expect(find.byIcon(Icons.close), findsNothing,
        reason: 'Reset must clear all matches and rebuild the cards');
  });
}
