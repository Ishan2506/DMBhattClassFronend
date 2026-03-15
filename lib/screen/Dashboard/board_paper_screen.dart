import 'dart:convert';
import 'package:dm_bhatt_tutions/utils/academic_constants.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/pdf_preview_screen.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';

class BoardPaperScreen extends StatefulWidget {
  const BoardPaperScreen({super.key});

  @override
  State<BoardPaperScreen> createState() => _BoardPaperScreenState();
}

class _BoardPaperScreenState extends State<BoardPaperScreen> {
  // Filter States
  String? _selectedMedium;
  String? _selectedStd;
  String? _selectedStream;
  String? _selectedYear;

  final List<String> _mediums = ["Gujarati", "English"];
  final List<String> _stds = ["10", "12"];
  final List<String> _streams = ["Science", "Commerce", "Arts"]; // Only for 12
  final List<String> _years = List.generate(10, (index) => (DateTime.now().year - 1 - index).toString());
  String? _selectedSubject;

  String? _userBoard;

  List<String> _getFilteredSubjects() {
    return AcademicConstants.getSubjectsForStudent(
      board: _userBoard,
      std: _selectedStd,
      stream: _selectedStream,
    );
  }

  bool _isLoading = false;
  bool _isProfileLoading = true;
  List<dynamic> _papers = [];
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    setState(() => _isProfileLoading = true);
    final prefs = await SharedPreferences.getInstance();
    
    // Load initial values from prefs
    final profileFromPrefs = {
      'board': prefs.getString('board'),
      'std': prefs.getString('std'),
      'stream': prefs.getString('stream'),
      'medium': prefs.getString('medium'),
    };

