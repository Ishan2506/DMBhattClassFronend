import 'dart:async';
import 'dart:convert';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/material_detail_screen.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
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

  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.75);
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

  Future<void> _fetchProducts() async {
    try {
      final response = await ApiService.getExploreProducts();
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _products = data.map((item) => {
              "id": item['_id'] ?? "",
              "name": item['name'] ?? "",
              "description": item['description'] ?? "",
              "category": item['category'] ?? "Material",
              "price": item['price'] ?? 0,
              "originalPrice": item['originalPrice'] ?? 0,
              "discount": item['discount'] ?? 0,
              "rating": 4.5,
              "reviews": 0,
              "image": item['image'] ?? "",
              "subject": item['subject'] ?? "",
            }).toList().cast<Map<String, dynamic>>();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          CustomToast.showError(context, "Failed to load products");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint("Error fetching products: $e");
      }
    }
  }

  /// Helper function to get image URL for display
  /// If the URL is a PDF, converts it to show first page as image
  String _getImageUrl(String url) {
    if (url.isEmpty) return url;
    
    // Check if URL is a PDF (check before any URL encoding)
    if (url.toLowerCase().contains('.pdf')) {
      debugPrint('🔍 PDF detected: $url');
      // Cloudinary PDF to Image transformation
      // Replace /upload/ with /upload/pg_1,f_jpg/ to get first page as JPG
      if (url.contains('/upload/')) {
        // Split the URL at /upload/
        final parts = url.split('/upload/');
        if (parts.length == 2) {
          // Reconstruct with transformation parameters
          final transformedUrl = '${parts[0]}/upload/pg_1,f_jpg/${parts[1]}';
          debugPrint('✅ Transformed URL: $transformedUrl');
          return transformedUrl;
        }
      }
    }
    
    return url;
  }




  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header & Search
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                       borderRadius: BorderRadius.circular(16),
                       boxShadow: [
                         BoxShadow(
                           color: Colors.black.withOpacity(0.05),
                           blurRadius: 10,
                           offset: const Offset(0, 4),
                         )
                       ]
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      style: GoogleFonts.poppins(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: l10n.search,
                        hintStyle: GoogleFonts.poppins(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                          fontSize: 16,
                        ),
                       border: InputBorder.none,
                       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                       prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),)
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Category List
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
                        _currentPage = 0;
                        if (_pageController.hasClients) {
                          _pageController.jumpToPage(0);
                        }
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : theme.colorScheme.outline.withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        category,
                        style: GoogleFonts.poppins(
                          color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
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
              child: _isLoading 
              ? const Center(child: CustomLoader())
              : displayedProducts.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                       Text(
                        AppLocalizations.of(context)!.noProductsFound,
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
                              color: theme.cardColor,
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
                                          color: theme.colorScheme.surfaceContainerHighest,
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                                        ),
                                       ),
                                      Center(
                                        child: Hero(
                                          tag: product['id'],
                                          child: Image.network(
                                            _getImageUrl(product['image']),
                                            fit: BoxFit.contain,
                                            width: screenWidth * 0.5,
                                            errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: 50, color: Colors.grey.shade400,),
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
                                            color: theme.colorScheme.onSurface,
                                            height: 1.2,
                                          ),
                                        ),
                                        Text(
                                          l10n.newSale, 
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
                                            color: theme.colorScheme.onSurface,
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
}

