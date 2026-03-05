
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'dart:io';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:dm_bhatt_tutions/screen/Dashboard/exam_history_data.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'dart:convert';

class StudentFiveMinHistoryScreen extends StatelessWidget {
  const StudentFiveMinHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Fetch Data from Singleton (Only Quiz Exams)
    final quizExams = ExamHistoryData().quizExams;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(
        title: "5 Min Test History",
      ),
      body: _buildExamList(context, quizExams),
    );
  }

  Widget _buildExamList(BuildContext context, List<Map<String, dynamic>> exams) {
    final colorScheme = Theme.of(context).colorScheme;

    if (exams.isEmpty) {
      return Center(
        child: Text(
          "No 5-min tests found",
          style: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: exams.length,
      itemBuilder: (context, index) {
        final exam = exams[index];
        return Card(
          elevation: 0,
          color: colorScheme.surfaceContainer,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            onTap: () => _generateAndOpenPdf(context, exam),
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.timer, color: colorScheme.primary), // Changed icon to timer
            ),
            title: Text(
              exam['title'],
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
            ),
            subtitle: Text(
              "Date: ${exam['date']}",
              style: GoogleFonts.poppins(fontSize: 12, color: colorScheme.onSurfaceVariant),
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
                  exam['marks'],
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: colorScheme.primary, fontSize: 14),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateAndOpenPdf(BuildContext context, Map<String, dynamic> exam) async {
    final examId = exam['examId'] ?? exam['id'] ?? exam['_id'];
    
    if (examId == null) {
      // If no ID, it's likely local mock data from ExamHistoryData singleton
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExamPdfViewer(exam: exam),
        ),
      );
      return;
    }

    CustomLoader.show(context);
    try {
       // Since this is Five Min History, we fetch from FiveMinTest endpoint
      final response = await ApiService.getFiveMinTestById(examId);

      if (context.mounted) {
        CustomLoader.hide(context);
        if (response.statusCode == 200) {
          final fullExam = jsonDecode(response.body);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExamPdfViewer(
                exam: exam,
                fullExam: fullExam,
              ),
            ),
          );
        } else {
           // Fallback to just opening with what we have
           Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExamPdfViewer(exam: exam),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomLoader.hide(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExamPdfViewer(exam: exam),
          ),
        );
      }
    }
  }
}

// Reusing ExamPdfViewer Logic
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
        build: (format) => _generateExamPdf(format, exam), // Preview is unprotected
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
        // On Web, creating a download link or using Printing.sharePdf (which downloads)
        await Printing.sharePdf(bytes: bytes, filename: '${exam['title']}.pdf');
      } else {
        // Mobile / Desktop
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
      // Generate normal PDF (Unencrypted)
      final bytes = await _generateExamPdf(PdfPageFormat.a4, exam);
      
      if (context.mounted) {
         CustomToast.showSuccess(context, "Sharing PDF...");
      }
      
      await Printing.sharePdf(bytes: bytes, filename: '${exam['title']}.pdf');
    } catch (e) {
      if (context.mounted) {
        CustomToast.showError(context, "Share failed: $e");
      }
    }
  }

  Future<Uint8List> _generateExamPdf(PdfPageFormat format, Map<String, dynamic> exam) async {
    final pdf = pw.Document();
    
    // Load Logo for Watermark
    final logoData = await rootBundle.load(imgDmBhattLogo);
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        theme: pw.ThemeData.withFont(
           base: await PdfGoogleFonts.poppinsRegular(),
           bold: await PdfGoogleFonts.poppinsBold(),
        ),
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // White Background Container
              pw.Positioned.fill(child: pw.Container(color: PdfColors.white)),
              
              // Watermark
              pw.Center(
                child: pw.Opacity(
                  opacity: 0.1,
                  child: pw.Image(logoImage, width: 300),
                ),
              ),
              // Content
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                   pw.Header(
                    level: 0,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("D. M. Bhatt Tuition Classes", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                        pw.Text("Date: ${exam['date']}"),
                      ]
                    )
                  ),
                  pw.SizedBox(height: 20),
                  pw.Center(
                    child: pw.Text(exam['title'] ?? "", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Center(
                    child: pw.Text(
                      "Marks Obtained: ${exam['marks'] ?? (exam['obtainedMarks'] != null ? "${exam['obtainedMarks']}/${exam['totalMarks']}" : "N/A")}",
                      style: const pw.TextStyle(fontSize: 16),
                    ),
                  ),
                  pw.Divider(),
                  pw.SizedBox(height: 20),
                  pw.Text("Questions:", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  // Render Dynamic Questions if available
                  if (fullExam != null && fullExam!['questions'] != null)
                    ...List.generate((fullExam!['questions'] as List).length, (index) {
                      final q = fullExam!['questions'][index];
                       // Handle both Exam (questionText) and FiveMinTest (question) formats
                      final qText = q['questionText'] ?? q['question'] ?? "Question ${index + 1}";
                      return _buildQuestionItem(index + 1, qText);
                    })
                  else ...[
                    // Mock Questions (Generic for now, as history doesn't store full Q&A detailed list in this simple mock)
                    _buildQuestionItem(1, "Question 1 content placeholder..."),
                    _buildQuestionItem(2, "Question 2 content placeholder..."),
                    _buildQuestionItem(3, "Question 3 content placeholder..."),
                    _buildQuestionItem(4, "Question 4 content placeholder..."),
                    _buildQuestionItem(5, "Question 5 content placeholder..."),
                  ],
                ],
              ),
            ],
          );
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
