import 'dart:convert';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
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
  List<Map<String, dynamic>> _materials = [];
  List<Map<String, dynamic>> _products = [];

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
          // Assuming the API returns a list of purchases
          // Filter into materials (PDFs) and products (Image/Other)
          final purchases = data.map((item) => {
            "id": item['productId']['_id'],
            "title": item['productId']['name'] ?? "Unknown Product",
            "date": _formatDate(item['createdAt']),
            "type": item['productId']['category'] ?? "Material",
            "price": "₹${item['amount']}",
            "transactionId": item['razorpay_payment_id'] ?? "N/A",
            "image": item['productId']['image'] ?? "",
            "isPdf": item['productId']['image'].toString().toLowerCase().contains('.pdf'),
          }).toList().cast<Map<String, dynamic>>();

          _materials = purchases.where((p) => p['isPdf']).toList();
          _products = purchases.where((p) => !p['isPdf']).toList();
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: CustomAppBar(
          title: "Product History",
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(
                child: Text(
                  "Materials",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
              Tab(
                child: Text(
                  "Products",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        body: _isLoading 
          ? const Center(child: CustomLoader())
          : TabBarView(
              children: [
                _buildHistoryList(context, _materials, isMaterial: true),
                _buildHistoryList(context, _products, isMaterial: false),
              ],
            ),
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context, List<Map<String, dynamic>> items, {required bool isMaterial}) {
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
        return Card(
          elevation: 0,
          color: colorScheme.surfaceContainer,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isMaterial ? Icons.picture_as_pdf : Icons.inventory_2, 
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
            trailing: isMaterial 
              ? ElevatedButton(
                  onPressed: () {
                    _openSecurePdf(context, item);
                  },
                   style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
                  ),
                  child: Text("Read", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                )
              : null,
          ),
        );
      },
    );
  }

  void _openSecurePdf(BuildContext context, Map<String, dynamic> item) {
    // Navigate to a screen that shows the full PDF
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullPdfViewerScreen(product: {
          'name': item['title'],
          'image': item['image'],
        }),
      ),
    );
  }
}

class FullPdfViewerScreen extends StatelessWidget {
  final Map<String, dynamic> product;
  const FullPdfViewerScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: product['name'] ?? 'View PDF',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PdfPreview(
        build: (format) async {
          final response = await http.get(Uri.parse(product['image']));
          return response.bodyBytes;
        },
        useActions: false, 
        allowPrinting: false,
        allowSharing: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
      ),
    );
  }
}
