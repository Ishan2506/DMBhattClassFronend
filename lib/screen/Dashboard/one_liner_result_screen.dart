import 'dart:convert';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_filled_button.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/landing_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class OneLinerResultScreen extends StatelessWidget {
  final int totalQuestions;
  final int correctAnswers;
  final double averageAccuracy;
  final List<Map<String, dynamic>> questions;
  final Map<int, String> spokenAnswers;
  final String subject;
  final String title;
  final String unit;

  const OneLinerResultScreen({
    super.key,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.averageAccuracy,
    required this.questions,
    required this.spokenAnswers,
    required this.subject,
    required this.title,
    required this.unit,
  });

  Future<void> _generatePdf(BuildContext context) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.poppinsRegular();
    final fontBold = await PdfGoogleFonts.poppinsBold();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(
            base: font,
            bold: fontBold,
          ),
          buildForeground: (context) {
            return pw.Center(
              child: pw.Transform.rotate(
                angle: -0.5,
                child: pw.Text(
                  "DMBhatt",
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 100,
                    color: PdfColors.grey200,
                  ),
                ),
              ),
            );
          },
        ),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("One-Liner Exam Result", style: pw.TextStyle(font: fontBold, fontSize: 24)),
                      pw.SizedBox(height: 4),
                      pw.Text("$subject - $unit ($title)", style: pw.TextStyle(font: font, fontSize: 16)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("DMBhatt Tuitions", style: pw.TextStyle(font: fontBold, fontSize: 14)),
                      pw.Text("Date: ${DateTime.now().toString().split(' ')[0]}", style: pw.TextStyle(font: font, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            pw.Divider(),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildPdfStat("Total Qns", "$totalQuestions", fontBold),
                  _buildPdfStat("Passed", "$correctAnswers", fontBold, color: PdfColors.green),
                  _buildPdfStat("Avg. Accuracy", "${averageAccuracy.toStringAsFixed(1)}%", fontBold, color: PdfColors.blue),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            ...List.generate(questions.length, (index) {
              final q = questions[index];
              final spoken = spokenAnswers[index] ?? "N/A";
              final target = q['answer']['en'] ?? "";
              
              // Simple rough match check for color in PDF
              bool isCorrect = spoken.toLowerCase().trim() == target.toLowerCase().trim();

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 16),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Q${index + 1}: ${q['question']['en']}", style: pw.TextStyle(font: fontBold, fontSize: 12)),
                    pw.SizedBox(height: 4),
                    pw.Text("Admin Keyword: $target", style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.green)),
                    pw.Text("Your Answer: $spoken", style: pw.TextStyle(font: font, fontSize: 10, color: isCorrect ? PdfColors.green : PdfColors.red)),
                    pw.Divider(color: PdfColors.grey200),
                  ],
                ),
              );
            }),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'DMBhatt_OneLiner_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  pw.Widget _buildPdfStat(String label, String value, pw.Font font, {PdfColor color = PdfColors.black}) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(font: font, fontSize: 18, color: color)),
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: "Exam Result",
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LandingScreen()),
                (route) => false,
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: P.all16,
        child: Column(
          children: [
            // Summary Card
            Container(
              padding: P.all24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Text("🎉", style: TextStyle(fontSize: 40)),
                  Text(
                    "Exam Completed!",
                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryStat("Score", "$correctAnswers/$totalQuestions", Colors.white),
                      _buildSummaryStat("Accuracy", "${averageAccuracy.toStringAsFixed(1)}%", Colors.white),
                    ],
                  ),
                ],
              ),
            ),
            blankVerticalSpace24,
            
            // Detailed Review
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Detailed Review",
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            blankVerticalSpace16,
            
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final q = questions[index];
                final spoken = spokenAnswers[index] ?? "N/A";
                final target = q['answer']['en'] ?? "";
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: P.all16,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Q${index + 1}: ${q['question']['en']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _ReviewRow(label: "Admin Keyword:", value: target, color: Colors.green),
                      _ReviewRow(label: "Your Answer:", value: spoken, color: Colors.blue),
                    ],
                  ),
                );
              },
            ),
            blankVerticalSpace24,
            
            CustomFilledButton(
              label: "Download Questions",
              icon: Icons.download,
              onPressed: () => _generatePdf(context),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LandingScreen()),
                  (route) => false,
                );
              },
              child: Text("Back to Home", style: TextStyle(color: colorScheme.onSurfaceVariant)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: color.withOpacity(0.8))),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ReviewRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color))),
        ],
      ),
    );
  }
}
