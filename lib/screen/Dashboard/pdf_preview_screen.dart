import 'dart:ui';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:math' as math;

class PdfPreviewScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const PdfPreviewScreen({super.key, required this.product});

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _freePages = 2; // First 2 pages are free
  int _actualTotalPages = 1; // Actual total pages in PDF (dynamic)
  bool _isLoading = true;
  Uint8List? _pdfBytes;

  @override
  void initState() {
    super.initState();
    _loadPdfInfo();
  }

  Future<void> _loadPdfInfo() async {
    try {
      final response = await http.get(Uri.parse(widget.product['image']));
      if (response.statusCode == 200) {
        _pdfBytes = response.bodyBytes;
        
        // Robust page counting using structural PDF markers
        try {
          final content = String.fromCharCodes(_pdfBytes!);
          
          // Strategy 1: Look for /Count in the page tree
          final countMatch = RegExp(r'/Count\s+(\d+)').firstMatch(content);
          if (countMatch != null) {
            _actualTotalPages = int.parse(countMatch.group(1)!);
          } else {
            // Strategy 2: Count all instances of /Type /Page
            // We use a boundary check to avoid catching similar strings
            _actualTotalPages = RegExp(r'/Type\s*/Page\b').allMatches(content).length;
          }
        } catch (parseError) {
          debugPrint("Error parsing PDF content for page count: $parseError");
          _actualTotalPages = 1; // Fallback
        }

        if (_actualTotalPages <= 0) _actualTotalPages = 1;

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error loading PDF info: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Generate Cloudinary URL for specific PDF page
  String _getPdfPageUrl(String pdfUrl, int pageNumber) {
    if (pdfUrl.contains('/upload/')) {
      // Insert transformation: pg_<pageNumber>,f_jpg
      return pdfUrl.replaceFirst(
        '/upload/',
        '/upload/pg_$pageNumber,f_jpg/',
      );
    }
    return pdfUrl;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: CustomAppBar(
        title: "PDF Preview",
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Page indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.product['name'] ?? 'PDF Preview',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Page ${_currentPage + 1} / $_actualTotalPages',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Free preview notice
          if (_currentPage < _freePages)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
            ),

          // Page viewer
          Expanded(
            child: _isLoading
                ? const CustomLoader()
                : PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: math.min(_actualTotalPages, _freePages + 1),
                    itemBuilder: (context, index) {
                      final pageNumber = index + 1;
                      final isLocked = pageNumber > _freePages;
                      final bool isCloudinary = widget.product['image'].contains('/upload/');

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade900 : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // PDF Page Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: isCloudinary
                                  ? Image.network(
                                      _getPdfPageUrl(widget.product['image'], pageNumber),
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: const CustomLoader(),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) =>
                                          _buildRasterizedFallback(pageNumber),
                                    )
                                  : _buildRasterizedFallback(pageNumber),
                            ),

                      // Locked overlay for pages beyond free limit
                      if (isLocked)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IgnorePointer(
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.lock_outline,
                                            size: 64,
                                            color: Colors.white.withOpacity(0.9),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Page Locked',
                                            style: GoogleFonts.poppins(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Purchase to unlock all pages',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.white.withOpacity(0.8),
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        // Scroll to download button on detail page
                                      },
                                      icon: const Icon(Icons.shopping_cart),
                                      label: Text(
                                        'Buy for ₹${widget.product['price']}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.colorScheme.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 32,
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Navigation controls
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous button
                ElevatedButton.icon(
                  onPressed: _currentPage > 0
                      ? () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.arrow_back),
                  label: Text(
                    'Previous',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    foregroundColor: isDark ? Colors.white : Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                // Next button
                ElevatedButton.icon(
                  onPressed: _currentPage < math.min(_actualTotalPages, _freePages + 1) - 1
                      ? () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(
                    'Next',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRasterizedFallback(int pageNumber) {
    return FutureBuilder<Uint8List?>(
      future: _getRasterizedPage(widget.product['image'], pageNumber),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CustomLoader();
        }
        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(snapshot.data!, fit: BoxFit.contain);
        }
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                'Failed to load page',
                style: GoogleFonts.poppins(color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Uint8List?> _getRasterizedPage(String url, int pageNumber) async {
    try {
      if (_pdfBytes == null) {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          _pdfBytes = response.bodyBytes;
        }
      }

      if (_pdfBytes != null) {
        // Rasterize the specific page (0-indexed in Printing.raster)
        await for (final page in Printing.raster(_pdfBytes!, pages: [pageNumber - 1])) {
          return await page.toPng();
        }
      }
    } catch (e) {
      debugPrint("Error rasterizing PDF: $e");
    }
    return null;
  }
}
