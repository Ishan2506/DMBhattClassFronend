import 'package:dm_bhatt_tutions/constant/string_constant.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_filled_button.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/exam_question_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:flutter/material.dart';

class ExamInstructionScreen extends StatelessWidget {
  const ExamInstructionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(lblExamInstructions),
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
            CustomFilledButton(
              label: lblProceedToExam,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExamQuestionScreen(),
                  ),
                );
              },
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
