import 'package:dm_bhatt_tutions/constant/string_constant.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_filled_button.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/exam_question_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';

class ExamInstructionScreen extends StatelessWidget {
  final String subject;
  final String examId;
  final String title;
  
  const ExamInstructionScreen({super.key, required this.subject, required this.examId, required this.title});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const CustomAppBar(
        title: lblExamInstructions,
      ),
      body: Padding(
        padding: P.all24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Icon(
              Icons.rule,
              size: S.s100,
              color: colorScheme.primary,
            ),
            blankVerticalSpace32,
            Text(
              lblExamInstructions,
              style: textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            blankVerticalSpace32,
            _buildInstruction(context, lblInstruction1),
            _buildInstruction(context, lblInstruction2),
            _buildInstruction(context, lblInstruction3),
            _buildInstruction(context, lblInstruction4),
            _buildInstruction(context, lblInstruction5),
            const Spacer(),
            Text(
              lblAllTheBest,
              style: textTheme.titleLarge?.copyWith(color: colorScheme.primary),
              textAlign: TextAlign.center,
            ),
            blankVerticalSpace32,
            Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.065,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(S.s12),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExamQuestionScreen(subject: subject, examId: examId, title: title),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(S.s12)),
                ),
                child: Text(
                  lblProceedToExam,
                  style: TextStyle(
                      letterSpacing: 0.5,
                      fontSize: MediaQuery.of(context).size.width * 0.045,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(BuildContext context, String text) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 20.0),
          const SizedBox(width: 16.0),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
