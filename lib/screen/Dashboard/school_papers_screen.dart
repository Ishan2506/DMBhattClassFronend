import 'dart:convert';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

class SchoolPapersScreen extends StatefulWidget {
  const SchoolPapersScreen({super.key});

  @override
  State<SchoolPapersScreen> createState() => _SchoolPapersScreenState();
}

class _SchoolPapersScreenState extends State<SchoolPapersScreen> {
  // Filter States
  String? _selectedMedium;
  String? _selectedStd;
  String? _selectedStream;
  String? _selectedYear;
  String? _selectedSubject;

  final List<String> _mediums = ["Gujarati", "English"];
  final List<String> _stds = ["6", "7", "8", "9", "10", "11", "12"];
  final List<String> _streams = ["Science", "Commerce", "Arts"];
  final List<String> _years = List.generate(10, (index) => (DateTime.now().year - index).toString());

  String? _board;
  bool _isGuest = false;
  bool _isPaid = false;
  bool _isLoading = false;
  bool _isProfileLoading = true;
  bool _hasSearched = false;
  List<dynamic> _displayPapers = [];

  @override
  void initState() {
    super.initState();
    _loadProfileAndCheckGuest();
  }

  Future<void> _loadProfileAndCheckGuest() async {
    setState(() => _isProfileLoading = true);
    _isGuest = await GuestUtils.isGuest();
    final prefs = await SharedPreferences.getInstance();

    // Read cached isPaid state to avoid flashing banner for paid users
    _isPaid = prefs.getBool('isPaid') ?? false;

    final profileFromPrefs = {
      'board': prefs.getString('board'),
      'std': prefs.getString('std'),
      'stream': prefs.getString('stream'),
      'medium': prefs.getString('medium'),
    };

    if (!_isGuest) {
      try {
        final profileResponse = await ApiService.getProfile(forceRefresh: true);
        if (profileResponse.statusCode == 200) {
          final profileData = jsonDecode(profileResponse.body);
          final user = profileData['user'];
          final profile = profileData['profile'];
          
          _isPaid = user?['isPaid'] ?? false;
          await prefs.setBool('isPaid', _isPaid);
          final board = user?['board'] ?? profile?['board'] ?? profileFromPrefs['board'];
          final studentStd = user?['std']?.toString() ?? profile?['std']?.toString() ?? profileFromPrefs['std'];
          final studentStream = user?['stream'] ?? profile?['stream'] ?? profileFromPrefs['stream'];
          final medium = user?['medium'] ?? profile?['medium'] ?? profileFromPrefs['medium'];

          String? validStd;
          if (studentStd != null) {
            final match = RegExp(r'(\d+)').firstMatch(studentStd);
            if (match != null) {
              validStd = match.group(1);
            }
          }

          if (mounted) {
            setState(() {
              _selectedMedium = medium ?? profileFromPrefs['medium'];
              _selectedStd = validStd;
              _selectedStream = (validStd == '11' || validStd == '12') ? studentStream : null;
              _board = board;
            });
          }

          // Sync back to SharedPreferences
          if (studentStd != null) await prefs.setString('std', studentStd);
          if (studentStream != null) await prefs.setString('stream', studentStream);
          if (board != null) await prefs.setString('board', board);
          if (medium != null) await prefs.setString('medium', medium);
        }
      } catch (e) {
        debugPrint("Error fetching profile: $e");
      }
    } else {
      _selectedMedium ??= profileFromPrefs['medium'] ?? "English";
      if (profileFromPrefs['std'] != null) {
        final match = RegExp(r'(\d+)').firstMatch(profileFromPrefs['std']!);
        if (match != null) _selectedStd = match.group(1);
      }
      _selectedStream ??= profileFromPrefs['stream'];
      _board ??= profileFromPrefs['board'];
    }

    if (mounted) setState(() => _isProfileLoading = false);
  }

