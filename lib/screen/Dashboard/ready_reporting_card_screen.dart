import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
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
        final response = await ApiService.getDashboardData(token);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> results = data['examResults'] ?? [];
          setState(() {
            _allExams = results;
            _filterExams(); 
            _isLoading = false;
          });
        } else {
             // Handle error
             setState(() => _isLoading = false);
        }
      } else {
          // Handle no token
           setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching exams: $e");
      setState(() => _isLoading = false);
    }
  }

  void _filterExams() {
    // Filter by date range if selected
    List<dynamic> filtered = _allExams;
    if (_selectedDateRange != null) {
      filtered = _allExams.where((exam) {
        final examDate = DateTime.tryParse(exam['date'] ?? "");
        if (examDate == null) return false;
        return examDate.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
            examDate.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
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
        title: "Reporting Card", // TODO: Add to l10n
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(text: "Manual Exam Mark"), // TODO: Add to l10n
            Tab(text: "Application Exam Mark"), // TODO: Add to l10n
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
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDateRange == null
                            ? "Select Date Range" // TODO: Add to l10n
                            : "${DateFormat('MMM dd').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd').format(_selectedDateRange!.end)}",
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface),
                      ),
                      IconButton(
                        icon: Icon(Icons.calendar_month,
                            color: colorScheme.primary),
                        onPressed: () => _selectDateRange(context),
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
    if (exams.isEmpty) {
      return Center(child: Text("No exams found for this period.", style: GoogleFonts.poppins()));
    }

    // Prepare chart data
    // Simply mapping index to x, percentage to y
    List<BarChartGroupData> barGroups = [];
    double maxPercentage = 0;
    
    for (int i = 0; i < exams.length; i++) {
        final exam = exams[i];
        final obtained = (exam['obtainedMarks'] as num).toDouble();
        final total = (exam['totalMarks'] as num).toDouble();
        final percentage = total == 0 ? 0.0 : (obtained / total) * 100;
        
        if (percentage > maxPercentage) maxPercentage = percentage;

        barGroups.add(
            BarChartGroupData(
                x: i,
                barRods: [
                    BarChartRodData(
                        toY: percentage,
                        color: percentage >= 90 ? Colors.green : (percentage >= 50 ? Colors.blue : Colors.red),
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                    ),
                ],
            ),
        );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bar Chart Section
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < exams.length) {
                             String title = exams[index]['title'] ?? "";
                             if (title.length > 5) title = "${title.substring(0, 5)}...";
                             return Padding(
                               padding: const EdgeInsets.only(top: 8.0),
                               child: Text(title, style: const TextStyle(fontSize: 10)),
                             );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: true),
                barGroups: barGroups,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Highest Mark & Grade Section
          Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(
                 color: Theme.of(context).colorScheme.surfaceContainer,
                 borderRadius: BorderRadius.circular(12),
             ),
             child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                     Text("Performance Summary", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                     const SizedBox(height: 12),
                     Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                             Text("Highest Percentage:", style: GoogleFonts.poppins()),
                             Text("${maxPercentage.toStringAsFixed(1)}%", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.green)),
                         ],
                     ),
                     const Divider(),
                      Text("Remarks:", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("Professor: $_remark", style: GoogleFonts.poppins(fontStyle: FontStyle.italic)),
                 ],
             ),
          ),

          const SizedBox(height: 24),

          // Detailed List
          Text("Exam Details", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: exams.length,
            itemBuilder: (context, index) {
              final exam = exams[index];
              final obtained = (exam['obtainedMarks'] as num).toDouble();
              final total = (exam['totalMarks'] as num).toDouble();
              final percentage = total == 0 ? 0.0 : (obtained / total) * 100;
              final grade = _calculateGrade(percentage);

              return Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(8)),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(exam['title'] ?? "Unknown Exam", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  subtitle: Text(DateFormat('MMM dd, yyyy').format(DateTime.parse(exam['date'] ?? DateTime.now().toIso8601String()))),
                  trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                          Text("${percentage.toStringAsFixed(1)}%", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                          Text("Grade: $grade", style: GoogleFonts.poppins(fontSize: 12, color: _getGradeColor(grade))),
                      ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
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

    // Use current tab's exams
    final exams = _tabController.index == 0 ? _manualExams : _appExams;
    final title = _tabController.index == 0 ? "Manual Exam Report" : "Application Exam Report";

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
               // Header
               pw.Row(
                   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                   children: [
                       pw.Text("Padhku", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                       // Scan QR to download app
                       pw.Column(
                           children: [
                               pw.BarcodeWidget(
                                   barcode: pw.Barcode.qrCode(),
                                   data: "https://play.google.com/store/apps/details?id=com.dmbhatt.tutions", // App Link
                                   width: 60,
                                   height: 60,
                               ),
                               pw.Text("Scan to Download App", style: const pw.TextStyle(fontSize: 8)),
                           ]
                       )
                   ]
               ),
               pw.Divider(),
               pw.SizedBox(height: 20),
               pw.Center(child: pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
               pw.SizedBox(height: 10),
               if (_selectedDateRange != null)
                   pw.Center(child: pw.Text("Period: ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}")),
               
               pw.SizedBox(height: 20),

               // Table
               pw.Table.fromTextArray(
                   headers: ["Date", "Exam Title", "Obtained/Total", "Percentage", "Grade"],
                   data: exams.map((e) {
                       final obtained = (e['obtainedMarks'] as num).toDouble();
                       final total = (e['totalMarks'] as num).toDouble();
                       final percentage = total == 0 ? 0.0 : (obtained / total) * 100;
                       return [
                           DateFormat('dd MMM').format(DateTime.parse(e['date'] ?? DateTime.now().toIso8601String())),
                           e['title'] ?? "",
                           "${obtained.toInt()}/${total.toInt()}",
                           "${percentage.toStringAsFixed(1)}%",
                           _calculateGrade(percentage)
                       ];
                   }).toList(),
                   headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                   headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                   cellAlignment: pw.Alignment.centerLeft,
               ),

               pw.Spacer(),
               pw.Divider(),
               pw.Text("Report Generated on: ${DateFormat('dd MMM yyyy').format(DateTime.now())}", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
            ],
          );
        },
      ),
    );

    // Share/Print
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
