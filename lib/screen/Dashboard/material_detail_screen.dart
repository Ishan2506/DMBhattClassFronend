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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: "Product Details",
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.35,
                color: Colors.grey.shade100,
                child: Hero(
                  tag: product['id'],
                  child: Image.asset(
                    product['image'],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image_not_supported, size: 80, color: Colors.grey);
                    },
                  ),
                ),
              ),
              
              Padding(
                padding: P.all16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Visit Store Link
                    Text(
                      "Visit the DM Bhatt Store",
                      style: GoogleFonts.poppins(color: Colors.teal, fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    
                    // Title
                    Text(
                      product['name'],
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.normal, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),

                    // Rating
                    Row(
                      children: [
                        Text("${product['rating']}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        ...List.generate(5, (index) {
                          return Icon(
                            index < (product['rating'] as double).round() ? Icons.star : Icons.star_border,
                            color: Colors.orange,
                            size: 16,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text("${product['reviews']} ratings", style: GoogleFonts.poppins(color: Colors.blue, fontSize: 12)),
                      ],
                    ),
                    const Divider(height: 24),

                    // Price
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "₹${product['price']}",
                            style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w500, color: Colors.black),
                          ),
                          TextSpan(
                            text: " M.R.P.: ",
                            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                          ),
                          TextSpan(
                            text: "₹${product['originalPrice']}",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          TextSpan(
                            text: " (${product['discount']}% off)",
                            style: GoogleFonts.poppins(fontSize: 14, color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text("Inclusive of all taxes", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),

                    // Delivery Info
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 18, color: Colors.black54),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "Deliver to Devarsh - Ahmedabad 382443",
                            style: GoogleFonts.poppins(color: Colors.teal, fontSize: 13, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "In stock",
                      style: GoogleFonts.poppins(color: Colors.green, fontSize: 16, fontWeight: FontWeight.w500),
                    ),

                    const SizedBox(height: 24),

                    // Buttons
                    SizedBox(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.06,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD814), // Amazon-like yellow
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: Text("Add to Cart", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.06,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFA41C), // Amazon-like orange
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: Text("Buy Now", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    
                    // Description
                    Text(
                      "About this item",
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product['description'] ?? "No description available for this item.",
                      style: GoogleFonts.poppins(fontSize: 14, height: 1.5, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
