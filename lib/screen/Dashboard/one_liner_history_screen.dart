
import 'dart:convert';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'dart:io';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class OneLinerHistoryScreen extends StatefulWidget {
  const OneLinerHistoryScreen({super.key});

  @override
  State<OneLinerHistoryScreen> createState() => _OneLinerHistoryScreenState();
}

class _OneLinerHistoryScreenState extends State<OneLinerHistoryScreen> {
  List<dynamic> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getDashboardData();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['examResults'] ?? [];
        
        setState(() {
          _history = results
              .where((e) => e['type'] == 'ONELINER')
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error loading one-liner history: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(
        title: "One-Liner History",
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CustomLoader())
          ? const Center(child: CustomLoader())
          : _history.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    return _buildHistoryCard(item);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No one-liner history found",
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(dynamic item) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateStr = item['date'] ?? item['createdAt'];
    final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
    final formattedDate = DateFormat('MMM dd, yyyy').format(date);
    final double accuracy = (item['accuracy'] ?? 0).toDouble();

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => _generateAndOpenPdf(context, item),
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.mic_none, color: colorScheme.primary),
        ),
        title: Text(
          item['title'] ?? "One-Liner Exam",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Date: $formattedDate",
              style: GoogleFonts.poppins(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
            Text(
              "Accuracy: ${accuracy.toStringAsFixed(1)}%",
              style: GoogleFonts.poppins(
                fontSize: 12, 
                fontWeight: FontWeight.w600,
                color: accuracy >= 70 ? Colors.green : Colors.orange
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
              style: GoogleFonts.poppins(fontSize: 10, color: colorScheme.onSurfaceVariant),
            ),
            Text(
              "${item['obtainedMarks']}/${item['totalMarks']}",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: colorScheme.primary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndOpenPdf(BuildContext context, dynamic exam) async {
    final rawId = exam['examId'];
    final examId = rawId is Map ? rawId['_id']?.toString() : rawId?.toString();
    
    CustomLoader.show(context);
    try {
      Map<String, dynamic>? fullExam;
      if (examId != null && examId.isNotEmpty) {
        final response = await ApiService.getOneLinerExamById(examId);
        if (response.statusCode == 200) {
          fullExam = jsonDecode(response.body);
        }
      }

      if (context.mounted) {
        CustomLoader.hide(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExamPdfViewer(
              exam: exam is Map<String, dynamic> ? exam : Map<String, dynamic>.from(exam),
              fullExam: fullExam,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomLoader.hide(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExamPdfViewer(
               exam: exam is Map<String, dynamic> ? exam : Map<String, dynamic>.from(exam),
            ),
          ),
        );
      }
    }
  }
}

class ExamPdfViewer extends StatelessWidget {
  final Map<String, dynamic> exam;
  final Map<String, dynamic>? fullExam;
  const ExamPdfViewer({super.key, required this.exam, this.fullExam});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: exam['title'],
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () => _downloadPdf(context),
            tooltip: "Download",
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => _sharePdf(context),
             tooltip: "Share (Protected)",
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => _generateExamPdf(format, exam),
        canChangeOrientation: false,
        canChangePageFormat: false,
        allowSharing: false,
        allowPrinting: false,
        useActions: false, 
      ),
    );
  }

  Future<void> _downloadPdf(BuildContext context) async {
    try {
      final bytes = await _generateExamPdf(PdfPageFormat.a4, exam);
      
      if (kIsWeb) {
        await Printing.sharePdf(bytes: bytes, filename: '${exam['title']}.pdf');
      } else {
        final directory = Platform.isAndroid 
            ? await getExternalStorageDirectory() 
            : await getApplicationDocumentsDirectory();
        
        final path = directory?.path ?? (await getApplicationDocumentsDirectory()).path;
        final file = File('$path/${exam['title'].replaceAll(' ', '_')}.pdf');
        await file.writeAsBytes(bytes);

        if (context.mounted) {
          CustomToast.showSuccess(context, "Downloaded to: ${file.path}");
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomToast.showError(context, "Download failed: $e");
      }
    }
  }

  Future<void> _sharePdf(BuildContext context) async {
    try {
      final bytes = await _generateExamPdf(PdfPageFormat.a4, exam);
      await Printing.sharePdf(bytes: bytes, filename: '${exam['title']}.pdf');
    } catch (e) {
      if (context.mounted) {
        CustomToast.showError(context, "Share failed: $e");
      }
    }
  }

  Future<Uint8List> _generateExamPdf(PdfPageFormat format, Map<String, dynamic> exam) async {
    final pdf = pw.Document();
    final logoData = await rootBundle.load(imgDmBhattLogo);
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: format,
          theme: pw.ThemeData.withFont(
             base: await PdfGoogleFonts.poppinsRegular(),
             bold: await PdfGoogleFonts.poppinsBold(),
             fontFallback: [
               await PdfGoogleFonts.notoSansGujaratiRegular(),
               await PdfGoogleFonts.notoSansDevanagariRegular(),
             ],
          ),
          buildBackground: (pw.Context context) {
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Center(
                child: pw.Opacity(
                  opacity: 0.1,
                  child: pw.Image(logoImage, width: 300),
                ),
              ),
            );
          },
        ),
        build: (pw.Context context) {
          final dateStr = exam['date'] ?? exam['createdAt'];
          final DateTime date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
          final String formattedDate = DateFormat('MMM dd, yyyy').format(date);
          final double accuracy = (exam['accuracy'] ?? 0).toDouble();

          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("D. M. Bhatt Tuition Classes", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text("Date: $formattedDate"),
                ]
              )
            ),
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text(exam['title'] ?? "", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 10),
            pw.Center(
               child: pw.Column(
                 children: [
                   pw.Text(
                    "Marks Obtained: ${exam['obtainedMarks']}/${exam['totalMarks']}",
                    style: const pw.TextStyle(fontSize: 16),
                  ),
                   pw.Text(
                    "Accuracy: ${accuracy.toStringAsFixed(1)}%",
                    style: pw.TextStyle(fontSize: 14, color: accuracy >= 70 ? PdfColors.green : PdfColors.orange),
                  ),
                 ]
               )
            ),
            pw.Divider(),
            pw.SizedBox(height: 20),
            pw.Text("Questions:", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            if (fullExam != null && fullExam!['questions'] != null)
              ...List.generate((fullExam!['questions'] as List).length, (index) {
                final q = fullExam!['questions'][index];
                final qText = q['questionText'] ?? q['question'] ?? "Question ${index + 1}";
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: _buildQuestionItem(index + 1, qText),
                );
              })
            else ...[
              pw.Padding(padding: const pw.EdgeInsets.only(bottom: 8), child: _buildQuestionItem(1, "Question 1 content placeholder...")),
              pw.Padding(padding: const pw.EdgeInsets.only(bottom: 8), child: _buildQuestionItem(2, "Question 2 content placeholder...")),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildQuestionItem(int number, String question) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("$number. ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Expanded(child: pw.Text(question)),
        ],
      ),
    );
  }
}
