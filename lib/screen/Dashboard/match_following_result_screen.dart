import 'dart:typed_data';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_filled_button.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/landing_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/pdf_preview_screen.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';

class MatchFollowingResultScreen extends StatefulWidget {
  final int totalPairs;
  final int correctMatches;
  final num averageAccuracy;
  final String subject;
  final String title;
  final String unit;
  final List<Map<String, dynamic>> answers;

  const MatchFollowingResultScreen({
    super.key,
    required this.totalPairs,
    required this.correctMatches,
    required this.averageAccuracy,
    required this.subject,
    required this.title,
    required this.unit,
    required this.answers,
  });

  @override
  State<MatchFollowingResultScreen> createState() => _MatchFollowingResultScreenState();
}

class _MatchFollowingResultScreenState extends State<MatchFollowingResultScreen> {
  bool _isLoading = false;

  Future<pw.Font> _loadCustomFont() async {
    return await PdfGoogleFonts.poppinsRegular();
  }

  Future<pw.Font> _loadCustomFontBold() async {
    return await PdfGoogleFonts.poppinsBold();
  }

  Future<Uint8List> _generatePdfBytes() async {
    final pdf = pw.Document();
    final font = await _loadCustomFont();
    final fontBold = await _loadCustomFontBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
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
                      pw.Text("D.M. Bhatt Classes", style: pw.TextStyle(font: fontBold, fontSize: 24, color: PdfColors.blue900)),
                      pw.Text("Match the Following Exam Result", style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.grey700)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildPdfStat("Subject", widget.subject, fontBold),
                  _buildPdfStat("Unit", widget.unit, fontBold),
                  _buildPdfStat("Score", "${widget.correctMatches}/${widget.totalPairs}", fontBold, color: PdfColors.blue900),
                  _buildPdfStat("Accuracy", "${widget.averageAccuracy.toStringAsFixed(1)}%", fontBold),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text("Exam Details: ${widget.title}", style: pw.TextStyle(font: fontBold, fontSize: 16)),
            pw.Divider(),
            pw.SizedBox(height: 10),
            ...List.generate(widget.answers.length, (index) {
              final answer = widget.answers[index];
              final bool isCorrect = answer['isCorrect'] ?? false;
              final String leftVal = answer['left'] ?? '';
              final String correctRightVal = answer['correctMatch'] ?? answer['correctRight'] ?? '';
              final String studentMatch = answer['studentMatch'] ?? answer['right'];
              final String rightVal = (studentMatch == null || studentMatch.toString().isEmpty) ? 'Unanswered' : studentMatch;

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 16),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Pair ${index + 1}: $leftVal", style: pw.TextStyle(font: fontBold, fontSize: 12)),
                    pw.SizedBox(height: 4),
                    pw.Text("Correct Answer: $correctRightVal", style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.green)),
                    pw.Text("Your Answer: $rightVal", style: pw.TextStyle(font: font, fontSize: 10, color: isCorrect ? PdfColors.green : PdfColors.red)),
                    pw.Divider(color: PdfColors.grey200),
                  ],
                ),
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
                          _buildSummaryStat("Correct", "${widget.correctMatches}/${widget.totalPairs}", Colors.white),
                          _buildSummaryStat("Marks", "${widget.correctMatches}", Colors.white),
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
                  itemCount: widget.answers.length,
                  itemBuilder: (context, index) {
                    final answer = widget.answers[index];
                    final bool isCorrect = answer['isCorrect'] ?? false;
                    final String leftVal = answer['left'] ?? '';
                    final String correctRightVal = answer['correctMatch'] ?? answer['correctRight'] ?? '';
                    final String studentMatch = answer['studentMatch'] ?? answer['right'];
                    final String rightVal = (studentMatch == null || studentMatch.toString().isEmpty)
                        ? "Unanswered"
                        : studentMatch.toString();

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
                          Text("Pair ${index + 1}: $leftVal", style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          _ReviewRow(label: "Correct Match:", value: correctRightVal, color: Colors.green),
                          _ReviewRow(label: "Your Match:", value: rightVal, color: isCorrect ? Colors.green : Colors.red),
                        ],
                      ),
                    );
                  },
                ),
                blankVerticalSpace24,

                CustomFilledButton(
                  label: "Preview Results",
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
        if (_isLoading) const CustomLoader(),
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
