import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/board_paper_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/school_papers_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/notes_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/material_images_screen.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MaterialScreen extends StatefulWidget {
  const MaterialScreen({super.key});

  @override
  State<MaterialScreen> createState() => _MaterialScreenState();
}

class _MaterialScreenState extends State<MaterialScreen> {
  String? _std;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserStd();
  }

  Future<void> _loadUserStd() async {
    final prefs = await SharedPreferences.getInstance();
    final rawStd = prefs.getString('std') ?? '';
    // Extract numeric part (e.g., "10th" -> "10")
    final stdMatch = RegExp(r'(\d+)').firstMatch(rawStd);
    if (mounted) {
      setState(() {
        _std = stdMatch?.group(1);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    bool showBoardPapers = _std == "10" || _std == "12";

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: l10n.material,
        centerTitle: true,
      ),
      body: _isLoading
        ? const CustomLoader()
        : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildMaterialItem(
              context,
              title: l10n.schoolPapers,
              icon: Icons.note_alt_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SchoolPapersScreen()),
                );
              },
            ),
            _buildMaterialItem(
              context,
              title: l10n.notes,
              icon: Icons.description_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotesScreen()),
                );
              },
            ),
            if (showBoardPapers)
              _buildMaterialItem(
                context,
                title: l10n.boardPapers,
                icon: Icons.assignment_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BoardPaperScreen()),
                  );
                },
              ),
            _buildMaterialItem(
              context,
              title: l10n.images,
              icon: Icons.image_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MaterialImagesScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialItem(BuildContext context,
      {required String title, required IconData icon, required VoidCallback onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
