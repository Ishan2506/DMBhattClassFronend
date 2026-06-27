import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'dart:io';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';

class MatchFollowingHistoryScreen extends StatefulWidget {
  final bool hideAppBar;
  const MatchFollowingHistoryScreen({super.key, this.hideAppBar = false});

  @override
  State<MatchFollowingHistoryScreen> createState() => _MatchFollowingHistoryScreenState();
}

class _MatchFollowingHistoryScreenState extends State<MatchFollowingHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _historyItems = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filteredHistoryItems() {
    if (_searchQuery.isEmpty) {
      return _historyItems;
    }
    return _historyItems.where((item) {
      final title = (item['title'] ?? '').toString().toLowerCase();
      return title.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getDashboardData();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['examResults'] ?? [];
        
        setState(() {
          _historyItems = results
              .where((e) => e['type'] == 'MATCH_FOLLOWING')
              .map((e) => e as Map<String, dynamic>)
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error loading match following history: $e");
      setState(() {
        _historyItems = [];
        _isLoading = false;
      });
    }
  }

  String _formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = months[dateTime.month - 1];
      final year = dateTime.year;
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return "$month $day, $year • $hour:$minute";
    } catch (_) {
      return isoString;
    }
  }

  String _getTranslation(BuildContext context, String key) {
    // only english language currenyly we are working on
    final locale = Localizations.localeOf(context).languageCode;
    const translations = {
      'en': {
        'title': 'Match the Following History',
        'noHistory': 'No history found.',
        'score': 'Score',
        'accuracy': 'Accuracy',
      },
      'gu': {
        'title': 'જોડકાં જોડો ઇતિહાસ',
        'noHistory': 'કોઈ ઇતિહાસ મળ્યો નથી.',
        'score': 'ગુણ',
        'accuracy': 'ચોકસાઈ',
      },
      'hi': {
        'title': 'मैच द फॉलोइंग इतिहास',
        'noHistory': 'कोई इतिहास नहीं मिला।',
        'score': 'स्कोर',
        'accuracy': 'सटीकता',
      },
      'mr': {
        'title': 'जुळवाजुळव इतिहास',
        'noHistory': 'काहीही इतिहास सापडला नाही.',
        'score': 'गुण',
        'accuracy': 'अचूकता',
      },
      'ta': {
        'title': 'பொருத்துக வரலாறு',
        'noHistory': 'வரலாறு ஏதும் கிடைக்கவில்லை.',
        'score': 'மதிப்பெண்',
        'accuracy': 'துல்லியம்',
      }
    };
    final langMap = translations[locale] ?? translations['en']!;
    return langMap[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: widget.hideAppBar ? null : CustomAppBar(
        title: _getTranslation(context, 'title'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchBar(context),
                Expanded(
                  child: _filteredHistoryItems().isEmpty
                      ? _buildEmptyState(isDark)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: _filteredHistoryItems().length,
                          itemBuilder: (context, index) {
                            final item = _filteredHistoryItems()[index];
                    final title = item['title'] ?? 'Matching Game';
                    final subject = item['subject'] ?? 'General';
                    final score = item['obtainedMarks'] ?? 0;
                    final total = item['totalMarks'] ?? 0;
                    final timestamp = item['date'] ?? item['createdAt'] ?? '';
                    final accuracy = total > 0 ? (score / total * 100).toInt() : 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                      color: isDark ? const Color(0xFF1E284A) : Colors.white,
                      child: InkWell(
                        onTap: () => _generateAndOpenPdf(context, item),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200, width: 1.5),
                          ),
                          child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            subject,
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _formatDateTime(timestamp),
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: isDark ? Colors.white38 : Colors.grey.shade500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      title,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.grey.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          "${_getTranslation(context, 'score')}: ",
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                                          ),
                                        ),
                                        Text(
                                          "$score / $total",
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: primary,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          "${_getTranslation(context, 'accuracy')}: ",
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                                          ),
                                        ),
                                        Text(
                                          "$accuracy%",
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: accuracy >= 80
                                                ? Colors.green
                                                : (accuracy >= 50 ? Colors.orange : Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                  },
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

  Future<void> _generateAndOpenPdf(BuildContext context, dynamic exam) async {
    final rawId = exam['examId'];
    final examId = rawId is Map ? rawId['_id']?.toString() : rawId?.toString();
    
    CustomLoader.show(context);
    try {
      Map<String, dynamic>? fullExam;
      if (examId != null && examId.isNotEmpty) {
        final response = await ApiService.getMatchFollowingExamById(examId);
        if (response.statusCode == 200) {
          fullExam = jsonDecode(response.body);
        }
      }

      if (context.mounted) {
        CustomLoader.hide(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MatchFollowingPdfViewer(
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
            builder: (context) => MatchFollowingPdfViewer(
               exam: exam is Map<String, dynamic> ? exam : Map<String, dynamic>.from(exam),
            ),
          ),
        );
      }
    }
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history_rounded,
            size: 64,
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _getTranslation(context, 'noHistory'),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class MatchFollowingPdfViewer extends StatelessWidget {
  final Map<String, dynamic> exam;
  final Map<String, dynamic>? fullExam;
  const MatchFollowingPdfViewer({super.key, required this.exam, this.fullExam});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: exam['title'] ?? "Match Following",
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
                  pw.Text("Padhaku", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text("Date: $formattedDate"),
                ]
              )
            ),
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text(exam['title'] ?? "Match Following Exam", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
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
            pw.Text("Questions (Pairs):", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            if (exam['answers'] != null && (exam['answers'] as List).isNotEmpty)
              ...List.generate((exam['answers'] as List).length, (index) {
                final ans = exam['answers'][index];
                final left = ans['left'] ?? "";
                String studentRight = ans['studentMatch'] ?? ans['right'] ?? "";
                String correctRight = ans['correctMatch'] ?? ans['correctRight'] ?? "";
                final isCorrect = ans['isCorrect'] == true;

                // Recover missing data using fullExam
                if (correctRight.isEmpty && fullExam != null && fullExam!['pairs'] != null) {
                  try {
                    final pair = (fullExam!['pairs'] as List).firstWhere(
                      (p) => p['left'] == left,
                      orElse: () => null,
                    );
                    if (pair != null) {
                      correctRight = pair['right'] ?? "";
                    }
                  } catch (e) {
                    // Ignore
                  }
                }

                if (studentRight.isEmpty && isCorrect) {
                  studentRight = correctRight;
                }

                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  child: _buildResultItem(index + 1, left, studentRight, correctRight, isCorrect),
                );
              })
            else if (fullExam != null && fullExam!['pairs'] != null)
              ...List.generate((fullExam!['pairs'] as List).length, (index) {
                final p = fullExam!['pairs'][index];
                final left = p['left'] ?? "";
                final right = p['right'] ?? "";
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: _buildQuestionItem(index + 1, left, right),
                );
              })
            else ...[
              pw.Padding(padding: const pw.EdgeInsets.only(bottom: 8), child: _buildQuestionItem(1, "Sample Left", "Sample Right")),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildQuestionItem(int number, String left, String right) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("$number. ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(left),
                pw.SizedBox(height: 4),
                pw.Text("Matches with: $right", style: pw.TextStyle(fontSize: 10, color: PdfColors.green)),
              ]
            )
          ),
        ],
      ),
    );
  }

  pw.Widget _buildResultItem(int number, String left, String studentRight, String correctRight, bool isCorrect) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("$number. ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(left, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Text("Your Answer: ", style: const pw.TextStyle(fontSize: 12)),
                    pw.Text(studentRight.isEmpty ? "(Not Answered)" : studentRight, style: pw.TextStyle(fontSize: 12, color: isCorrect ? PdfColors.green : PdfColors.red)),
                  ]
                ),
                if (!isCorrect)
                  pw.Text("(Correct: ${correctRight.isEmpty ? 'Not Available' : correctRight})", style: pw.TextStyle(fontSize: 11, color: PdfColors.green)),
              ]
            )
          ),
          pw.SizedBox(width: 10),
          pw.Text(
            isCorrect ? "CORRECT" : "WRONG",
            style: pw.TextStyle(
              color: isCorrect ? PdfColors.green : PdfColors.red,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            )
          ),
        ],
      ),
    );
  }
}
