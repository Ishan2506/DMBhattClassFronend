
import 'package:flutter/material.dart';

class ExamHistoryData {
  static final ExamHistoryData _instance = ExamHistoryData._internal();
  factory ExamHistoryData() => _instance;
  ExamHistoryData._internal();

  // Mock Data for Regular Exams
  final List<Map<String, dynamic>> regularExams = [
    {"title": "Science_Weekly Test", "date": "Jan 25, 2025", "marks": "25/30"},
    {"title": "Maths_Chapter 5", "date": "Jan 18, 2025", "marks": "28/30"},
  ];

  // Mock Data for 5 Min Quizzes
  final List<Map<String, dynamic>> quizExams = [
    {"title": "English_Grammar Quiz", "date": "Jan 28, 2025", "marks": "10/10"},
    {"title": "GK_Rapid Fire", "date": "Jan 20, 2025", "marks": "8/10"},
  ];

  bool isRegularExamTaken(String title) {
    return regularExams.any((exam) => exam['title'].toLowerCase() == title.toLowerCase());
  }

  bool isQuizExamTaken(String title) {
    return quizExams.any((exam) => exam['title'].toLowerCase() == title.toLowerCase());
  }

  void addRegularExam(String title, String marks) {
    // Current date for simplicity
    final date = "${DateTime.now().month}/${DateTime.now().day}/${DateTime.now().year}";
    regularExams.insert(0, {"title": title, "date": date, "marks": marks});
  }

  void addQuizExam(String title, String marks) {
    final date = "${DateTime.now().month}/${DateTime.now().day}/${DateTime.now().year}";
    quizExams.insert(0, {"title": title, "date": date, "marks": marks});
  }
}
