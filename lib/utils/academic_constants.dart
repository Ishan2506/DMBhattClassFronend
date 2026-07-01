import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';

class AcademicConstants {
  static const List<String> boards = ["GSEB", "CBSE"];

  static Map<String, List<String>> standards = {
    "GSEB": [
      "6", "7", "8", "9", "10",
      "11", "12"
    ],
    "CBSE": [
      "6", "7", "8", "9", "10",
      "11", "12"
    ]
  };

  static Map<String, List<String>> subjects = {
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

  static Future<void> loadFromServer() async {
    try {
      // 1. Fetch Standards
      final stdRes = await http.get(Uri.parse("${ApiService.baseUrl}/superadmin/standards/status/true"));
      if (stdRes.statusCode == 200) {
        List<dynamic> fetchedStandards = jsonDecode(stdRes.body);
        List<String> allStds = fetchedStandards.map((s) => s['name'].toString()).toList();
        
        if (allStds.isNotEmpty) {
          // Broadcast across both boards since the backend handles subjects agnostic of board
          standards["GSEB"] = allStds;
          standards["CBSE"] = allStds;
        }
      }

      // 2. Fetch Subjects
      final subRes = await http.get(Uri.parse("${ApiService.baseUrl}/superadmin/subjects"));
      if (subRes.statusCode == 200) {
        List<dynamic> fetchedSubjects = jsonDecode(subRes.body);
        Map<String, List<String>> newSubjectsMap = {};

        for(var sub in fetchedSubjects) {
          final standardInfo = sub['standardId'];
          if (standardInfo == null) continue;

          final String stdName = standardInfo['name']?.toString() ?? "";
          if (stdName.isEmpty) continue;

          final String streamName = (sub['stream'] != null && sub['stream'] != 'None') ? sub['stream'].toString() : "";
          
          final String gsebKey = streamName.isNotEmpty ? "GSEB-$stdName-$streamName" : "GSEB-$stdName";
          final String cbseKey = streamName.isNotEmpty ? "CBSE-$stdName-$streamName" : "CBSE-$stdName";

          if (!newSubjectsMap.containsKey(gsebKey)) newSubjectsMap[gsebKey] = [];
          if (!newSubjectsMap.containsKey(cbseKey)) newSubjectsMap[cbseKey] = [];
          
          final String subName = sub['name'].toString();
          if (!newSubjectsMap[gsebKey]!.contains(subName)) newSubjectsMap[gsebKey]!.add(subName);
          if (!newSubjectsMap[cbseKey]!.contains(subName)) newSubjectsMap[cbseKey]!.add(subName);
        }

        // Only override if data successfully collected
        if (newSubjectsMap.isNotEmpty) {
          subjects = newSubjectsMap;
        }
      }
    } catch(e) {
      debugPrint("Failed to load academic constants from server: $e");
    }
  }

  static const List<String> _fallbackSubjects = [
    "Maths", "Science", "English", "Social Science", "Gujarati",
    "Physics", "Chemistry", "Biology", "Accountancy", "Statistics"
  ];
}
