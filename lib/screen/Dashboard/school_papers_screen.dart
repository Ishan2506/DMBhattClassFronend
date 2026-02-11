import 'package:dm_bhatt_tutions/utils/guest_utils.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/pdf_preview_screen.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SchoolPapersScreen extends StatefulWidget {
  const SchoolPapersScreen({super.key});

  @override
  State<SchoolPapersScreen> createState() => _SchoolPapersScreenState();
}

class _SchoolPapersScreenState extends State<SchoolPapersScreen> {
  String? _selectedSubject;
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    _checkGuestStatus();
  }

  Future<void> _checkGuestStatus() async {
    _isGuest = await GuestUtils.isGuest();
    if (mounted) setState(() {});
  }
  final List<String> _subjects = [
    "Mathematics",
    "Science", 
    "English",
    "Gujarati",
    "Social Science",
    "Hindi",
    "Sanskrit",
    "Computer"
  ];

  // Mock Data
  final List<Map<String, dynamic>> _allPapers = [
    {
      "id": "1",
      "name": "Unit Test 1 - Maths",
      "subject": "Mathematics",
      "date": "10 Aug 2025",
      "image": "https://pdfobject.com/pdf/sample.pdf", // Mock PDF
    },
    {
      "id": "2",
      "name": "Mid Term - Maths",
      "subject": "Mathematics",
      "date": "15 Oct 2025",
      "image": "https://pdfobject.com/pdf/sample.pdf",
    },
    {
      "id": "3",
      "name": "Chapter 5 Worksheet",
      "subject": "Science",
      "date": "12 Sep 2025",
      "image": "https://pdfobject.com/pdf/sample.pdf",
    },
    {
      "id": "4",
      "name": "English Grammar Test",
      "subject": "English",
      "date": "05 Nov 2025",
      "image": "https://pdfobject.com/pdf/sample.pdf",
    },
  ];

  List<Map<String, dynamic>> _displayPapers = [];

  void _filterPapers() {
    if (_selectedSubject == null) {
      setState(() {
        _displayPapers = [];
      });
      return;
    }
    setState(() {
      _displayPapers = _allPapers.where((p) => p['subject'] == _selectedSubject).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: l10n.schoolPapers,
        centerTitle: true, 
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.selectSubject, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedSubject,
                    hint: Text(l10n.selectSubject, style: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant)),
                    items: _subjects.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) {
                      _selectedSubject = val;
                      _filterPapers();
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: theme.cardColor,
                    ),
                    style: GoogleFonts.poppins(color: colorScheme.onSurface),
                    dropdownColor: theme.cardColor,
                    icon: Icon(Icons.arrow_drop_down, color: colorScheme.onSurface),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // Results Section
            if (_selectedSubject == null)
               Center(
                 child: Padding(
                   padding: const EdgeInsets.only(top: 40),
                   child: Column(
                     children: [
                       Icon(Icons.subject, size: 64, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
                       const SizedBox(height: 16),
                       Text(l10n.selectStandardMediumError, style: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant)), // Generic msg if needed
                     ],
                   ),
                 ),
               )
            else if (_displayPapers.isEmpty)
               Center(
                 child: Padding(
                   padding: const EdgeInsets.only(top: 40),
                   child: Column(
                     children: [
                       Icon(Icons.description_outlined, size: 64, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
                       const SizedBox(height: 16),
                       Text("${l10n.noExamsFound} ${l10n.forLabel} $_selectedSubject", style: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant)),
                     ],
                   ),
                 ),
               )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${l10n.availablePapers} (${_displayPapers.length})", // Corrected
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 12),
                  ..._displayPapers.map((paper) => _buildPaperCard(paper, theme)).toList(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaperCard(Map<String, dynamic> paper, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paper['name'],
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: colorScheme.onSurface),
                ),
                Text(
                  paper['date'],
                  style: GoogleFonts.poppins(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          
          // View Button
          IconButton(
            icon: Icon(Icons.visibility_outlined, color: colorScheme.primary),
            onPressed: () {
               if (_isGuest) {
                  GuestUtils.showGuestRestrictionDialog(context, message: "Register to view school papers!");
                  return;
               }
               Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfPreviewScreen(product: paper),
                  ),
                );
            },
            tooltip: l10n.view,
          ),
          
          // Download Button
          IconButton(
            icon: Icon(Icons.download_rounded, color: colorScheme.secondary),
            onPressed: () {
               if (_isGuest) {
                  GuestUtils.showGuestRestrictionDialog(context, message: "Register to download school papers!");
                  return;
               }
               CustomToast.showSuccess(context, "Downloading ${paper['name']}...");
               // Implement download logic here
            },
             tooltip: l10n.download,
          ),
        ],
      ),
    );
  }
}
