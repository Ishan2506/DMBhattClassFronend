import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class StudentProductHistoryScreen extends StatelessWidget {
  const StudentProductHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Mock Data for Materials (PDFs)
    final List<Map<String, dynamic>> materials = [
      {
        "title": "Science Chapter 1 - Notes",
        "date": "Jan 10, 2025",
        "type": "PDF",
        "price": "₹49",
        "transactionId": "TXN123456789"
      },
      {
        "title": "Maths Formulas",
        "date": "Dec 15, 2024",
        "type": "PDF",
        "price": "₹99",
        "transactionId": "TXN987654321"
      },
    ];

    // Mock Data for Products (Physical/Other)
    final List<Map<String, dynamic>> products = [
      {
        "title": "Science Kit - Standard 10",
        "date": "Jan 05, 2025",
        "type": "Physical",
        "price": "₹499",
        "transactionId": "TXN456123789"
      },
      {
        "title": "DM Bhatt T-Shirt",
        "date": "Nov 20, 2024",
        "type": "Merch",
        "price": "₹299",
        "transactionId": "TXN789123456"
      },
    ];

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
        body: TabBarView(
          children: [
            _buildHistoryList(context, materials, isMaterial: true),
            _buildHistoryList(context, products, isMaterial: false),
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
                    _openSecurePdf(context, item['title']);
                  },
                   style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
                  ),
                  child: Text("Read", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                )
              : null, // No action for physical products yet
          ),
        );
      },
    );
  }

  void _openSecurePdf(BuildContext context, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SecurePdfViewer(title: title),
      ),
    );
  }
}

class SecurePdfViewer extends StatelessWidget {
  final String title;
  const SecurePdfViewer({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: title),
      body: PdfPreview(
        build: (format) => _generateDummyPdf(format, title),
        useActions: false, 
        allowPrinting: false,
        allowSharing: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
      ),
    );
  }

  Future<Uint8List> _generateDummyPdf(PdfPageFormat format, String title) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(title, style: pw.TextStyle(fontSize: 40)),
                pw.SizedBox(height: 20),
                pw.Text("This is a secured PDF content.", style: pw.TextStyle(fontSize: 20)),
                pw.Text("Sharing is disabled.", style: pw.TextStyle(fontSize: 14, color: PdfColors.grey)),
              ]
            )
          );
        },
      ),
    );

    return pdf.save();
  }
}
