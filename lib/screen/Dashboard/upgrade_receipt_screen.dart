import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class UpgradeReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> historyItem;

  const UpgradeReceiptScreen({super.key, required this.historyItem});

  Future<void> _downloadReceipt(BuildContext context) async {
    final pdf = pw.Document();

    final date = DateTime.parse(historyItem['createdAt']);
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Payment Receipt', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Upgrade from Standard ${historyItem['oldStandard']} to ${historyItem['newStandard']}', style: pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 10),
              pw.Text('Medium: ${historyItem['medium']}'),
              if (historyItem['stream'] != null) pw.Text('Stream: ${historyItem['stream']}'),
              pw.SizedBox(height: 10),
              pw.Text('Date: $formattedDate'),
              pw.SizedBox(height: 10),
              pw.Text('Transaction ID: ${historyItem['razorpayPaymentId']}'),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Amount Paid:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Rs. ${historyItem['amount']}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ]
              ),
              pw.SizedBox(height: 40),
              pw.Text('Thank you for your purchase!'),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Receipt_${historyItem['razorpayPaymentId']}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final date = DateTime.parse(historyItem['createdAt']);
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('Payment Confirmation', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            Text(
              "Payment Successful!",
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                   _buildDetailRow("Standard", "${historyItem['oldStandard']} ➔ ${historyItem['newStandard']}", colorScheme),
                   const Divider(height: 24),
                   _buildDetailRow("Medium", historyItem['medium'], colorScheme),
                   if (historyItem['stream'] != null) ...[
                     const Divider(height: 24),
                     _buildDetailRow("Stream", historyItem['stream'], colorScheme),
                   ],
                   const Divider(height: 24),
                   _buildDetailRow("Date", formattedDate, colorScheme),
                   const Divider(height: 24),
                   _buildDetailRow("Transaction ID", historyItem['razorpayPaymentId'], colorScheme),
                   const Divider(height: 24),
                   _buildDetailRow("Amount", "₹${historyItem['amount']}", colorScheme, isBold: true, valueColor: colorScheme.primary),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _downloadReceipt(context),
                icon: const Icon(Icons.download, color: Colors.white),
                label: Text(
                  "Download Receipt",
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ColorScheme colorScheme, {bool isBold = false, Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 14, color: colorScheme.onSurfaceVariant)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: isBold ? 18 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
