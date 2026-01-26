import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/material_detail_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // Filters
  final List<String> _filters = ["Material", "Diagram", "Phantom material", "Books", "Stationery"];
  String _selectedFilter = "Material";

  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        if(!mounted) return;
        CustomLoader.show(context);

        await Future.delayed(const Duration(seconds: 2));
        
        if(!mounted) return;
        CustomLoader.hide(context);

        final matchedProduct = _products.first; 
        
        setState(() {
          _searchQuery = matchedProduct['name'];
          _searchController.text = matchedProduct['name'];
        });

        CustomToast.showSuccess(context, "Found matching product: ${matchedProduct['name']}");
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      CustomToast.showError(context, "Error capturing image: $e");
    }
  }

  // Mock Data
  final List<Map<String, dynamic>> _products = [
    {
      "id": "1",
      "name": "Mahamantra Frame | Hare Rama Hare Krishna",
      "image": "assets/images/mahamantra_frame.png",
      "rating": 4.5,
      "reviews": 12,
      "price": 630,
      "originalPrice": 1400,
      "discount": 55,
      "description": "High quality wooden frame with gold plated text. Perfect for home decor and pooja room.",
      "category": "Material"
    },
    {
      "id": "2",
      "name": "Physics Class 10 Diagram Set",
      "image": "assets/images/diagram_set.png",
      "rating": 4.2,
      "reviews": 45,
      "price": 250,
      "originalPrice": 500,
      "discount": 50,
      "description": "Complete set of physics diagrams for class 10 students. Laminated for durability.",
      "category": "Diagram"
    },
     {
      "id": "3",
      "name": "Chemistry Phantom Material",
      "image": "assets/images/phantom_chem.png",
      "rating": 4.8,
      "reviews": 8,
      "price": 899,
      "originalPrice": 1999,
      "discount": 55,
      "description": "Special study material for chemistry enthusiasts. Includes 3D models.",
      "category": "Phantom material"
    },
    {
      "id": "4",
      "name": "Wall Hanging Hindu Quote Frame",
      "image": "assets/images/wall_hanging.png",
      "rating": 5.0,
      "reviews": 3,
      "price": 287,
      "originalPrice": 699,
      "discount": 59,
      "description": "Beautiful wall hanging with inspirational Hindu quotes. Size 6x20 inches.",
      "category": "Material"
    }
  ];

<<<<<<< HEAD
=======

>>>>>>> b1af9f75f0e6e8a77946d6f379cb9e8fac116453
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    List<Map<String, dynamic>> displayedProducts = _products.where((p) {
      final isCategoryMatch = p['category'] == _selectedFilter || _selectedFilter == "All";
      final searchLower = _searchQuery.toLowerCase();
      final isSearchMatch = _searchQuery.isEmpty || 
          p['name'].toString().toLowerCase().contains(searchLower) || 
          p['description'].toString().toLowerCase().contains(searchLower);
      return isCategoryMatch && isSearchMatch;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: GoogleFonts.poppins(color: Colors.black87, fontSize: screenWidth * 0.035),
                decoration: InputDecoration(
                  hintText: "Search materials, books, etc...",
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: screenWidth * 0.035),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.blue.shade900, size: screenWidth * 0.05),
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.camera_alt_rounded, color: Colors.blue.shade900, size: screenWidth * 0.05),
                      onPressed: _pickImage,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          // Filter Chips
          Container(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = filter == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    labelStyle: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.032,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: Colors.blue.shade900,
                    elevation: isSelected ? 4 : 0,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide.none,
                    ),
                    showCheckmark: false,
                  ),
                );
              },
            ),
          ),

          // Product List
          Expanded(
            child: displayedProducts.isEmpty 
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    "No items found",
                    style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: displayedProducts.length,
                itemBuilder: (context, index) {
                  final product = displayedProducts[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MaterialDetailScreen(product: product),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Hero(
                                tag: product['id'],
                                child: Container(
                                  width: screenWidth * 0.28,
                                  height: screenWidth * 0.28,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      product['image'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (c,e,s) => const Icon(Icons.image, color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['name'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: screenWidth * 0.035, 
                                        fontWeight: FontWeight.w600, 
                                        color: Colors.black87,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.star_rounded, color: const Color(0xFFFFB300), size: screenWidth * 0.04),
                                        const SizedBox(width: 2),
                                        Text(
                                          "${product['rating']}", 
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold, 
                                            fontSize: screenWidth * 0.03, 
                                            color: Colors.black87
                                          ),
                                        ),
                                        Text(
                                          " (${product['reviews']})", 
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey.shade500, 
                                            fontSize: screenWidth * 0.03
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          "₹${product['price']}",
                                          style: GoogleFonts.poppins(
                                            fontSize: screenWidth * 0.045, 
                                            fontWeight: FontWeight.bold, 
                                            color: Colors.blue.shade900
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "₹${product['originalPrice']}",
                                          style: GoogleFonts.poppins(
                                            fontSize: screenWidth * 0.028,
                                            color: Colors.grey.shade400,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        "Save ${product['discount']}%",
                                        style: GoogleFonts.poppins(
                                          color: Colors.green.shade700, 
                                          fontSize: 10, 
                                          fontWeight: FontWeight.w600
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ),
        ],
      ),
    );
  }
}
