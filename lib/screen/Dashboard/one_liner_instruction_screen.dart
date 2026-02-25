import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/one_liner_exam_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OneLinerInstructionScreen extends StatelessWidget {
  final String subject;
  final String unit;
  final String title;
  final String examId;

  const OneLinerInstructionScreen({
    super.key,
    required this.subject,
    required this.unit,
    required this.title,
    required this.examId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(
        title: "Instructions",
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.info_outline_rounded, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            Text(
              "How it works?",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildInstructionItem(
              context,
              icon: Icons.mic_rounded,
              text: "Speak your answers clearly after tapping the microphone button.",
            ),
            _buildInstructionItem(
              context,
              icon: Icons.vpn_key_rounded,
              text: "The system will automatically fetch crucial keywords from your speech to evaluate accuracy.",
            ),
            _buildInstructionItem(
              context,
              icon: Icons.language_rounded,
              text: "You can answer in English only.",
            ),
            _buildInstructionItem(
              context,
              icon: Icons.analytics_outlined,
              text: "Post-exam, you'll receive a detailed match percentage based on the fetched keywords.",
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OneLinerExamScreen(
                      subject: subject,
                      unit: unit,
                      title: title,
                      examId: examId,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              child: Text(
                "Start Exam Now",
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(BuildContext context, {required IconData icon, required String text}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: colorScheme.onSurface,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
