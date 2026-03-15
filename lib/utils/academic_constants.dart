import 'package:flutter/foundation.dart';

class AcademicConstants {
  static const List<String> boards = ["GSEB", "CBSE"];

  static const Map<String, List<String>> standards = {
    "GSEB": [
      "6", "7", "8", "9", "10",
      "11", "12"
    ],
    "CBSE": [
      "6", "7", "8", "9", "10",
      "11", "12"
    ]
  };

  static const Map<String, List<String>> subjects = {
    "GSEB-6": ["Maths", "Science", "English", "Gujarati", "Hindi", "Social Science", "Computer"],
    "GSEB-7": ["Maths", "Science", "English", "Gujarati", "Hindi", "Social Science", "Computer"],
    "GSEB-8": ["Maths", "Science", "English", "Gujarati", "Hindi", "Social Science", "Computer"],
    "GSEB-9": ["Maths", "Science", "English", "Gujarati", "Hindi", "Social Science", "Computer"],
    "GSEB-10": ["Maths", "Science", "English", "Gujarati", "Hindi", "Social Science", "Computer"],

    "GSEB-11-Science": ["Physics", "Chemistry", "Biology", "Mathematics", "English", "Computer Science"],
    "GSEB-12-Science": ["Physics", "Chemistry", "Biology", "Mathematics", "English", "Computer Science"],

    "GSEB-11-Commerce": [
      "Accountancy",
      "Business Studies",
      "Economics",
      "Statistics",
      "English",
      "Organization of Commerce",
      "Secretarial Practice"
    ],
    "GSEB-12-Commerce": [
      "Accountancy",
      "Business Studies",
      "Economics",
      "Statistics",
      "English",
      "Organization of Commerce",
      "Secretarial Practice"
    ],

    "CBSE-6": ["Maths", "Science", "English", "Hindi", "Social Science", "Computer"],
    "CBSE-7": ["Maths", "Science", "English", "Hindi", "Social Science", "Computer"],
    "CBSE-8": ["Maths", "Science", "English", "Hindi", "Social Science", "Computer"],
    "CBSE-9": ["Maths", "Science", "English", "Hindi", "Social Science", "Computer"],
    "CBSE-10": ["Maths", "Science", "English", "Hindi", "Social Science", "Computer"],

    "CBSE-11-Science": ["Physics", "Chemistry", "Biology", "Mathematics", "English", "Computer Science"],
    "CBSE-12-Science": ["Physics", "Chemistry", "Biology", "Mathematics", "English", "Computer Science"],

    "CBSE-11-Commerce": [
      "Accountancy",
      "Business Studies",
      "Economics",
      "Mathematics",
      "English",
      "Informatics Practices"
    ],
    "CBSE-12-Commerce": [
      "Accountancy",
      "Business Studies",
      "Economics",
      "Mathematics",
      "English",
      "Informatics Practices"
    ],
  };

  static const List<String> mediums = ["English", "Gujarati"];

  /// Helper to get subjects for a student based on their board, standard, and stream.
  /// [board] e.g. "GSEB", [std] e.g. "7" or "7th" (numeric part is extracted),
  /// [stream] e.g. "Science", "Commerce" (only relevant for std 11/12).
  /// Returns a fallback list if no match is found.
  static List<String> getSubjectsForStudent({
    required String? board,
    required String? std,
    String? stream,
  }) {
    if (board == null || std == null) {
      return _fallbackSubjects;
    }

    // Extract numeric part from std (e.g., "7th" -> "7", "10" -> "10")
    final stdMatch = RegExp(r'(\d+)').firstMatch(std);
    if (stdMatch == null) return _fallbackSubjects;
    final stdNum = stdMatch.group(1)!;

    // For std 11/12, try board-std-stream key first
    if ((stdNum == "11" || stdNum == "12") && stream != null && stream.isNotEmpty && stream != "None") {
      final streamKey = "$board-$stdNum-$stream";
      if (subjects.containsKey(streamKey)) {
        return subjects[streamKey]!;
      }
    }

    // Try board-std key
    final key = "$board-$stdNum";
    if (subjects.containsKey(key)) {
      return subjects[key]!;
    }
    return _fallbackSubjects;
  }

  static const List<String> _fallbackSubjects = [
    "Maths", "Science", "English", "Social Science", "Gujarati",
    "Physics", "Chemistry", "Biology", "Accountancy", "Statistics"
  ];
}
