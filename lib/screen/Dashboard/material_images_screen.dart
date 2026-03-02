import 'dart:convert';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:dm_bhatt_tutions/utils/guest_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MaterialImagesScreen extends StatefulWidget {
  const MaterialImagesScreen({super.key});

  @override
  State<MaterialImagesScreen> createState() => _MaterialImagesScreenState();
}

class _MaterialImagesScreenState extends State<MaterialImagesScreen> {
  String? _selectedSubject;
  String? _selectedUnit;

  final List<String> _subjects = ["Mathematics", "Science", "English", "Social Science", "Gujarati", "Physics", "Chemistry", "Biology", "Accounts", "Statistics"];
  final List<String> _units = List.generate(20, (index) => (index + 1).toString());

  bool _isLoading = false;
  bool _hasSearched = false;
  List<dynamic> _images = [];
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    _checkGuest();
  }

  Future<void> _checkGuest() async {
    _isGuest = await GuestUtils.isGuest();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: l10n.images,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildFilterCard(colorScheme),
                const SizedBox(height: 24),
                if (_hasSearched && _images.isEmpty && !_isLoading)
                  _buildNoResults()
                else if (_hasSearched && _images.isNotEmpty)
                  _buildImagesGrid(colorScheme),
              ],
            ),
          ),
          if (_isLoading) const Center(child: CustomLoader()),
        ],
      ),
    );
  }

  Widget _buildFilterCard(ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          _buildDropdown(l10n.selectSubject, _subjects, _selectedSubject, (val) => setState(() => _selectedSubject = val)),
          const SizedBox(height: 12),
          _buildDropdown(l10n.selectUnit, _units, _selectedUnit, (val) => setState(() => _selectedUnit = val)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _fetchImages,
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
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Icon(Icons.image_not_supported_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text("No images found for this selection", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesGrid(ColorScheme colorScheme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _images.length,
      itemBuilder: (context, index) {
        final imageData = _images[index];
        return _buildImageCard(imageData, colorScheme);
      },
    );
  }

  Widget _buildImageCard(dynamic imageData, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () => _viewImage(imageData['url']),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  imageData['url'],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                imageData['title'] ?? "Image ${imageData['unit']}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewImage(String url) {
    if (_isGuest) {
       GuestUtils.showGuestRestrictionDialog(context, message: "Register to view images!");
       return;
    }
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Image.network(url, fit: BoxFit.contain),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchImages() async {
    if (_selectedSubject == null || _selectedUnit == null) {
      CustomToast.showError(context, "Please select Subject and Unit");
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _images = [];
    });

    try {
      // Assuming a new API endpoint or reusing existing one with category 'Image'
      final response = await ApiService.getMaterialImages(
        subject: _selectedSubject!,
        unit: _selectedUnit!,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _images = data; // Backend returns a list
        });
      } else {
        CustomToast.showError(context, "Failed to fetch images");
      }
    } catch (e) {
      debugPrint("Error fetching images: $e");
      // For now, if API fails or doesn't exist, show empty or mock if needed for demo
      // setState(() => _images = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
