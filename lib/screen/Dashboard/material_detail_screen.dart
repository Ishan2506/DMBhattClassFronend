import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_filled_button.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/pdf_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Hero Image
            Container(
               width: double.infinity,
               height: screenHeight * 0.4,
               padding: const EdgeInsets.all(32),
               decoration: BoxDecoration(
                 color: isDark ? Colors.grey.shade900 : Colors.white,
                 borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                 boxShadow: [
                   BoxShadow(
                     color: Colors.black.withOpacity(0.05),
                     blurRadius: 10,
                     offset: const Offset(0, 5),
                   )
                 ],
               ),
               child: Hero(
                 tag: product['id'],
                 child: Image.asset(
                   product['image'],
                   fit: BoxFit.contain,
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
    return SizedBox(
      width: double.infinity,
      height: 56,
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
                  Icon(icon, size: 22),
                  const SizedBox(width: 8),
                  Text(label, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
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
                  Icon(icon, size: 22),
                  const SizedBox(width: 8),
                  Text(label, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
    );
  }
}
