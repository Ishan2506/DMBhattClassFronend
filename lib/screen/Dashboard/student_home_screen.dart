import 'package:dm_bhatt_tutions/constant/string_constant.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_filled_button.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/student_start_exam_form.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:flutter/material.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: P.all24,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CircleAvatar(
                radius: S.s64,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.school,
                  size: S.s64,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              blankVerticalSpace32,
              Text(
                lblWelcomeStudent,
                style: textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              blankVerticalSpace8,
              Text(
                lblReadyToTest,
                style: textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              blankVerticalSpace48,
              Card(
                elevation: S.s4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(S.s16),
                ),
                child: Padding(
                  padding: P.all24,
                  child: Column(
                    children: [
                      Text(
                        lblNextExamWaiting,
                        style: textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      blankVerticalSpace24,
                      CustomFilledButton(
                        label: lblStartExam,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StudentStartExamForm(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