  List<String> _getFilteredSubjects() {
    return AcademicConstants.getSubjectsForStudent(
      board: _board,
      std: _selectedStd,
      stream: _selectedStream,
    );
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

  Widget _buildUnpaidBanner(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.workspace_premium_rounded, color: colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Free Preview Mode",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      "Showing 2 free sample school papers",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Upgrade your plan to unlock full access to all school papers & study materials!",
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: colorScheme.onPrimaryContainer.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UpgradePlanScreen()),
                );
              },
              icon: const Icon(Icons.star_rounded, size: 18),
              label: Text(
                "Upgrade Plan to Unlock All",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _filterPapers({bool isAuto = false}) async {
    if (_selectedMedium == null || _selectedStd == null) {
      if (!isAuto) CustomToast.showError(context, "Please select Medium and Standard");
      return;
    }
    if (_selectedYear == null) {
      if (!isAuto) CustomToast.showError(context, "Please select Year");
      return;
    }
    if ((_selectedStd == "11" || _selectedStd == "12") && _selectedStream == null) {
      if (!isAuto) CustomToast.showError(context, AppLocalizations.of(context)!.selectStreamError);
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _displayPapers = [];
    });

    try {
      final response = await ApiService.getSchoolPapers(
        subject: _selectedSubject,
        std: _selectedStd,
        medium: _selectedMedium,
        year: _selectedYear,
        board: _board,
        stream: _selectedStream,
      );

      if (response.statusCode == 200) {
        final List<dynamic> allPapers = jsonDecode(response.body);
        setState(() {
          if ((!_isPaid || _isGuest) && allPapers.length > 2) {
            _displayPapers = allPapers.sublist(0, 2);
          } else {
            _displayPapers = allPapers;
          }
        });
        if (_displayPapers.isEmpty && !isAuto) {
          CustomToast.showSuccess(context, AppLocalizations.of(context)!.noPapersFound);
        }
      } else {
        if (!isAuto) CustomToast.showError(context, "Failed to fetch papers: ${ApiService.getErrorMessage(response.body)}");
      }
    } catch (e) {
      if (!isAuto) CustomToast.showError(context, "Error: $e");
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
            if (!_isProfileLoading && (!_isPaid || _isGuest)) _buildUnpaidBanner(context),

            // Filter Section Card
            _buildFilterCard(colorScheme, isDark),
            
            const SizedBox(height: 24),

            // Results Section
            if (_selectedMedium == null || _selectedStd == null || _selectedYear == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(
                    children: [
                      Icon(Icons.manage_search_rounded, size: 64, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text("Select filters and apply to view papers", style: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              )
            else if (_isLoading || _isProfileLoading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: CustomLoader(),
              )
            else if (_hasSearched && _displayPapers.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 64, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text("No papers found for this search", style: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              )
            else if (_hasSearched && _displayPapers.isNotEmpty) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${l10n.availablePapers} (${_displayPapers.length})",
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 12),
                  ..._displayPapers.map((paper) => _buildPaperCard(paper, theme)),
                ],
              ),
            ],
          ],
        ),
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
          Text(l10n.selectSubject, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  l10n.medium, 
                  _mediums, 
                  _selectedMedium, 
                  (val) => setState(() => _selectedMedium = val),
                  enabled: false,
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
                  }),
                  enabled: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_selectedStd == "11" || _selectedStd == "12") ...[
            _buildDropdown(
              l10n.stream, 
              _streams, 
              _selectedStream, 
              (val) => setState(() {
                _selectedStream = val;
                _selectedSubject = null; // Reset subject when stream changes
              }),
              enabled: false,
            ),
            const SizedBox(height: 12),
          ],

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
              onPressed: () => _filterPapers(),
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

  Widget _buildDropdown(String label, List<String> items, String? value, Function(String?)? onChanged, {bool enabled = true}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : null,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 14, color: colorScheme.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: theme.cardColor,
      ),
      style: GoogleFonts.poppins(color: colorScheme.onSurface),
      dropdownColor: theme.cardColor,
    );
  }

  Widget _buildPaperCard(Map<String, dynamic> paper, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;
    final yearText = paper['year'] != null && paper['year'].toString().isNotEmpty ? " • ${paper['year']}" : "";

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
                  paper['title'] ?? paper['name'] ?? 'School Paper',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: colorScheme.onSurface),
                ),
                Text(
                  "${paper['subject'] ?? ''}$yearText",
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

               // Allow viewing sample paper preview
               final productId = paper['id']?.toString() ?? paper['_id']?.toString() ?? paper['name'] ?? paper['title'];
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
                    builder: (context) => PdfPreviewScreen(product: pdfPaper, isFullAccess: true),
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

