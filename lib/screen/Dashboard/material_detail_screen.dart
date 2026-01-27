import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_filled_button.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
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
      // backgroundColor: Colors.white, // Removed to allow theme background
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: screenWidth * 0.05),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Product Details",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                width: double.infinity,
                height: screenHeight * 0.4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Hero(
                  tag: product['id'],
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Image.asset(
                      product['image'],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.image_not_supported_rounded, size: screenWidth * 0.2, color: Colors.grey.shade300);
                      },
                    ),
                  ),
                ),
              ),
              
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge/Category
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        product['category']?.toUpperCase() ?? "MATERIAL",
                        style: GoogleFonts.poppins(
                          color: isDark ? Colors.blue.shade200 : Colors.blue.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.025,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Title
                    Text(
                      product['name'],
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.055, 
                        fontWeight: FontWeight.bold, 
                        color: theme.textTheme.bodyLarge?.color,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Rating
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB300).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.star_rounded, color: const Color(0xFFFFB300), size: screenWidth * 0.045),
                              const SizedBox(width: 4),
                              Text(
                                "${product['rating']}", 
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: screenWidth * 0.035,
                                  color: theme.textTheme.bodyMedium?.color
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "${product['reviews']} customer reviews", 
                          style: GoogleFonts.poppins(
                            color: Colors.blue.shade700, 
                            fontSize: screenWidth * 0.032, 
                            fontWeight: FontWeight.w500
                          ),
                        ),
                      ],
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(),
                    ),

                    // Price Section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "₹${product['price']}",
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.08, 
                            fontWeight: FontWeight.bold, 
                            color: isDark ? Colors.blue.shade200 : Colors.blue.shade900
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "₹${product['originalPrice']}",
                              style: GoogleFonts.poppins(
                                fontSize: screenWidth * 0.035,
                                color: Colors.grey.shade400,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            Text(
                              "${product['discount']}% OFF",
                              style: GoogleFonts.poppins(
                                fontSize: screenWidth * 0.03, 
                                color: Colors.green.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Inclusive of all taxes", 
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    
                    const SizedBox(height: 32),

                    // Detail Info
                    _buildInfoRow(context, Icons.local_shipping_outlined, "Free delivery available"),
                    const SizedBox(height: 12),
                    _buildInfoRow(context, Icons.verified_user_outlined, "Genuine quality product"),
                    const SizedBox(height: 12),
                    _buildInfoRow(context, Icons.inventory_2_outlined, "In Stock"),

                    const SizedBox(height: 40),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: screenHeight * 0.07,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? Colors.transparent : Colors.white,
                                foregroundColor: isDark ? Colors.blue.shade200 : Colors.blue.shade900,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: isDark ? Colors.blue.shade200 : Colors.blue.shade900, 
                                    width: 2
                                  ),
                                ),
                              ),
                              child: Text(
                                "Add to Cart", 
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: screenHeight * 0.07,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade900,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: Colors.blue.shade900.withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                "Buy Now", 
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                    
                    // Description
                    Text(
                      "About this item",
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.045, 
                        fontWeight: FontWeight.bold, 
                        color: theme.textTheme.bodyLarge?.color
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      product['description'] ?? "No description available for this item.",
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.038, 
                        height: 1.6, 
                        color: isDark ? Colors.grey.shade300 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(icon, size: screenWidth * 0.05, color: Colors.blue.shade700),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: screenWidth * 0.035,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey.shade300 : Colors.black87,
          ),
        ),
      ],
    );
  }
}
