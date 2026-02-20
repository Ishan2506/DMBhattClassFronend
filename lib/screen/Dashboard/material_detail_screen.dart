import 'dart:ui' as ui;
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_filled_button.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/pdf_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class MaterialDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;

  const MaterialDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: "Product Details",
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      backgroundColor: theme.colorScheme.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Hero Image
            Container(
               width: double.infinity,
               height: screenHeight * 0.4,
               padding: const EdgeInsets.all(32),
               decoration: BoxDecoration(
                 color: theme.colorScheme.surfaceContainerLowest,
                 borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                 boxShadow: [
                   BoxShadow(
                     color: Colors.black.withOpacity(0.05),
                     blurRadius: 10,
                     offset: const Offset(0, 5),
                   )
                 ],
               ),
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                  child: Hero(
                    tag: product['id'],
                    child: () {
                       final String imageUrl = product['image'].toString();
                       // 1. Check if it's a Cloudinary PDF - Use fast image transformation
                       if (imageUrl.toLowerCase().contains('.pdf') && imageUrl.contains('/upload/')) {
                          final parts = imageUrl.split('/upload/');
                          if (parts.length == 2) {
                            final transformedUrl = '${parts[0]}/upload/pg_1,f_jpg/${parts[1]}';
                            return Image.network(
                              transformedUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                            );
                          }
                       }
                       
                       // 2. Check if it's a non-Cloudinary PDF - Use rasterization (slower)
                       if (imageUrl.toLowerCase().contains('.pdf')) {
                         return _PdfCover(url: imageUrl);
                       }
   
                       // 3. Standard Image
                       if (imageUrl.startsWith('http')) {
                         return Image.network(
                           imageUrl,
                           fit: BoxFit.contain,
                           errorBuilder: (context, error, stackTrace) =>
                               const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                         );
                       }
   
                       // 4. Asset Image
                       return Image.asset(
                         imageUrl,
                         fit: BoxFit.contain,
                       );
                     }(),
                  ),
                ),
            ),

            // 2. Content Body
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    // Badge (Subject > Category fallback)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        product['subject']?.toUpperCase() ?? product['category']?.toUpperCase() ?? "MATERIAL",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Subject Row
                    if (product['subject'] != null && product['subject'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          "Subject: ${product['subject']}",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),

                    // Title
                    Text(
                      product['name'],
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Price Section
                    // Price Section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "₹${product['price']}",
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary, // Use theme color
                          ),
                        ),
                         const SizedBox(width: 12),
                         if ((product['originalPrice'] as num) > (product['price'] as num))
                          Text(
                            "₹${product['originalPrice']}",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey.shade400,
                            ),
                          ),
                         const SizedBox(width: 8),
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                           decoration: BoxDecoration(
                             color: Colors.green.shade50,
                             borderRadius: BorderRadius.circular(4),
                           ),
                           child: Text(
                             "${product['discount']}% OFF",
                             style: GoogleFonts.poppins(
                               fontSize: 12,
                               fontWeight: FontWeight.bold,
                               color: Colors.green.shade700
                             ),
                           ),
                         ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),

                     // Description
                    Text(
                      "About this item",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product['description'] ?? "No description available.",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        height: 1.6,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // --- Action Buttons Section ---
                    Text(
                      "Actions",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Preview PDF (Only for PDFs)
                    if (product['image'] != null && product['image'].toString().toLowerCase().contains('.pdf'))
                      _buildActionButton(
                        context: context,
                        label: "Preview PDF",
                        icon: Icons.visibility_outlined,
                        color: theme.colorScheme.secondary,
                        isPrimary: false,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PdfPreviewScreen(product: product),
                            ),
                          );
                        },
                      ),
                    
                    if (product['image'] != null && product['image'].toString().toLowerCase().contains('.pdf'))
                      const SizedBox(height: 12),
                    
                    // 1. Download PDF (Prominent)
                    _buildActionButton(
                      context: context,
                      label: "Download PDF",
                      icon: Icons.file_download_outlined,
                      color: theme.colorScheme.primary, // Use theme color
                      isPrimary: true,
                      onPressed: () {
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text("Downloading PDF...")),
                         );
                      },
                    ),

                    const SizedBox(height: 40), // Bottom padding
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isPrimary = false,
    bool isOutlined = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      width: double.infinity,
      height: screenHeight * 0.065,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                foregroundColor: color, // Text & Icon color
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: screenWidth * 0.05),
                  const SizedBox(width: 8),
                  Text(label, style: GoogleFonts.poppins(fontSize: screenWidth * 0.045, fontWeight: FontWeight.w600)),
                ],
              ),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: isPrimary ? color : color.withOpacity(0.1),
                foregroundColor: isPrimary ? Colors.white : color,
                elevation: isPrimary ? 4 : 0,
                shadowColor: isPrimary ? color.withOpacity(0.4) : Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: screenWidth * 0.05),
                  const SizedBox(width: 8),
                  Text(label, style: GoogleFonts.poppins(fontSize: screenWidth * 0.045, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
    );
  }
}

class _PdfCover extends StatefulWidget {
  final String url;
  const _PdfCover({required this.url});

  @override
  State<_PdfCover> createState() => _PdfCoverState();
}

class _PdfCoverState extends State<_PdfCover> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadPdfCover();
  }

  Future<void> _loadPdfCover() async {
    try {
      final response = await http.get(Uri.parse(widget.url));
      if (response.statusCode == 200) {
        final pdfBytes = response.bodyBytes;
        // Rasterize the first page (0)
        await for (final page in Printing.raster(pdfBytes, pages: [0])) {
           final bytes = await page.toPng();
           if (mounted) {
             setState(() {
               _imageBytes = bytes;
               _isLoading = false;
             });
           }
           break; // Just need the first page
        }
      } else {
        if (mounted) setState(() { _hasError = true; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _hasError = true; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CustomLoader();
    }
    if (_hasError || _imageBytes == null) {
       return const Center(
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
             SizedBox(height: 8),
             Text("PDF Document", style: TextStyle(color: Colors.grey))
           ],
         )
       );
    }
    return Image.memory(_imageBytes!, fit: BoxFit.contain);
  }
}
