import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:printing/printing.dart'; // For PDF preview
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw; // For PDF generation
import 'dart:typed_data';

class ReadyReportingCardScreen extends StatefulWidget {
  const ReadyReportingCardScreen({super.key});

  @override
  State<ReadyReportingCardScreen> createState() => _ReadyReportingCardScreenState();
}

class _ReadyReportingCardScreenState extends State<ReadyReportingCardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange? _selectedDateRange;
  String _selectedSubject = "All";
  List<String> _subjects = ["All"];
  bool _isLoading = true;
  List<dynamic> _allExams = [];
  List<dynamic> _manualExams = [];
  List<dynamic> _appExams = [];
  String _remark = "Keep up the good work!"; // Default mock remark

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchExamData();
  }

  Future<void> _fetchExamData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null) {
        final response = await ApiService.getDashboardData();
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> results = data['examResults'] ?? [];
          
          // Extract unique subjects
          Set<String> subjectSet = {"All"};
          for (var exam in results) {
            if (exam['subject'] != null) {
              subjectSet.add(exam['subject']);
            }
          }

          setState(() {
            _allExams = results;
            _subjects = subjectSet.toList();
            _filterExams(); 
            _isLoading = false;
          });
        } else {
             setState(() => _isLoading = false);
        }
      } else {
           setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching exams: $e");
      setState(() => _isLoading = false);
    }
  }

  void _filterExams() {
    List<dynamic> filtered = _allExams;
    
    // Filter by Date Range
    if (_selectedDateRange != null) {
      filtered = filtered.where((exam) {
        final examDate = DateTime.tryParse(exam['date'] ?? "");
        if (examDate == null) return false;
        return examDate.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
            examDate.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Filter by Subject
    if (_selectedSubject != "All") {
      filtered = filtered.where((exam) => exam['subject'] == _selectedSubject).toList();
    }

    _appExams = filtered.where((e) => e['isOnline'] == true).toList();
    _manualExams = filtered.where((e) => e['isOnline'] == false).toList();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
        _filterExams();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: "Reporting Card",
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: "Manual Exam Mark"),
            Tab(text: "Application Exam Mark"),
          ],
        ),
        actions: [
            IconButton(
                icon: const Icon(Icons.print, color: Colors.white),
                onPressed: () => _generatePDF(context),
            )
        ],
      ),
      body: _isLoading
          ? const CustomLoader()
          : Column(
              children: [
                // Date Range and Subject Filter
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: colorScheme.surface,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDateRange == null
                                ? "Select Date Range"
                                : "${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.end)}",
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: colorScheme.onSurface),
                          ),
                          IconButton(
                            icon: Icon(Icons.calendar_month,
                                color: colorScheme.primary),
                            onPressed: () => _selectDateRange(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _subjects.length,
                          itemBuilder: (context, index) {
                            final subject = _subjects[index];
                            final isSelected = _selectedSubject == subject;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: FilterChip(
                                selected: isSelected,
                                label: Text(subject, style: GoogleFonts.poppins(fontSize: 12)),
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedSubject = subject;
                                    _filterExams();
                                  });
                                },
                                selectedColor: colorScheme.primary.withOpacity(0.2),
                                checkmarkColor: colorScheme.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildReportView(_manualExams),
                      _buildReportView(_appExams),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildReportView(List<dynamic> exams) {
    final colorScheme = Theme.of(context).colorScheme;
    if (exams.isEmpty) {
      return Center(child: Text("No exams found for this selection.", style: GoogleFonts.poppins()));
    }

    List<BarChartGroupData> barGroups = [];
    double totalMaxPercentage = 0;
    num totalObtained = 0;
    num totalPossible = 0;
    
    for (int i = 0; i < exams.length; i++) {
        final exam = exams[i];
        final obtained = (exam['obtainedMarks'] as num).toDouble();
        final total = (exam['totalMarks'] as num).toDouble();
        final percentage = total == 0 ? 0.0 : (obtained / total) * 100;
        
        totalObtained += exam['obtainedMarks'] as num;
        totalPossible += exam['totalMarks'] as num;

        if (percentage > totalMaxPercentage) totalMaxPercentage = percentage;

        barGroups.add(
            BarChartGroupData(
                x: i,
                barRods: [
                    // Obtained Mark Bar
                    BarChartRodData(
                        toY: obtained,
                        color: colorScheme.primary,
                        width: 8,
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                    ),
                    // Total Mark Bar (Gray/Black background effect)
                    BarChartRodData(
                        toY: total,
                        color: Colors.grey.withOpacity(0.3),
                        width: 8,
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                    ),
                ],
                barsSpace: 4,
            ),
        );
    }

    final double overAllPercentage = totalPossible == 0 ? 0 : (totalObtained / totalPossible) * 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem("Obtained Mark", colorScheme.primary),
              const SizedBox(width: 20),
              _buildLegendItem("Total Mark", Colors.grey.withOpacity(0.3)),
            ],
          ),
          const SizedBox(height: 16),
          // Bar Chart Section
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: colorScheme.surfaceContainerHigh,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                       final exam = exams[group.x.toInt()];
                       String label = rodIndex == 0 ? "Obtained: " : "Total: ";
                       return BarTooltipItem(
                         "$label${rod.toY}",
                         GoogleFonts.poppins(color: colorScheme.onSurface, fontSize: 12),
                       );
                    }
                  )
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < exams.length) {
                             String title = exams[index]['title'] ?? "";
                             if (title.length > 8) title = "${title.substring(0, 6)}..";
                             return Padding(
                               padding: const EdgeInsets.only(top: 8.0),
                               child: Text(title, style: const TextStyle(fontSize: 9)),
                             );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 35),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Performance Summary Card
          Container(
             width: double.infinity,
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(
                 color: colorScheme.surfaceContainer,
                 borderRadius: BorderRadius.circular(16),
                 border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
             ),
             child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                     Text("Performance Summary", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                     const SizedBox(height: 16),
                     _buildSummaryRow("Total Marks Obtained:", "$totalObtained/$totalPossible"),
                     _buildSummaryRow("Overall Percentage:", "${overAllPercentage.toStringAsFixed(1)}%"),
                     _buildSummaryRow("Highest Mark in Class:", "${exams.fold(0, (max, e) => (e['highestMark'] ?? 0) > max ? e['highestMark'] : max)}", isBold: true),
                     const Divider(height: 24),
                      Text("Professor's Remarks:", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text("\"$_remark\"", style: GoogleFonts.poppins(fontStyle: FontStyle.italic, color: colorScheme.onSurfaceVariant)),
                 ],
             ),
          ),

          const SizedBox(height: 24),

          // Detailed List (Table Style)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Exam Details", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
              Text("Scroll for more", style: GoogleFonts.poppins(fontSize: 10, color: colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: exams.length,
            itemBuilder: (context, index) {
              final exam = exams[index];
              final obtained = (exam['obtainedMarks'] as num).toDouble();
              final total = (exam['totalMarks'] as num).toDouble();
              final highest = (exam['highestMark'] as num? ?? 0).toDouble();
              final percentage = total == 0 ? 0.0 : (obtained / total) * 100;
              final grade = _calculateGrade(percentage);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(exam['title'] ?? "Unknown Exam", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(exam['subject'] ?? "General", style: GoogleFonts.poppins(fontSize: 12, color: colorScheme.primary)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getGradeColor(grade).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(grade, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: _getGradeColor(grade))),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatColumn("Obtained", "${obtained.toInt()}"),
                        _buildStatColumn("Total", "${total.toInt()}"),
                        _buildStatColumn("Highest", "${highest.toInt()}"),
                        _buildStatColumn("Per(%)", "${percentage.toStringAsFixed(1)}%"),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.poppins(fontSize: 11)),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 13)),
          Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }

  String _calculateGrade(double percentage) {
    if (percentage >= 90) return "A+";
    if (percentage >= 80) return "A";
    if (percentage >= 70) return "B+";
    if (percentage >= 60) return "B";
    if (percentage >= 50) return "C";
    return "F";
  }

  Color _getGradeColor(String grade) {
      if (grade.startsWith("A")) return Colors.green;
      if (grade.startsWith("B")) return Colors.blue;
      if (grade == "C") return Colors.orange;
      return Colors.red;
  }

  Future<void> _generatePDF(BuildContext context) async {
    final pdf = pw.Document();

    // Use filtered exams
    final exams = _tabController.index == 0 ? _manualExams : _appExams;
    final title = _tabController.index == 0 ? "Manual Exam Report" : "Application Exam Report";

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
               // Header
               pw.Row(
                   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                   children: [
                       pw.Column(
                         crossAxisAlignment: pw.CrossAxisAlignment.start,
                         children: [
                           pw.Text("Padhku", style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                           pw.Text("D. M. Bhatt Tuition Classes", style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                         ]
                       ),
                       pw.Column(
                           children: [
                               pw.BarcodeWidget(
                                   barcode: pw.Barcode.qrCode(),
                                   data: "https://play.google.com/store/apps/details?id=com.dmbhatt.tutions",
                                   width: 50,
                                   height: 50,
                               ),
                               pw.SizedBox(height: 4),
                               pw.Text("Scan to Download", style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                           ]
                       )
                   ]
               ),
               pw.Divider(thickness: 2, color: PdfColors.blue900),
               pw.SizedBox(height: 20),
               pw.Center(child: pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
               pw.SizedBox(height: 10),
               pw.Row(
                 mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                 children: [
                    if (_selectedDateRange != null)
                      pw.Text("Period: ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}", style: pw.TextStyle(fontSize: 10)),
                    pw.Text("Subject: $_selectedSubject", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                 ]
               ),
               
               pw.SizedBox(height: 24),

               // Table
               pw.Table.fromTextArray(
                   headers: ["Date", "Subject", "Paper Title", "Total Mark", "Obt. Mark", "High. Mark", "Per(%)", "Grade"],
                   data: exams.map((e) {
                       final obtained = (e['obtainedMarks'] as num).toDouble();
                       final total = (e['totalMarks'] as num).toDouble();
                       final highest = (e['highestMark'] as num? ?? 0).toDouble();
                       final percentage = total == 0 ? 0.0 : (obtained / total) * 100;
                       return [
                           DateFormat('dd MMM').format(DateTime.parse(e['date'] ?? DateTime.now().toIso8601String())),
                           e['subject'] ?? "General",
                           e['title'] ?? "",
                           "${total.toInt()}",
                           "${obtained.toInt()}",
                           "${highest.toInt()}",
                           "${percentage.toStringAsFixed(1)}%",
                           _calculateGrade(percentage)
                       ];
                   }).toList(),
                   headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                   headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
                   cellAlignment: pw.Alignment.centerLeft,
                   cellStyle: const pw.TextStyle(fontSize: 8),
                   headerHeight: 25,
                   cellHeight: 20,
                   columnWidths: {
                     0: const pw.FixedColumnWidth(40),
                     1: const pw.FixedColumnWidth(55),
                     2: const pw.FlexColumnWidth(),
                     3: const pw.FixedColumnWidth(40),
                     4: const pw.FixedColumnWidth(40),
                     5: const pw.FixedColumnWidth(40),
                     6: const pw.FixedColumnWidth(40),
                     7: const pw.FixedColumnWidth(30),
                   }
               ),

               pw.SizedBox(height: 30),
               pw.Container(
                 padding: const pw.EdgeInsets.all(10),
                 decoration: pw.BoxDecoration(
                   border: pw.Border.all(color: PdfColors.grey400),
                   borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                 ),
                 child: pw.Column(
                   crossAxisAlignment: pw.CrossAxisAlignment.start,
                   children: [
                     pw.Text("Professor's Remarks:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                     pw.SizedBox(height: 5),
                     pw.Text("\"$_remark\"", style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 10)),
                   ]
                 )
               ),

               pw.Spacer(),
               pw.Divider(color: PdfColors.grey400),
               pw.Row(
                 mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                 children: [
                   pw.Text("Generated via Padhku Student App", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                   pw.Text("Date: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                 ]
               ),
            ],
          );
        },
      ),
    );

    // Share/Print
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: "Padhku_Report_${_selectedSubject.replaceAll(' ', '_')}",
    );
  }
}
