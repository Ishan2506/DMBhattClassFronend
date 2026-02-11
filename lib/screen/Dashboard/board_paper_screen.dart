import 'package:dm_bhatt_tutions/utils/guest_utils.dart';
import 'dart:convert';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final List<String> _years = List.generate(10, (index) => (DateTime.now().year - index).toString());
  final List<String> _subjects = ["Mathematics", "Science", "English", "Social Science", "Gujarati", "Physics", "Chemistry", "Biology", "Accounts", "Statistics"];
  String? _selectedSubject;

  bool _isLoading = false;
  bool _isProfileLoading = true;
  bool _isGuest = false;
  List<dynamic> _papers = [];
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    setState(() => _isProfileLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final response = await ApiService.getProfile(token);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final profile = data['profile'];
        if (profile != null) {
          setState(() {
            _selectedMedium = profile['medium'];
            _selectedStd = profile['std'];
            // Attempt to get stream if available or if std implies it (though API might not return it explicitly if not saved)
            // For now, if std is 12, we might need a way to know stream. 
            // Assuming profile might have 'stream' field or similar, or we just have to hope it's there.
            // If not present in profile, we can't set it. 
            _selectedStream = profile['stream']; 
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    } finally {
      _isGuest = await GuestUtils.isGuest();
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
                     child: Column(
                       children: [
                         Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
                         const SizedBox(height: 16),
                         Text(l10n.noPapersFound, style: GoogleFonts.poppins(color: Colors.grey)),
                       ],
                     ),
                   )
                else if (_papers.any((p) => p['subject'] == _selectedSubject) && !_isLoading) ...[
                   Text(
                     "${l10n.availablePapers} (${_papers.where((p) => p['subject'] == _selectedSubject).length})",
                     style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                   ),
                   const SizedBox(height: 12),
                   ..._papers.where((p) => p['subject'] == _selectedSubject).map((paper) => _buildPaperCard(paper, colorScheme, isDark)).toList()
                ]
                else if (_hasSearched && !_isLoading)
                   Center(
                     child: Column(
                       children: [
                         Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade400),
                         const SizedBox(height: 16),
                         Text("${l10n.noExamsFound} ${l10n.forLabel} $_selectedSubject", style: GoogleFonts.poppins(color: Colors.grey)),
                       ],
                     ),
                   ),
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
    // Note: Loader logic moved to Stack in build method
    
    // if (_isProfileLoading) {
    //    return const CustomLoader();
    // }
    
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
          Text(l10n.selectSubject, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)), // Generic
          const SizedBox(height: 16),
          
          if (_selectedMedium != null && _selectedStd != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
              ),
              child: Text(
                "${_selectedStd}${l10n.th} - $_selectedMedium ${l10n.medium}${_selectedStream != null ? ' ($_selectedStream)' : ''}",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: colorScheme.primary),
                textAlign: TextAlign.center,
              ),
            ),

          // Year Dropdown
          _buildDropdown(
            l10n.year, 
            _years, 
            _selectedYear, 
            (val) => setState(() => _selectedYear = val)
          ),
          const SizedBox(height: 12),
          
          // Subject Dropdown
          _buildDropdown(
            l10n.subject, 
            _subjects, 
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
              child: Text(AppLocalizations.of(context)!.apply, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)), // Or findPapers
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
          // View Button
          IconButton(
            icon: Icon(Icons.visibility_outlined, color: colorScheme.primary),
            onPressed: () {
               if (_isGuest) {
                  GuestUtils.showGuestRestrictionDialog(context, message: "Register to view board papers!");
                  return;
               }
               // Ensure paper map has 'image' key for PdfPreviewScreen
               final pdfPaper = Map<String, dynamic>.from(paper);
               if (pdfPaper['image'] == null) pdfPaper['image'] = pdfPaper['url'];
               
               Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfPreviewScreen(product: pdfPaper),
                  ),
                );
            },
          ),
          // Download Button
          IconButton(
            icon: Icon(Icons.download_rounded, color: colorScheme.secondary),
            onPressed: () {
              if (_isGuest) {
                  GuestUtils.showGuestRestrictionDialog(context, message: "Register to download board papers!");
                  return;
              }
              _launchURL(paper['url'] ?? ""); 
            }, 
          ),
        ],
      ),
    );
  }

  Future<void> _validateAndFetch() async {
    // Basic validation
    if (_selectedMedium == null || _selectedStd == null) {
       CustomToast.showError(context, AppLocalizations.of(context)!.registrationFailed); // Generic profile error
       return;
    }
    
    if (_selectedSubject == null || _selectedYear == null) {
       CustomToast.showError(context, AppLocalizations.of(context)!.selectStandardMediumError);
       return;
    }

     if (_selectedStd == "12" && _selectedStream == null) {
        // If stream is missing from profile, we might still want to proceed or error out.
        // For now, let's warn.
        CustomToast.showError(context, AppLocalizations.of(context)!.selectStreamError);
        return;
     }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _papers = [];
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // Use API Service
      final response = await ApiService.getBoardPapers(
        token: token ?? "",
        medium: _selectedMedium!,
        std: _selectedStd!,
        stream: _selectedStream, // Can be null
        year: _selectedYear!,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _papers = data['papers'] ?? []; // Adjust key based on actual API
        });
        if (_papers.isEmpty) {
           CustomToast.showSuccess(context, AppLocalizations.of(context)!.noExamsFound);
        }
      } else {
         CustomToast.showError(context, "Failed to fetch papers");
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