    try {
      final response = await ApiService.getProfile(forceRefresh: true);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'];
        final profile = data['profile'];
        
        final board = user?['board'] ?? profile?['board'] ?? profileFromPrefs['board'];
        final studentStd = user?['std']?.toString() ?? profile?['std']?.toString() ?? profileFromPrefs['std'];
        final studentStream = user?['stream'] ?? profile?['stream'] ?? profileFromPrefs['stream'];
        final medium = user?['medium'] ?? profile?['medium'] ?? profileFromPrefs['medium'];

        String validBoardStd = '';
        if (studentStd != null) {
          final match = RegExp(r'(\d+)').firstMatch(studentStd);
          if (match != null) {
            final num = match.group(1);
            if (num == '10' || num == '12') validBoardStd = num!;
          }
        }

        if (mounted) {
          setState(() {
            _selectedMedium = medium;
            _selectedStd = validBoardStd;
            _selectedStream = (validBoardStd == '12') ? studentStream : null;
            _userBoard = board;
          });
        }

        // Sync back to SharedPreferences if we got data
        if (studentStd != null) await prefs.setString('std', studentStd);
        if (studentStream != null) await prefs.setString('stream', studentStream);
        if (board != null) await prefs.setString('board', board);
        if (medium != null) await prefs.setString('medium', medium);
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    } finally {
      if (mounted) setState(() => _isProfileLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: l10n.boardPapers,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilterCard(colorScheme, isDark),
                const SizedBox(height: 24),
                
                if (_hasSearched && _papers.isEmpty && !_isLoading)
                   Center(
                     child: Padding(
                       padding: const EdgeInsets.only(top: 40),
                       child: Column(
                         children: [
                           Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
                           const SizedBox(height: 16),
                           const Text("No papers found for this search", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                         ],
                       ),
                     ),
                   )
                else if (_hasSearched && _papers.isNotEmpty && !_isLoading) ...[
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                        Text(
                          "${l10n.availablePapers} (${_papers.where((p) => _selectedSubject == null || p['subject'] == _selectedSubject).length})",
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                        ),
                        const SizedBox(height: 12),
                        ..._papers.where((p) => _selectedSubject == null || p['subject'] == _selectedSubject).map((paper) => _buildPaperCard(paper, colorScheme, isDark)).toList(),
                        if (_papers.where((p) => _selectedSubject == null || p['subject'] == _selectedSubject).isEmpty)
                           Center(
                             child: Padding(
                               padding: const EdgeInsets.only(top: 20),
                               child: Text("No papers found for $_selectedSubject", style: GoogleFonts.poppins(color: Colors.grey)),
                             ),
                           ),
                     ],
                   )
                ],
              ],
            ),
          ),
          if (_isLoading || _isProfileLoading)
            const Center(child: CustomLoader()),
        ],
      ),
    );
  }

  Widget _buildFilterCard(ColorScheme colorScheme, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
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
          Text(l10n.selectSubject, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  l10n.medium, 
                  _mediums, 
                  _selectedMedium, 
                  (val) => setState(() => _selectedMedium = val)
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  l10n.standard, 
                  _stds.map((e) => "$e${l10n.th}").toList(), 
                  _selectedStd != null ? "$_selectedStd${l10n.th}" : null, 
                  (val) => setState(() {
                    _selectedStd = val?.replaceAll(l10n.th, "");
                    _selectedSubject = null; // Reset subject when std changes
                    _selectedStream = null;  // Reset stream when std changes
                  })
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_selectedStd == "12")
            _buildDropdown(
              l10n.stream, 
              _streams, 
              _selectedStream, 
              (val) => setState(() {
                _selectedStream = val;
                _selectedSubject = null; // Reset subject when stream changes
              })
            ),
          if (_selectedStd == "12") const SizedBox(height: 12),

          _buildDropdown(
            l10n.year, 
            _years, 
            _selectedYear, 
            (val) => setState(() => _selectedYear = val)
          ),
          const SizedBox(height: 12),
          
          _buildDropdown(
            l10n.subject, 
            _getFilteredSubjects(), 
            _selectedSubject, 
            (val) => setState(() => _selectedSubject = val)
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _validateAndFetch,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(l10n.apply, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).cardColor,
      ),
      style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodyMedium?.color),
      dropdownColor: Theme.of(context).cardColor,
    );
  }

  Widget _buildPaperCard(dynamic paper, ColorScheme colorScheme, bool isDark) {
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
                  paper['title'] ?? paper['name'] ?? AppLocalizations.of(context)!.boardPapers, 
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                Text(
                  "${paper['subject'] ?? 'Subject'} • ${paper['year'] ?? ''}",
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.visibility_outlined, color: colorScheme.primary),
            onPressed: () async {
               final productId = paper['_id']?.toString() ?? paper['id']?.toString() ?? paper['title'] ?? paper['name'];
               final prefs = await SharedPreferences.getInstance();
               final alreadyUsed = prefs.getBool('preview_used_$productId') ?? false;

               if (alreadyUsed) {
                 if (!mounted) return;
                 CustomToast.showError(context, "Free preview already used for this paper. Please purchase to view.");
                 return;
               }

               final pdfPaper = Map<String, dynamic>.from(paper);
               if (pdfPaper['image'] == null) pdfPaper['image'] = pdfPaper['file'] ?? pdfPaper['url'];
               
               if (!mounted) return;
               Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfPreviewScreen(product: pdfPaper),
                  ),
                );
            },
          ),
          IconButton(
            icon: Icon(Icons.download_rounded, color: colorScheme.secondary),
            onPressed: () {
              _launchURL(paper['file'] ?? paper['url'] ?? ""); 
            }, 
          ),
        ],
      ),
    );
  }

  Future<void> _validateAndFetch() async {
    if (_selectedMedium == null || _selectedStd == null) {
       CustomToast.showError(context, "Please select Medium and Standard");
       return;
    }
    if (_selectedYear == null) {
       CustomToast.showError(context, "Please select Year");
       return;
    }
     if (_selectedStd == "12" && _selectedStream == null) {
        CustomToast.showError(context, AppLocalizations.of(context)!.selectStreamError);
        return;
     }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _papers = [];
    });

    try {
      final response = await ApiService.getBoardPapers(
        medium: _selectedMedium!,
        std: _selectedStd!,
        stream: _selectedStream,
        year: _selectedYear!,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _papers = data; // Backend returns a list of materials直接
        });
        if (_papers.isEmpty) {
           CustomToast.showSuccess(context, AppLocalizations.of(context)!.noPapersFound);
        }
      } else {
         CustomToast.showError(context, "Failed to fetch papers: ${ApiService.getErrorMessage(response.body)}");
      }
    } catch (e) {
      CustomToast.showError(context, "Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchURL(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      CustomToast.showError(context, AppLocalizations.of(context)!.downloadFailed("PDF"));
    }
  }
}
