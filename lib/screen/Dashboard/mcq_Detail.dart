import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class McqDetailScreen extends StatelessWidget {
  const McqDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Questions Data
    final List<Map<String, dynamic>> questions = [
      {
        "q": "What is the capital of India?",
        "user_ans": "New Delhi",
        "correct_ans": "New Delhi",
        "is_correct": true
      },
      {
        "q": "Which planet is known as the Red Planet?",
        "user_ans": "Venus",
        "correct_ans": "Mars",
        "is_correct": false
      },
      {
        "q": "What is 5 + 7?",
        "user_ans": "12",
        "correct_ans": "12",
        "is_correct": true
      },
    ];

    return Scaffold(
      appBar: const CustomAppBar(
        title: "MCQ Review",
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final item = questions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Q${index + 1}: ${item['q']}",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text("Your Answer: ${item['user_ans']}",
                      style: TextStyle(
                          color: item['is_correct'] ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600)),
                  if (!item['is_correct'])
                    Text("Correct Answer: ${item['correct_ans']}",
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 5),
                  Icon(
                    item['is_correct'] ? Icons.check_circle : Icons.cancel,
                    color: item['is_correct'] ? Colors.green : Colors.red,
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}