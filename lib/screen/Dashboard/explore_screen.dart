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
        // Show scanning dialog
        if(!mounted) return;
        CustomLoader.show(context);

        // Simulate API delay
        await Future.delayed(const Duration(seconds: 2));
        
        if(!mounted) return;
        CustomLoader.hide(context);

        // Simulate finding the first product as a match
        // In a real app, you would upload the image to a server for analysis
        final matchedProduct = _products.first; 
        
        setState(() {
          _searchQuery = matchedProduct['name'];
          _searchController.text = matchedProduct['name'];
        });

        CustomToast.showSuccess(context, "Found matching product: ${matchedProduct['name']}");
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      // Ensure loader is hidden if error occurs while loading
      // (Though try-catch block covers the picky part, if loader was shown need to handle that. 
      // Ideally wrap the loader logic in try-finally or careful flow. 
      // here loader is shown after pickImage returns).
       CustomToast.showError(context, "Error capturing image: $e");
    }
  }

  // Mock Data
  final List<Map<String, dynamic>> _products = [
    {
      "id": "1",
      "name": "Mahamantra Frame | Hare Rama Hare Krishna",
      "image": "assets/images/mahamantra_frame.png", // Updated extension
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
      "image": "assets/images/diagram_set.png", // Updated extension
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
      "image": "assets/images/phantom_chem.png", // Updated extension
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
      "image": "assets/images/wall_hanging.png", // Updated extension
      "rating": 5.0,
      "reviews": 3,
      "price": 287,
      "originalPrice": 699,
      "discount": 59,
      "description": "Beautiful wall hanging with inspirational Hindu quotes. Size 6x20 inches.",
      "category": "Material"
    }
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Filter products
    List<Map<String, dynamic>> displayedProducts = _products
        .where((p) {
          final matchesFilter = _selectedFilter == "All" || _selectedFilter == "Material" && p['category'] == "Material" || p['category'] == _selectedFilter; // Adjusted for initial state
          // Simplified Category Logic: Allow "Material" to act as default or explicit filter
           bool categoryMatch = false;
           if (_filters.contains(_selectedFilter)) {
             categoryMatch = p['category'] == _selectedFilter;
           } else {
             categoryMatch = p['category'] == _selectedFilter;
           }
           
          // Actual Logic used in previous code was: p['category'] == _selectedFilter || _selectedFilter == "All"
          // Let's stick to that but create a more robust search
          final isCategoryMatch = p['category'] == _selectedFilter || _selectedFilter == "All"; // Assuming "All" might be handled outside or if we add "All" tab

          final searchLower = _searchQuery.toLowerCase();
          final isSearchMatch = _searchQuery.isEmpty || 
              p['name'].toString().toLowerCase().contains(searchLower) || 
              p['description'].toString().toLowerCase().contains(searchLower);

          return isCategoryMatch && isSearchMatch;
        }) 
        .toList();
    
    if(displayedProducts.isEmpty && _products.isNotEmpty) {
       // Fallback logic
    }

    return Scaffold(
      backgroundColor: colorScheme.surface, // Dynamic Background
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: "Search or ask a question...",
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                suffixIcon: IconButton(
                  icon: Icon(Icons.camera_alt_outlined, color: colorScheme.onSurfaceVariant),
                  onPressed: _pickImage,
                  tooltip: "Search by Image",
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3), // Dynamic Fill
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.2)),
                ),
              ),
            ),
          ),

          // Filter Chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.2))),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = filter == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    backgroundColor: colorScheme.surface,
                    selectedColor: colorScheme.primaryContainer,
                    checkmarkColor: colorScheme.onPrimaryContainer,
                    labelStyle: TextStyle(
                      color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected ? Colors.transparent : colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Product List
          Expanded(
            child: displayedProducts.isEmpty 
            ? Center(child: Text("No items found for $_selectedFilter", style: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant)))
            : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: displayedProducts.length,
              itemBuilder: (context, index) {
                final product = displayedProducts[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MaterialDetailScreen(product: product),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerLow, // Dynamic Card
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                            child: Hero(
                              tag: product['id'],
                              child: Image.asset(
                                product['image'],
                                fit: BoxFit.cover,
                                errorBuilder: (c,e,s) => Center(child: Icon(Icons.image, color: colorScheme.onSurfaceVariant)),
                              ),
                            ),
                          ),
                        ),
                        
                        // Details
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['name'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text("${product['rating']}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.onSurface)),
                                    const Icon(Icons.star, color: Colors.orange, size: 14),
                                    Text(" (${product['reviews']})", style: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      "₹${product['price']}",
                                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "M.R.P.: ₹${product['originalPrice']}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                        decoration: TextDecoration.lineThrough,
                                        decorationColor: colorScheme.onSurfaceVariant
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  "Save ${product['discount']}%",
                                  style: GoogleFonts.poppins(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "FREE delivery Wed, 28 Jan",
                                  style: GoogleFonts.poppins(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
