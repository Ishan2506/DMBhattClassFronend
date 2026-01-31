import 'dart:async'; // Added Timer import
import 'dart:convert';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/material_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final ImagePicker _picker = ImagePicker();

  // Categories
  final List<String> _categories = ["All", "Material", "Diagram", "Phantom material"];
  String _selectedCategory = "All";

  // Auto Slider
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.75);
    _startAutoSlide();
    _fetchProducts();
  }

  void _startAutoSlide() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_products.isNotEmpty && _pageController.hasClients) {
        _currentPage++;
        if (_currentPage >= _products.length) {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // Future<void> _pickImage() async {
  //   try {
  //     final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
  //     if (photo != null) {
  //       if (!mounted) return;
  //       CustomLoader.show(context);

  //       final inputImage = InputImage.fromFilePath(photo.path);
  //       final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  //       try {
  //         final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
  //         final String extractedText = recognizedText.text.toLowerCase();

  //         // Search logic: Check if any product name is contained in the extracted text
  //         // or if the extracted text contains keywords from the product name.
  //         Map<String, dynamic>? bestMatch;
  //         int maxMatches = 0;

  //         for (final product in _products) {
  //            final productName = product['name'].toString().toLowerCase();
  //            final productKeywords = productName.split(' ').where((w) => w.length > 3).toList();
             
  //            int matches = 0;
  //            for(final keyword in productKeywords) {
  //               if (extractedText.contains(keyword)) {
  //                  matches++;
  //               }
  //            }
             
  //            if (matches > maxMatches) {
  //               maxMatches = matches;
  //               bestMatch = product;
  //            }
  //         }
          
  //         if (!mounted) return;
  //         CustomLoader.hide(context);

  //         if (bestMatch != null) {
  //            setState(() {
  //             _searchQuery = bestMatch!['name'];
  //             _searchController.text = bestMatch!['name'];
  //           });
  //           CustomToast.showSuccess(context, "Found: ${bestMatch!['name']}");
  //         } else {
  //            CustomToast.showError(context, "No product found");
  //         }

  //       } catch (e) {
  //          debugPrint("ML Kit Error: $e");
  //          if (mounted) CustomLoader.hide(context);
  //          if (mounted) CustomToast.showError(context, "Failed to recognize text");
  //       } finally {
  //          textRecognizer.close();
  //       }
  //     }
  //   } catch (e) {
  //     debugPrint("Error picking image: $e");
  //     if (mounted) CustomToast.showError(context, "Error capturing image: $e");
  //   }
  // }

  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];



  Future<void> _fetchProducts() async {
    try {
      final response = await ApiService.getExploreProducts();
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _products = data.map((item) => {
            "id": item['_id'] ?? "",
            "name": item['name'] ?? "",
            "description": item['description'] ?? "",
            "category": item['category'] ?? "Material",
            "price": item['price'] ?? 0,
            "originalPrice": item['originalPrice'] ?? 0,
            "discount": item['discount'] ?? 0,
            "rating": 4.5, // Default or fetch if available
            "reviews": 0,  // Default
            "image": item['image'] ?? "", // Cloudinary URL
          }).toList().cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        CustomToast.showError(context, "Failed to load products");
      }
    } catch (e) {
       setState(() => _isLoading = false);
       debugPrint("Error fetching products: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter Products
    List<Map<String, dynamic>> displayedProducts = _products.where((p) {
      final searchLower = _searchQuery.toLowerCase();
      final isSearchMatch = _searchQuery.isEmpty || 
          p['name'].toString().toLowerCase().contains(searchLower) || 
          p['description'].toString().toLowerCase().contains(searchLower);
      
      final isCategoryMatch = _selectedCategory == "All" || p['category'] == _selectedCategory;
      
      return isSearchMatch && isCategoryMatch;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF0F4F8), // Light Blue-Grey Background
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header & Search
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              // Removed heavy decoration to match minimal "Fency" style
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _searchQuery = value),
                          style: GoogleFonts.poppins(color: isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            hintText: "Search...",
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.grey.shade400,
                              fontSize: 16,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.blue.shade700,
                                width: 1,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Camera Button (Floating Style)
                      GestureDetector(
                        child: Container(
                          padding: const EdgeInsets.all(12), // Slightly smaller padding for balance
                          decoration: BoxDecoration(
                            color: Colors.blue.shade700,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade700.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

             // Category List (Re-introduced)
            SizedBox(
              height: 40,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                         _selectedCategory = category;
                         _currentPage = 0; // Reset page on category change
                         if (_pageController.hasClients) {
                           _pageController.jumpToPage(0);
                         }
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? isDark ? Colors.white : Colors.black87 : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : Colors.grey.shade400,
                        ),
                      ),
                      child: Text(
                        category,
                        style: GoogleFonts.poppins(
                          color: isSelected ? isDark ? Colors.black : Colors.white : isDark ? Colors.white70 : Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Product List
            Expanded(
              child: displayedProducts.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        "No items found",
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600, 
                          fontSize: 16
                        ),
                      ),
                    ],
                  ),
                )
              : Listener(
                 onPointerDown: (_) {
                   // Pause on touch
                   _timer?.cancel(); 
                 },
                 onPointerUp: (_) {
                    // Resume on release
                    _startAutoSlide();
                 },
                 onPointerCancel: (_) {
                    // Resume on cancel
                    _startAutoSlide();
                 },
                 child: PageView.builder(
                    controller: _pageController,
                    itemCount: displayedProducts.length,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) {
                       setState(() {
                         _currentPage = index;
                       });
                    },
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
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product Image (Top Half)
                                Expanded(
                                  flex: 4, 
                                  child: Stack(
                                    children: [
                                       Container(
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.grey.shade800 : const Color(0xFFF5F5F7),
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                                        ),
                                       ),
                                      Center(
                                        child: Hero(
                                          tag: product['id'],
                                          child: Image.asset(
                                            product['image'],
                                            fit: BoxFit.contain,
                                            width: screenWidth * 0.5,
                                          ),
                                        ),
                                      ),
                                      // Heart Icon
                                      Positioned(
                                        top: 20,
                                        right: 20,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.favorite_border,
                                            size: 20,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Details (Bottom Half)
                                Expanded(
                                  flex: 3, 
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0), // Reduced Padding
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Text(
                                          product['name'],
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 18, // Reduced from 20
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : Colors.black87,
                                            height: 1.2,
                                          ),
                                        ),
                                        Text(
                                          "New Sale", 
                                          style: GoogleFonts.poppins(
                                            fontSize: 13, // Reduced from 14
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          "₹${product['price']}",
                                          style: GoogleFonts.poppins(
                                            fontSize: 22, // Reduced from 24
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
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
            ),
          ],
        ),
      ),
    );
  }
} // Rebuild
