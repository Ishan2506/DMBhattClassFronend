import 'dart:math';

class MatchingUtils {
  /// Returns the match percentage (0.0 to 1.0) of spoken text against the actual answer.
  static double getMatchScore(String spokenText, String actualAnswer) {
    if (spokenText.isEmpty || actualAnswer.isEmpty) return 0.0;

    final normalizedSpoken = spokenText.toLowerCase().trim();
    // Filter out very short words from spoken text to focus on content
    final spokenWords = normalizedSpoken.split(RegExp(r'\s+')).where((w) => w.length > 1).toList();
    
    final possibleAnswers = actualAnswer.split('|').map((e) => e.trim().toLowerCase()).toList();

    double maxScore = 0.0;

    for (var answer in possibleAnswers) {
      if (normalizedSpoken == answer) return 1.0;

      // Stop words to filter out before weight calculation
      final stopWords = {
        'a', 'an', 'the', 'is', 'are', 'was', 'were', 'am', 'been', 'being',
        'in', 'on', 'at', 'to', 'for', 'with', 'by', 'of', 'from',
        'i', 'you', 'he', 'she', 'it', 'we', 'they', 'my', 'his', 'her',
        'that', 'and', 'has', 'have', 'had', 'do', 'does', 'did', 'but', 'because', 'their',
        'છે', 'હતું', 'હતા', 'નું', 'ની', 'નો', 'ના', 'માં', 'થી', 'ને', 'અને', 'પણ', 'તરીકે', 'કહે'
      };

      // Simple punctuation removal that's safe for all languages
      final sanitizedAnswer = answer.replaceAll(RegExp(r'[,.!?;:()\[\]"]'), '');

      final actualKeywords = sanitizedAnswer
          .split(RegExp(r'\s+'))
          .where((w) {
            final cleaned = w.trim();
            return cleaned.isNotEmpty && !stopWords.contains(cleaned);
          })
          .toList();

      if (actualKeywords.isEmpty) {
        // Fallback: If no keywords (very short answer), check for direct inclusion
        if (normalizedSpoken.contains(sanitizedAnswer)) return 1.0;
        continue;
      }

      int matchCount = 0;
      for (final keyword in actualKeywords) {
        bool keywordMatched = false;
        
        // 1. Check for exact containment in the whole string (covers suffixes often)
        if (normalizedSpoken.contains(keyword)) {
          keywordMatched = true;
        } else {
          // 2. Fuzzy match against each spoken word
          for (final spokenWord in spokenWords) {
            // Check similarity (lowered to 0.7 for more leniency)
            if (_calculateSimilarity(keyword, spokenWord) >= 0.7) {
              keywordMatched = true;
              break;
            }
            // 3. Prefix match for longer words (handles create vs creating)
            if (keyword.length >= 5 && spokenWord.length >= 5) {
              if (keyword.substring(0, 5) == spokenWord.substring(0, 5)) {
                keywordMatched = true;
                break;
              }
            }
          }
        }


        if (keywordMatched) {
          matchCount++;
        }
      }

      final matchScore = matchCount / actualKeywords.length;
      if (matchScore > maxScore) {
        maxScore = matchScore;
      }
    }

    return maxScore;
  }

  /// Calculates similarity between two strings (0.0 to 1.0)
  static double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    
    int distance = _levenshteinDistance(s1, s2);
    int maxLength = max(s1.length, s2.length);
    return 1.0 - (distance / maxLength);
  }

  /// Calculates Levenshtein Distance between two strings
  static int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v0[s2.length];
  }

  static bool isAnswerCorrect(String spokenText, String actualAnswer) {
    // Making it more lenient (0.5 instead of 0.6) to ensure near-correct concepts are passed
    return getMatchScore(spokenText, actualAnswer) >= 0.5;
  }
}
