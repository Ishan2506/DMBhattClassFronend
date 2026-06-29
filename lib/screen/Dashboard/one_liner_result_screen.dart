import 'dart:typed_data';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_filled_button.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/landing_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/pdf_preview_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class OneLinerResultScreen extends StatefulWidget {
  final int totalQuestions;
  final int correctAnswers;
  final double averageAccuracy;
  final List<Map<String, dynamic>> questions;
  final Map<int, String> spokenAnswers;
  final String subject;
  final String title;
  final String unit;
  final int totalMarks;
  final int obtainedMarks;

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
    required this.totalMarks,
    required this.obtainedMarks,
  });

  @override
  State<OneLinerResultScreen> createState() => _OneLinerResultScreenState();
}

class _OneLinerResultScreenState extends State<OneLinerResultScreen> {
  bool _isLoading = false;

  Future<Uint8List> _generatePdfBytes() async {
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
        ),
        build: (pw.Context context) {
          final String formattedDate = DateFormat('MMM dd, yyyy').format(DateTime.now());
          final double accuracy = widget.averageAccuracy;

          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Padhaku", style: pw.TextStyle(font: fontBold, fontSize: 18)),
                  pw.Text("Date: $formattedDate", style: pw.TextStyle(font: font)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text(widget.title, style: pw.TextStyle(font: fontBold, fontSize: 24)),
            ),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    "Marks Obtained: ${widget.obtainedMarks}/${widget.totalMarks}",
                    style: pw.TextStyle(font: font, fontSize: 16),
                  ),
                  pw.Text(
                    "Accuracy: ${accuracy.toStringAsFixed(1)}%",
                    style: pw.TextStyle(font: font, fontSize: 14, color: accuracy >= 70 ? PdfColors.green : PdfColors.orange),
                  ),
                ],
              ),
            ),
            pw.Divider(),
            pw.SizedBox(height: 20),
            pw.Text("Questions:", style: pw.TextStyle(font: fontBold, fontSize: 18)),
            pw.SizedBox(height: 10),
            ...List.generate(widget.questions.length, (index) {
              final q = widget.questions[index];
              final spoken = widget.spokenAnswers[index] ?? "N/A";
              final target = q['answer']['en'] ?? "";

              final bool isCorrect = spoken.toLowerCase().trim() == target.toLowerCase().trim();

              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: _buildResultItem(index + 1, q['question']['en'] ?? "", spoken, target, isCorrect, font, fontBold),
              );
            }),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  Future<void> _previewPdf() async {
    setState(() => _isLoading = true);
    try {
      final bytes = await _generatePdfBytes();
      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfPreviewScreen(
            product: {
              'name': '${widget.unit} - ${widget.subject} (${widget.title})',
            },
            isFullAccess: true,
            pdfBytes: bytes,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating preview: $e')),
        );
      }
    }
  }

  pw.Widget _buildResultItem(int number, String question, String yourAnswer, String correctAnswer, bool isCorrect, pw.Font font, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("$number. ", style: pw.TextStyle(font: fontBold)),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(question, style: pw.TextStyle(font: font)),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Text("Your Answer: $yourAnswer ", style: pw.TextStyle(font: font, fontSize: 10, color: isCorrect ? PdfColors.green : PdfColors.red)),
                    if (!isCorrect)
                      pw.Text("(Correct: $correctAnswer)", style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.green)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Text(
            isCorrect ? "CORRECT" : "WRONG",
            style: pw.TextStyle(font: fontBold, color: isCorrect ? PdfColors.green : PdfColors.red, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        Scaffold(
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
                      _buildSummaryStat("Correct", "${widget.correctAnswers}/${widget.totalQuestions}", Colors.white),
                      _buildSummaryStat("Marks", "${widget.obtainedMarks}/${widget.totalMarks}", Colors.white),
                      _buildSummaryStat("Accuracy", "${widget.averageAccuracy.toStringAsFixed(1)}%", Colors.white),
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
              itemCount: widget.questions.length,
              itemBuilder: (context, index) {
                final q = widget.questions[index];
                final spoken = widget.spokenAnswers[index] ?? "N/A";
                final target = q['answer']['en'] ?? "";
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: P.all16,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
              label: "Preview Questions",
              icon: Icons.visibility_rounded,
              onPressed: _previewPdf,
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
        ),
        if (_isLoading)
          const CustomLoader(),
      ],
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
