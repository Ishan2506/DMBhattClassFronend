import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dm_bhatt_tutions/network/api_service.dart';

class AcademicConstants {
  static const List<String> boards = ["GSEB", "CBSE"];

  static Map<String, List<String>> standards = Map.from(_fallbackStandards);
  static Map<String, List<String>> subjects = Map.from(_fallbackSubjectsMap);

  static const Map<String, List<String>> _fallbackStandards = {
    "GSEB": [
      "6", "7", "8", "9", "10",
      "11", "12"
    ],
    "CBSE": [
      "6", "7", "8", "9", "10",
      "11", "12"
    ]
  };

  static const Map<String, List<String>> _fallbackSubjectsMap = {
    "GSEB-6": ["Maths", "Science", "English", "Gujarati", "Hindi", "Social Science", "Computer"],
    "GSEB-7": ["Maths", "Science", "English", "Gujarati", "Hindi", "Social Science", "Computer"],
    "GSEB-8": ["Maths", "Science", "English", "Gujarati", "Hindi", "Social Science", "Computer"],
    "GSEB-9": ["Maths", "Science", "English", "Gujarati", "Hindi", "Social Science", "Computer"],
    "GSEB-10": ["Maths", "Science", "English", "Gujarati", "Hindi", "Social Science", "Computer", "Sanskrit"],

    "GSEB-11-Science": ["Physics", "Chemistry", "Biology", "Mathematics", "English", "Computer Science"],
    "GSEB-12-Science": ["Physics", "Chemistry", "Biology", "Mathematics", "English", "Computer Science"],

    "GSEB-11-Commerce": [
      "Accountancy",
      "Business Studies",
      "Economics",
      "Statistics",
      "English",
      "Organization Of Commerce",
      "Secretarial Practice"
    ],
    "GSEB-12-Commerce": [
      "Accountancy",
      "Business Studies",
      "Economics",
      "Statistics",
      "English",
      "Organization Of Commerce",
      "Secretarial Practice"
    ],

    "CBSE-6": ["Maths", "Science", "English", "Hindi", "Social Science", "Computer"],
    "CBSE-7": ["Maths", "Science", "English", "Hindi", "Social Science", "Computer"],
    "CBSE-8": ["Maths", "Science", "English", "Hindi", "Social Science", "Computer"],
    "CBSE-9": ["Maths", "Science", "English", "Hindi", "Social Science", "Computer"],
    "CBSE-10": ["Maths", "Science", "English", "Hindi", "Social Science", "Computer", "Gujarati", "Sanskrit"],

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

  static String _normalizeStandard(String value) {
    final match = RegExp(r'(\d+)').firstMatch(value);
    return match?.group(1) ?? value.trim();
  }

  /// Load standards and subjects created in the admin app.
  ///
  /// The backend catalog is board-agnostic, while student screens use keys like
  /// GSEB-10 and CBSE-11-Science, so each API subject is exposed for both boards.
  static Future<void> loadFromServer() async {
    standards = Map.from(_fallbackStandards);
    subjects = Map.from(_fallbackSubjectsMap);

    try {
      final stdRes = await http.get(
        Uri.parse("${ApiService.baseUrl}/superadmin/standards"),
      ).timeout(const Duration(seconds: 5));

      if (stdRes.statusCode == 200) {
        final List<dynamic> fetchedStandards = jsonDecode(stdRes.body);
        final apiStandards = fetchedStandards
            .map((s) => s['name']?.toString() ?? '')
            .map(_normalizeStandard)
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList();

        if (apiStandards.isNotEmpty) {
          standards = {
            for (final board in boards) board: List<String>.from(apiStandards),
          };
        }
      } else {
        debugPrint("Standards API failed: ${stdRes.statusCode} ${stdRes.body}");
      }

      final subRes = await http.get(
        Uri.parse("${ApiService.baseUrl}/superadmin/subjects"),
      ).timeout(const Duration(seconds: 5));

      if (subRes.statusCode == 200) {
        final List<dynamic> fetchedSubjects = jsonDecode(subRes.body);
        final Map<String, List<String>> apiSubjects = {};

        for (final sub in fetchedSubjects) {
          final standardInfo = sub['standardId'];
          if (standardInfo == null) continue;

          final rawStdName = standardInfo['name']?.toString() ?? '';
          final stdName = _normalizeStandard(rawStdName);
          final subName = sub['name']?.toString() ?? '';
          if (stdName.isEmpty || subName.isEmpty) continue;

          final stream = sub['stream']?.toString() ?? '';
          final hasStream = stream.isNotEmpty && stream != 'None';

          for (final board in boards) {
            final key = hasStream ? "$board-$stdName-$stream" : "$board-$stdName";
            apiSubjects.putIfAbsent(key, () => []);

            if (!apiSubjects[key]!.contains(subName)) {
              apiSubjects[key]!.add(subName);
            }
          }
        }

        if (apiSubjects.isNotEmpty) {
          subjects = apiSubjects;
          debugPrint("Loaded ${apiSubjects.length} subject groups from admin API");
        } else {
          debugPrint("Subjects API returned no usable subjects");
        }
      } else {
        debugPrint("Subjects API failed: ${subRes.statusCode} ${subRes.body}");
      }

      debugPrint("Academic constants loaded from admin API");
    } catch (e) {
      debugPrint("Failed to load academic constants from API: $e. Using fallback data.");
    }
  }

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
    return _fallbackSubjectsMap[key] ?? _fallbackSubjects;
  }

  static const List<String> _fallbackSubjects = [
    "Maths", "Science", "English", "Social Science", "Gujarati",
    "Physics", "Chemistry", "Biology", "Accountancy", "Statistics"
  ];
}
