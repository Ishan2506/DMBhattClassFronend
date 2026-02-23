import 'package:dm_bhatt_tutions/utils/matching_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MatchingUtils Tests', () {
    test('Exact match should return score 1.0', () {
      expect(MatchingUtils.getMatchScore('Solid', 'Solid'), 1.0);
    });

    test('Matter question keyword match (all keywords)', () {
      const answer = "Matter is anything that has mass and occupies space.";
      const spoken = "any thing has mass space occupies"; // Main words
      final score = MatchingUtils.getMatchScore(spoken, answer);
      // Keywords: matter, anything, mass, occupies, space (5)
      // Spoken: any thing, mass, space, occupies (4 matches with compact match)
      // Score: 4/5 = 0.8
      expect(score, greaterThanOrEqualTo(0.8));
    });

    test('States of matter match', () {
      const answer = "The three states of matter are solid, liquid and gas.";
      const spoken = "solid liquid gas";
      final score = MatchingUtils.getMatchScore(spoken, answer);
      // Keywords: three, states, matter, solid, liquid, gas (6)
      // Spoken matches: solid, liquid, gas (3)
      // Score: 3/6 = 0.5
      expect(score, greaterThanOrEqualTo(0.5));
    });

    test('Gujarati science match', () {
      const answer = "દ્રવ્યની ત્રણ અવસ્થાઓ ઘન, પ્રવાહી અને વાયુ છે.";
      const spoken = "ઘન પ્રવાહી વાયુ";
      final score = MatchingUtils.getMatchScore(spoken, answer);
      // Keywords: દ્રવ્યની, ત્રણ, અવસ્થાઓ, ઘન, પ્રવાહી, વાયુ (6)
      // Matches: ઘન, પ્રવાહી, વાયુ (3)
      // Score: 3/6 = 0.5
      expect(score, greaterThanOrEqualTo(0.5));
    });

    test('Partial match should return proportional score', () {
      const answer = "Solid|Liquid|Gas";
      expect(MatchingUtils.getMatchScore('solid', answer), 1.0);
    });

    test('Empty strings should return 0.0', () {
      expect(MatchingUtils.getMatchScore('', 'New Delhi'), 0.0);
      expect(MatchingUtils.getMatchScore('New Delhi', ''), 0.0);
    });
  });
}
