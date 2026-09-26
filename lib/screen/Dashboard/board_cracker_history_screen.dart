import 'dart:convert';

import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/pdf_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const List<String> _pdfOptionLetters = ['A', 'B', 'C', 'D'];

/// Question paper PDF for one Objectives Test Series attempt: every question
/// with its options, the student's answer and the correct one.
///
/// [reviewById] maps a question `_id` to `{selectedAnswer, correctAnswer,
/// isCorrect, explanation}` - the shape the submit API returns as `review`.
Future<Uint8List> buildObjectivesPaperPdf({
  required String title,
  String? subject,
  DateTime? date,
  required int obtainedMarks,
  required int totalMarks,
  required num accuracy,
  required List<Map<String, dynamic>> questions,
  required Map<String, dynamic> reviewById,
}) async {
  final pdf = pw.Document();
  final logoData = await rootBundle.load(imgDmBhattLogo);
  final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
  final formattedDate =
      DateFormat('MMM dd, yyyy').format((date ?? DateTime.now()).toLocal());

  pdf.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        // Poppins for Latin text; Noto Gujarati/Devanagari as fallbacks so
        // Gujarati/Hindi papers render instead of tofu boxes.
        theme: pw.ThemeData.withFont(
          base: await PdfGoogleFonts.poppinsRegular(),
          bold: await PdfGoogleFonts.poppinsBold(),
          fontFallback: [
            await PdfGoogleFonts.notoSansGujaratiRegular(),
            await PdfGoogleFonts.notoSansDevanagariRegular(),
          ],
        ),
        buildBackground: (pw.Context context) => pw.FullPage(
          ignoreMargins: true,
          child: pw.Center(
            child: pw.Opacity(
              opacity: 0.1,
              child: pw.Image(logoImage, width: 300),
            ),
          ),
        ),
      ),
      build: (pw.Context context) => [
        pw.Header(
          level: 0,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Padhaku",
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text("Date: $formattedDate"),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Center(
          child: pw.Text(
            title,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
        ),
        if (subject != null && subject.isNotEmpty)
          pw.Center(child: pw.Text(subject)),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text("Marks Obtained: $obtainedMarks/$totalMarks",
                  style: const pw.TextStyle(fontSize: 16)),
              pw.Text(
                "Accuracy: $accuracy%",
                style: pw.TextStyle(
                  fontSize: 14,
                  color: accuracy >= 70 ? PdfColors.green : PdfColors.orange,
                ),
              ),
            ],
          ),
        ),
        pw.Divider(),
        pw.SizedBox(height: 20),
        pw.Text("Questions:",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        ...List.generate(questions.length, (i) {
          final q = questions[i];
          return _pdfQuestion(i + 1, q, reviewById[q['_id']?.toString()]);
        }),
      ],
    ),
  );

  return pdf.save();
}

