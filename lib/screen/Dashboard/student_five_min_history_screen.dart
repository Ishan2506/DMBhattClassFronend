
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/pdf_preview_screen.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class StudentFiveMinHistoryScreen extends StatefulWidget {
  const StudentFiveMinHistoryScreen({super.key});

  @override
  State<StudentFiveMinHistoryScreen> createState() => _StudentFiveMinHistoryScreenState();
}

class _StudentFiveMinHistoryScreenState extends State<StudentFiveMinHistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _quizExams = [];
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
      final response = await ApiService.getDashboardData();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['examResults'] ?? [];
        
        setState(() {
          _quizExams = results.where((e) => e['type'] == 'QUIZ').toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching 5-min history: $e");
      setState(() => _isLoading = false);
    }
  }

  List<dynamic> _filteredExams() {
    if (_searchQuery.isEmpty) {
      return _quizExams;
    }
    return _quizExams.where((exam) {
      final title = (exam['title'] ?? "").toString().toLowerCase();
      return title.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(
        title: "5 Min Test History",
        centerTitle: true,
      ),
      body: _isLoading 
          ? const Center(child: CustomLoader())
          : Column(
              children: [
                _buildSearchBar(context),
                Expanded(child: _buildExamList(context, _filteredExams())),
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
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: "Search by title...",
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = "";
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: colorScheme.surfaceContainer,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildExamList(BuildContext context, List<dynamic> exams) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        final DateTime date = exam['date'] != null ? DateTime.parse(exam['date']).toLocal() : DateTime.now();
        final String formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(date);
        final String marks = "${exam['obtainedMarks']}/${exam['totalMarks']}";

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
            onTap: () => _generateAndOpenPdf(context, exam),
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.timer, color: colorScheme.primary),
            ),
            title: Text(
              exam['title'] ?? "5-min Quiz",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
            ),
            subtitle: Text(
              "Date: $formattedDate",
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

  Future<void> _generateAndOpenPdf(BuildContext context, dynamic exam) async {
    final rawId = exam['examId'];
    final examId = rawId is Map ? rawId['_id']?.toString() : rawId?.toString();
    
    CustomLoader.show(context);
    try {
      Map<String, dynamic>? fullExam;
      if (examId != null && examId.isNotEmpty) {
        final response = await ApiService.getFiveMinTestById(examId);
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

class ExamPdfViewer extends StatefulWidget {
  final Map<String, dynamic> exam;
  final Map<String, dynamic>? fullExam;
  const ExamPdfViewer({super.key, required this.exam, this.fullExam});

  @override
  State<ExamPdfViewer> createState() => _ExamPdfViewerState();
}

class _ExamPdfViewerState extends State<ExamPdfViewer> {
  Uint8List? _pdfBytes;
  bool _isLoading = true;

  Map<String, dynamic> get exam => widget.exam;
  Map<String, dynamic>? get fullExam => widget.fullExam;

  @override
  void initState() {
    super.initState();
    _buildPdf();
  }

  Future<void> _buildPdf() async {
    try {
      final bytes = await _generateExamPdf(PdfPageFormat.a4, exam);
      if (mounted) {
        setState(() {
          _pdfBytes = bytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error generating exam PDF: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _pdfBytes == null) {
      return Scaffold(
        appBar: CustomAppBar(title: exam['title']),
        body: const Center(child: CustomLoader()),
      );
    }

    return PdfPreviewScreen(
      product: {
        'name': exam['title'],
        'id': exam['examId'] is Map ? exam['examId']['_id'] : exam['examId'],
      },
      pdfBytes: _pdfBytes,
      isFullAccess: true,
    );
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
          final DateTime date = exam['date'] != null ? DateTime.parse(exam['date']) : DateTime.now();
          final String formattedDate = DateFormat('MMM dd, yyyy').format(date);

          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Padhaku", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
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
               child: pw.Text(
                "Marks Obtained: ${exam['obtainedMarks']}/${exam['totalMarks']}",
                style: const pw.TextStyle(fontSize: 16),
              ),
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
