import 'dart:convert';
import 'package:dm_bhatt_tutions/utils/academic_constants.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/utils/guest_utils.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/pdf_preview_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/upgrade_plan_screen.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SchoolPapersScreen extends StatefulWidget {
  const SchoolPapersScreen({super.key});

  @override
  State<SchoolPapersScreen> createState() => _SchoolPapersScreenState();
}

class _SchoolPapersScreenState extends State<SchoolPapersScreen> {
  String? _selectedSubject;
  bool _isGuest = false;
  bool _isPaid = false;
  String? _std;
  String? _stream;
  String? _board;

  @override
  void initState() {
    super.initState();
    _loadProfileAndCheckGuest();
  }

  Future<void> _loadProfileAndCheckGuest() async {
    _isGuest = await GuestUtils.isGuest();
    final prefs = await SharedPreferences.getInstance();

    if (!_isGuest) {
      try {
        final profileResponse = await ApiService.getProfile(forceRefresh: true);
        if (profileResponse.statusCode == 200) {
          final profileData = jsonDecode(profileResponse.body);
          final user = profileData['user'];
          final profile = profileData['profile'];
          
          if (mounted) {
            setState(() {
              _isPaid = user?['isPaid'] ?? false;
              // Priority: Profile API User Object > Profile API Profile Object > SharedPreferences
              _std = user?['std']?.toString() ?? profile?['std']?.toString() ?? prefs.getString('std');
              _stream = user?['stream'] ?? profile?['stream'] ?? prefs.getString('stream');
              _board = user?['board'] ?? profile?['board'] ?? prefs.getString('board');
            });
          }

          // Sync back to SharedPreferences if missing
          if (_std != null) await prefs.setString('std', _std!);
          if (_stream != null) await prefs.setString('stream', _stream!);
          if (_board != null) await prefs.setString('board', _board!);
        }
      } catch (e) {
        debugPrint("Error fetching profile: $e");
      }
    }

    // Fallback/Ensure values from Prefs if guest or API failed
    _std ??= prefs.getString('std');
    _stream ??= prefs.getString('stream');
    _board ??= prefs.getString('board');

    if (mounted) setState(() {});
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Premium Material", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          "This school paper is part of our premium content. Please upgrade your plan to access all papers and materials.",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Maybe Later", style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UpgradePlanScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text("Upgrade Now", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  List<String> _getFilteredSubjects() {
    return AcademicConstants.getSubjectsForStudent(
      board: _board,
      std: _std,
      stream: _stream,
    );
  }
  
  bool _isLoading = false;
  List<dynamic> _displayPapers = [];

  Future<void> _filterPapers() async {
    if (_selectedSubject == null) {
      setState(() {
        _displayPapers = [];
      });
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getSchoolPapers(subject: _selectedSubject);
      if (response.statusCode == 200) {
        setState(() {
          final List<dynamic> allPapers = jsonDecode(response.body);
          if (_isGuest && allPapers.length > 2) {
            _displayPapers = allPapers.sublist(0, 2);
          } else {
            _displayPapers = allPapers;
          }
        });
      } else {
        CustomToast.showError(context, "Failed to fetch papers");
      }
    } catch (e) {
      CustomToast.showError(context, "Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                    items: _getFilteredSubjects().map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
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
            else if (_displayPapers.isEmpty && !_isLoading)
               Center(
                 child: Padding(
                   padding: const EdgeInsets.only(top: 40),
                   child: Column(
                     children: [
                       Icon(Icons.description_outlined, size: 64, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
                       const SizedBox(height: 16),
                        Text(l10n.noPapersFoundForSubject(_selectedSubject!), style: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant)),
                     ],
                   ),
                 ),
               )
            else if (_isLoading)
               const Center(child: CircularProgressIndicator())
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
                  paper['title'] ?? 'School Paper',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: colorScheme.onSurface),
                ),
                Text(
                  paper['subject'] ?? '',
                  style: GoogleFonts.poppins(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          
          // View Button
          IconButton(
            icon: Icon(Icons.visibility_outlined, color: colorScheme.primary),
            onPressed: () async {
               if (_isGuest) {
                  GuestUtils.showGuestRestrictionDialog(context, message: "Register to view school papers!");
                  return;
               }

               if (!_isPaid) {
                 _showUpgradeDialog();
                 return;
               }

               final productId = paper['id']?.toString() ?? paper['name'];
               final prefs = await SharedPreferences.getInstance();
               final alreadyUsed = prefs.getBool('preview_used_$productId') ?? false;

               if (alreadyUsed) {
                 if (!mounted) return;
                 CustomToast.showError(context, "Free preview already used for this paper. Please purchase to view.");
                 return;
               }

               if (!mounted) return;
               Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfPreviewScreen(product: paper),
                  ),
                );
            },
            tooltip: l10n.view,
          ),
        ],
      ),
    );
  }
}