pw.Widget _pdfQuestion(int number, Map<String, dynamic> q, dynamic review) {
  final selected = review?['selectedAnswer']?.toString() ?? '';
  final correct = review?['correctAnswer']?.toString() ?? '';
  final explanation = review?['explanation']?.toString() ?? '';
  final isCorrect = review?['isCorrect'] == true;

  String optionText(String letter) =>
      letter.isEmpty ? '' : "$letter. ${q['option$letter'] ?? ''}";

  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 14),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("$number. ",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Expanded(child: pw.Text(q['question']?.toString() ?? '')),
          ],
        ),
        pw.SizedBox(height: 4),
        ..._pdfOptionLetters
            .where((l) => q['option$l']?.toString().trim().isNotEmpty ?? false)
            .map((l) => pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 15, top: 2),
                  child: pw.Text(optionText(l)),
                )),
        pw.SizedBox(height: 4),
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 15),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                selected.isEmpty
                    ? "Your Answer: Skipped"
                    : "Your Answer: ${optionText(selected)}",
                style: pw.TextStyle(
                  fontSize: 10,
                  color: selected.isEmpty
                      ? PdfColors.grey700
                      : (isCorrect ? PdfColors.green : PdfColors.red),
                ),
              ),
              if (correct.isNotEmpty)
                pw.Text(
                  "Correct Answer: ${optionText(correct)}",
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green,
                  ),
                ),
              if (explanation.isNotEmpty)
                pw.Text(
                  explanation,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey700,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// History
// ---------------------------------------------------------------------------

class BoardCrackerHistoryScreen extends StatefulWidget {
  const BoardCrackerHistoryScreen({super.key});

  @override
  State<BoardCrackerHistoryScreen> createState() =>
      _BoardCrackerHistoryScreenState();
}

class _BoardCrackerHistoryScreenState extends State<BoardCrackerHistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _history = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getMyBoardCrackerResults();
      if (!mounted) return;
      setState(() {
        if (response.statusCode == 200) {
          _history = jsonDecode(response.body) as List<dynamic>;
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching Objectives Test Series history: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> _filteredHistory() {
    if (_searchQuery.isEmpty) return _history;
    final query = _searchQuery.toLowerCase();
    return _history.where((r) {
      final title = (r['title'] ?? "").toString().toLowerCase();
      final subject = (r['subject'] ?? "").toString().toLowerCase();
      return title.contains(query) || subject.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = _filteredHistory();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(
        title: "Objectives Test History",
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CustomLoader())
          : Column(
              children: [
                _buildSearchBar(context),
                Expanded(
                  child: items.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _fetchHistory,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: items.length,
                            itemBuilder: (context, index) =>
                                _buildHistoryCard(items[index]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: "Search by title...",
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = "");
                  },
                )
              : null,
          filled: true,
          fillColor: colorScheme.surfaceContainer,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: colorScheme.outlineVariant.withOpacity(0.5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: colorScheme.outlineVariant.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded,
              size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No Objectives Test Series history found",
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(dynamic item) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final date = DateTime.tryParse(
            (item['submittedAt'] ?? item['createdAt'])?.toString() ?? '')
        ?.toLocal();
    final formattedDate =
        date != null ? DateFormat('MMM dd, yyyy - hh:mm a').format(date) : '';
    final num accuracy = item['accuracy'] ?? 0;
    final bool isRanked = item['isRanked'] == true;

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E284A) : Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: ListTile(
        onTap: () => _openPdf(item),
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child:
              Icon(Icons.workspace_premium_rounded, color: colorScheme.primary),
        ),
        title: Text(
          item['title']?.toString() ?? "Objectives Test Series",
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, color: colorScheme.onSurface),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (formattedDate.isNotEmpty)
              Text(
                "Date: $formattedDate",
                style: GoogleFonts.poppins(
                    fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
            Text(
              "Accuracy: $accuracy% · ${isRanked ? 'Ranked' : 'Practice'}",
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: accuracy >= 70 ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "Marks",
              style: GoogleFonts.poppins(
                  fontSize: 10, color: colorScheme.onSurfaceVariant),
            ),
            Text(
              "${item['obtainedMarks']}/${item['totalMarks']}",
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPdf(dynamic item) async {
    final resultId = item['_id']?.toString();
    if (resultId == null) return;

    CustomLoader.show(context);
    try {
      final response = await ApiService.getMyBoardCrackerResultDetail(resultId);
      if (response.statusCode != 200) {
        throw Exception("Server returned ${response.statusCode}");
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final result = data['result'] as Map<String, dynamic>;
      final exam = data['exam'] as Map<String, dynamic>?;
      if (exam == null) {
        throw Exception("This paper is no longer available.");
      }

      final questions = (exam['questions'] as List<dynamic>? ?? [])
          .map((q) => Map<String, dynamic>.from(q as Map))
          .toList();
      final explanationById = {
        for (final q in questions) q['_id'].toString(): q['explanation'],
      };
      final reviewById = <String, dynamic>{
        for (final a in (result['answers'] as List<dynamic>? ?? []))
          a['questionId'].toString(): {
            ...Map<String, dynamic>.from(a as Map),
            'explanation': explanationById[a['questionId'].toString()],
          },
      };
      // Questions the student never reached still show their correct answer.
      for (final q in questions) {
        reviewById.putIfAbsent(q['_id'].toString(), () => {
              'selectedAnswer': '',
              'correctAnswer': q['correctAnswer'],
              'isCorrect': false,
              'explanation': q['explanation'],
            });
      }

      final title = result['title']?.toString() ??
          exam['title']?.toString() ??
          'Objectives Test Series';
      final bytes = await buildObjectivesPaperPdf(
        title: title,
        subject: result['subject']?.toString() ?? exam['subject']?.toString(),
        date: DateTime.tryParse(
            (result['submittedAt'] ?? result['createdAt'])?.toString() ?? ''),
        obtainedMarks: (result['obtainedMarks'] as num?)?.toInt() ?? 0,
        totalMarks: (result['totalMarks'] as num?)?.toInt() ?? questions.length,
        accuracy: result['accuracy'] ?? 0,
        questions: questions,
        reviewById: reviewById,
      );

      if (!mounted) return;
      CustomLoader.hide(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfPreviewScreen(
            product: {'name': title, 'id': resultId},
            pdfBytes: bytes,
            isFullAccess: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error opening Objectives Test Series PDF: $e");
      if (!mounted) return;
      CustomLoader.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open this paper. Please try again.")),
      );
    }
  }
}
