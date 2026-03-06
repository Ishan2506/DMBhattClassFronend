import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
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
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/exam_history_data.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class StudentExamHistoryScreen extends StatefulWidget {
  const StudentExamHistoryScreen({super.key});

  @override
  State<StudentExamHistoryScreen> createState() => _StudentExamHistoryScreenState();
}

class _StudentExamHistoryScreenState extends State<StudentExamHistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _regularExams = [];
  List<dynamic> _fiveMinQuizzes = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      // Token managed internally
      final response = await ApiService.getDashboardData();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['examResults'] ?? [];
        
        setState(() {
          // Filter to only include appropriate types for each tab
          _regularExams = results.where((e) => 
            e['isOnline'] == true && e['type'] != 'ONELINER'
          ).toList();
          
          _fiveMinQuizzes = results.where((e) => 
            e['isOnline'] == false && e['type'] != 'ONELINER'
          ).toList(); 
          
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching history: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Fetch Data from Singleton
    final regularExams = ExamHistoryData().regularExams;
    final quizExams = ExamHistoryData().quizExams;

    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: CustomAppBar(
          title: l10n.examHistory,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(child: Text(l10n.regularExams, style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
              Tab(child: Text(l10n.fiveMinQuiz, style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
            ],
          ),
        ),
        body: _isLoading 
            ? const Center(child: CustomLoader())
            : TabBarView(
                children: [
                  _buildExamList(context, _regularExams),
                  _buildExamList(context, _fiveMinQuizzes),
                ],
              ),
      ),
    );
  }

  Widget _buildExamList(BuildContext context, List<dynamic> exams) {
    final colorScheme = Theme.of(context).colorScheme;

    if (exams.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return Center(
        child: Text(
          l10n.noExamsFound,
          style: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: exams.length,
      itemBuilder: (context, index) {
        final exam = exams[index];
        final DateTime date = exam['date'] != null ? DateTime.parse(exam['date']) : DateTime.now();
        final String formattedDate = DateFormat('MMM dd, yyyy').format(date);
        final String marks = "${exam['obtainedMarks']}/${exam['totalMarks']}";

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
              child: Icon(Icons.assignment, color: colorScheme.primary),
            ),
            title: Text(
              exam['title'] ?? (exam['isOnline'] == true ? AppLocalizations.of(context)!.regularExams : AppLocalizations.of(context)!.fiveMinQuiz),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
            ),
            subtitle: Text(
              AppLocalizations.of(context)!.dateLabel(formattedDate),
              style: GoogleFonts.poppins(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppLocalizations.of(context)!.marksLabel,
                  style: GoogleFonts.poppins(fontSize: 10, color: colorScheme.onSurfaceVariant),
                ),
                Text(
                  marks,
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
    // examId can be a plain string or a nested object like {'_id': '...'}
    final rawId = exam['examId'];
    final examId = rawId is Map ? rawId['_id']?.toString() : rawId?.toString();

    CustomLoader.show(context);
    try {
      Map<String, dynamic>? fullExam;

      if (examId != null && examId.isNotEmpty) {
        final bool isOnline = exam['isOnline'] ?? true;
        final response = isOnline
            ? await ApiService.getExamById(examId)
            : await ApiService.getFiveMinTestById(examId);

        debugPrint("Exam fetch: ${response.statusCode} for examId=$examId");

        if (response.statusCode == 200) {
          fullExam = jsonDecode(response.body) as Map<String, dynamic>;
        } else {
          // 404 = exam was deleted from server — just show history data (no questions)
          // Other errors — log but still show what we have
          debugPrint("Exam fetch non-200: ${response.statusCode} — ${response.body}");
        }
      }

      // Always open the PDF viewer with whatever data we have
      if (context.mounted) {
        CustomLoader.hide(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExamPdfViewer(
              exam: exam,
              fullExam: fullExam, // null = no questions section shown
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomLoader.hide(context);
        CustomToast.showError(context, "Error: $e");
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
            tooltip: AppLocalizations.of(context)!.download,
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => _sharePdf(context),
             tooltip: AppLocalizations.of(context)!.shareProtected,
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
          final l10n = AppLocalizations.of(context)!;
          CustomToast.showSuccess(context, l10n.downloadedTo(file.path));
        }
      }
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        CustomToast.showError(context, l10n.downloadFailed(e.toString()));
      }
    }
  }

  Future<void> _sharePdf(BuildContext context) async {
    try {
      // Generate normal PDF (Unencrypted)
      final bytes = await _generateExamPdf(PdfPageFormat.a4, exam);
      
      if (context.mounted) {
         final l10n = AppLocalizations.of(context)!;
         CustomToast.showSuccess(context, l10n.sharingPdf);
      }
      
      await Printing.sharePdf(bytes: bytes, filename: '${exam['title']}.pdf');
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        CustomToast.showError(context, l10n.shareFailed(e.toString()));
      }
    }
  }

  Future<Uint8List> _generateExamPdf(PdfPageFormat format, Map<String, dynamic> exam) async {
    final pdf = pw.Document();
    
    // Load Logo for Watermark
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
          return [
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
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: _buildQuestionItem(index + 1, qText),
                );
              })
            else ...[
              // Fallback to Mock Questions if no detailed data
              pw.Padding(padding: const pw.EdgeInsets.only(bottom: 8), child: _buildQuestionItem(1, "Explain the laws of motion.")),
              pw.Padding(padding: const pw.EdgeInsets.only(bottom: 8), child: _buildQuestionItem(2, "What is photosynthesis?")),
              pw.Padding(padding: const pw.EdgeInsets.only(bottom: 8), child: _buildQuestionItem(3, "Solve: 2x + 5 = 15")),
              pw.Padding(padding: const pw.EdgeInsets.only(bottom: 8), child: _buildQuestionItem(4, "Define Kinetic Energy.")),
              pw.Padding(padding: const pw.EdgeInsets.only(bottom: 8), child: _buildQuestionItem(5, "Write a short note on Indian Constitution.")),
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
