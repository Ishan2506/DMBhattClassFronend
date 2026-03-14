import 'dart:convert';
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

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String? _selectedSubject;
  bool _isGuest = false;
  bool _isPaid = false;
  String? _std;
  String? _stream;

  @override
  void initState() {
    super.initState();
    _loadProfileAndCheckGuest();
  }

  Future<void> _loadProfileAndCheckGuest() async {
    _isGuest = await GuestUtils.isGuest();
    if (!_isGuest) {
      try {
        final profileResponse = await ApiService.getProfile(forceRefresh: true);
        if (profileResponse.statusCode == 200) {
          final profileData = jsonDecode(profileResponse.body);
          _isPaid = profileData['user']?['isPaid'] ?? false;
        }
      } catch (e) {
        debugPrint("Error fetching profile: $e");
      }
    }
    final prefs = await SharedPreferences.getInstance();
    _std = prefs.getString('std');
    _stream = prefs.getString('stream');
    if (mounted) setState(() {});
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Premium Material", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          "These notes are part of our premium content. Please upgrade your plan to access all notes and materials.",
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
    if (_isGuest) {
      return ["Mathematics", "Science", "English", "Social Science", "Gujarati", "Physics", "Chemistry", "Biology", "Accounts", "Statistics"];
    }

    int? stdNum;
    if (_std != null) {
      final match = RegExp(r'(\d+)').firstMatch(_std!);
      if (match != null) {
        stdNum = int.tryParse(match.group(1)!);
      }
    }

    if (stdNum != null && stdNum <= 10) {
      return ["Mathematics", "Science", "English", "Social Science", "Gujarati", "Hindi", "Sanskrit", "Computer"];
    }

    if (stdNum != null && (stdNum == 11 || stdNum == 12)) {
      if (_stream == "Science") {
        return ["Physics", "Chemistry", "Biology", "Mathematics", "English", "Gujarati", "Hindi", "Computer", "Sanskrit"];
      } else if (_stream == "Commerce") {
        return ["Accounts", "Statistics", "Economics", "BA", "SPCC", "English", "Gujarati", "Hindi", "Computer"];
      } else if (_stream == "Arts") {
        return ["Sociology", "Psychology", "History", "Geography", "Philosophy", "English", "Gujarati", "Hindi", "Sanskrit"];
      }
    }

    return ["Mathematics", "Science", "English", "Social Science", "Gujarati", "Physics", "Chemistry", "Biology", "Accounts", "Statistics"];
  }
  
  bool _isLoading = false;
  List<dynamic> _displayNotes = [];

  Future<void> _filterNotes() async {
    if (_selectedSubject == null) {
      setState(() {
        _displayNotes = [];
      });
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getNotes(subject: _selectedSubject);
      if (response.statusCode == 200) {
        setState(() {
          final List<dynamic> allNotes = jsonDecode(response.body);
          if (_isGuest && allNotes.length > 2) {
            _displayNotes = allNotes.sublist(0, 2);
          } else {
            _displayNotes = allNotes;
          }
        });
      } else {
        CustomToast.showError(context, "Failed to fetch notes");
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

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: l10n.notes,
        centerTitle: true, 
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      _filterNotes();
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

            if (_selectedSubject == null)
               Center(
                 child: Padding(
                   padding: const EdgeInsets.only(top: 40),
                   child: Column(
                     children: [
                       Icon(Icons.subject, size: 64, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
                       const SizedBox(height: 16),
                       Text(l10n.selectSubject, style: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant)),
                     ],
                   ),
                 ),
               )
            else if (_displayNotes.isEmpty && !_isLoading)
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
                    "${l10n.availablePapers} (${_displayNotes.length})",
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 12),
                  ..._displayNotes.map((note) => _buildNoteCard(note, theme)).toList(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note, ThemeData theme) {
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
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.blue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note['title'] ?? 'Note',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: colorScheme.onSurface),
                ),
                Text(
                  note['subject'] ?? '',
                  style: GoogleFonts.poppins(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          
          IconButton(
            icon: Icon(Icons.visibility_outlined, color: colorScheme.primary),
            onPressed: () async {
               if (_isGuest) {
                  GuestUtils.showGuestRestrictionDialog(context, message: "Register to view notes!");
                  return;
               }

               if (!_isPaid) {
                 _showUpgradeDialog();
                 return;
               }

               Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfPreviewScreen(product: note),
                  ),
                );
            },
          ),
        ],
      ),
    );
  }
}
