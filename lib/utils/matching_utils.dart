class MatchingUtils {
  /// Returns the match percentage (0.0 to 1.0) of spoken text against the actual answer.
  static double getMatchScore(String spokenText, String actualAnswer) {
    if (spokenText.isEmpty || actualAnswer.isEmpty) return 0.0;

    final normalizedSpoken = spokenText.toLowerCase().trim();
    // Compact version for fuzzy matching (handles spaces correctly)
    final compactSpoken = normalizedSpoken.replaceAll(RegExp(r'\s+'), '');
    
    final possibleAnswers = actualAnswer.split('|').map((e) => e.trim().toLowerCase()).toList();

    double maxScore = 0.0;

    for (var answer in possibleAnswers) {
      if (normalizedSpoken == answer) return 1.0;

      // Stop words to filter out before weight calculation
      final stopWords = {
        'a', 'an', 'the', 'is', 'are', 'was', 'were', 'am', 'been', 'being',
        'in', 'on', 'at', 'to', 'for', 'with', 'by', 'of', 'from',
        'i', 'you', 'he', 'she', 'it', 'we', 'they', 'my', 'his', 'her',
        'that', 'and', 'has', 'have', 'had', 'do', 'does', 'did', 'but', 'because', 'their', 'of',
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
        if (normalizedSpoken.contains(answer.replaceAll(RegExp(r'[,.!?;:()\[\]"]'), ''))) {
          maxScore = 1.0;
        }
        continue;
      }

      int matchCount = 0;
      for (final keyword in actualKeywords) {
        final compactKeyword = keyword.replaceAll(' ', '');
        if (normalizedSpoken.contains(keyword) || compactSpoken.contains(compactKeyword)) {
          matchCount++;
        } else {
          // Fuzzy match for Gujarati suffixes: check if word starts with keyword
          // or keyword starts with word (handles 'દ્રવ્ય' vs 'દ્રવ્યની')
          if (keyword.length > 2) {
            bool fuzzyMatch = false;
            if (normalizedSpoken.contains(keyword.substring(0, keyword.length - 1))) fuzzyMatch = true; 
            if (fuzzyMatch) matchCount++;
          }
        }
      }

      final matchScore = matchCount / actualKeywords.length;
      if (matchScore > maxScore) {
        maxScore = matchScore;
      }
    }

    return maxScore;
  }

  static bool isAnswerCorrect(String spokenText, String actualAnswer) {
    return getMatchScore(spokenText, actualAnswer) >= 0.7;
  }
}
