import 'dart:convert';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/student_payment_confirmation_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:http/http.dart' as http;

class StudentProductHistoryScreen extends StatefulWidget {
  const StudentProductHistoryScreen({super.key});

  @override
  State<StudentProductHistoryScreen> createState() => _StudentProductHistoryScreenState();
}

class _StudentProductHistoryScreenState extends State<StudentProductHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _purchases = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final response = await ApiService.getPurchasedProducts();
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        setState(() {
          _purchases = data.map((item) => {
            "id": item['productId']['_id'],
            "title": item['productId']['name'] ?? "Unknown Product",
            "date": _formatDate(item['createdAt']),
            "type": item['productId']['category'] ?? "Material",
            "price": "₹${item['amount']}",
            "amountRaw": item['amount'],
            "transactionId": item['razorpay_payment_id'] ?? "N/A",
            "image": item['productId']['image'] ?? "",
            "isPdf": item['productId']['image'].toString().toLowerCase().contains('.pdf'),
            "standard": item['productId']['standardId']?['name'] ?? "N/A",
            "medium": item['productId']['mediumId']?['name'] ?? "N/A",
          }).toList().cast<Map<String, dynamic>>();

          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        CustomToast.showError(context, "Failed to load history");
      }
    } catch (e) {
      debugPrint("Error fetching history: $e");
      setState(() => _isLoading = false);
      CustomToast.showError(context, "Error: $e");
    }
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return "${date.day}/${date.month}/${date.year}";
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(
        title: "Product History",
      ),
      body: _isLoading 
        ? const Center(child: CustomLoader())
        : _buildHistoryList(context, _purchases),
    );
  }

  Widget _buildHistoryList(BuildContext context, List<Map<String, dynamic>> items) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (items.isEmpty) {
      return Center(
        child: Text(
          "No history found",
          style: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isPdf = item['isPdf'] == true;
        return Card(
          elevation: 0,
          color: colorScheme.surfaceContainer,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (isPdf) {
                _openMaterialViewer(context, item);
              } else if (item['image'] != null && item['image'].toString().isNotEmpty) {
                _openMaterialViewer(context, item);
              } else {
                // If it's not a material, we don't have a specific view right now, 
                // but we could just show the receipt as a fallback
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentPaymentConfirmationScreen(
                      transactionDetails: item,
                    ),
                  ),
                );
              }
            },
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPdf ? Icons.picture_as_pdf : Icons.image, 
                  color: colorScheme.primary
                ),
              ),
              title: Text(
                item['title'],
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                   Text(
                    "Purchased on: ${item['date']}",
                     style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant
                    ),
                  ),
                  Text(
                    "Price: ${item['price']}",
                     style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500
                    ),
                  ),
                   Text(
                    "Txn ID: ${item['transactionId']}",
                     style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.8)
                    ),
                  ),
                ],
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Download Receipt Button
                  IconButton(
                    icon: Icon(Icons.download, color: colorScheme.primary),
                    tooltip: "Download Receipt",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentPaymentConfirmationScreen(
                            transactionDetails: item,
                          ),
                        ),
                      );
                    },
                  ),
                  // Read Button (Show for all)
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      _openMaterialViewer(context, item);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
                    ),
                    child: Text("Read", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openMaterialViewer(BuildContext context, Map<String, dynamic> item) {
    // Navigate to a screen that shows the full PDF or image
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullMaterialViewerScreen(
          product: {
            'name': item['title'],
            'image': item['image'],
          },
          isPdf: item['isPdf'] ?? false,
        ),
      ),
    );
  }
}

class FullMaterialViewerScreen extends StatelessWidget {
  final Map<String, dynamic> product;
  final bool isPdf;
  
  const FullMaterialViewerScreen({
    super.key, 
    required this.product,
    required this.isPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Better for viewing images/PDFs
      appBar: CustomAppBar(
        title: product['name'] ?? 'View Material',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isPdf
          ? PdfPreview(
              build: (format) async {
                final response = await http.get(Uri.parse(product['image']));
                return response.bodyBytes;
              },
              useActions: false, 
              allowPrinting: false,
              allowSharing: false,
              canChangeOrientation: false,
              canChangePageFormat: false,
            )
          : Center(
              child: InteractiveViewer(
                child: Image.network(
                  product['image'],
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const CircularProgressIndicator(color: Colors.white);
                  },
                  errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                ),
              ),
            ),
    );
  }
}
