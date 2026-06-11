import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';

class UpgradeReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> historyItem;

  const UpgradeReceiptScreen({super.key, required this.historyItem});

  Future<void> _downloadReceipt(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get the invoice ID from historyItem
      final invoiceId = historyItem['invoiceId'];
      if (invoiceId == null) {
        if (context.mounted) Navigator.pop(context);
        CustomToast.showError(context, 'Invoice not found');
        return;
      }

      // Get auth token
      await ApiService.loadToken();
      final String? token = ApiService.userToken;
      if (token == null) {
        if (context.mounted) Navigator.pop(context);
        CustomToast.showError(context, 'Authentication failed');
        return;
      }

      // Download invoice from backend
      final response = await http.get(
        Uri.parse('http://103.212.121.139:5000/api/invoices/download/$invoiceId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (context.mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        // Save to downloads folder
        final directory = await getDownloadsDirectory();
        if (directory == null) {
          CustomToast.showError(context, 'Cannot access downloads folder');
          return;
        }

        final fileName = 'Receipt_${historyItem['razorpayPaymentId']}.pdf';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        CustomToast.showSuccess(context, 'Receipt saved successfully');

        // Optional: Share the file
        if (context.mounted) {
          await Share.shareXFiles(
            [XFile(file.path)],
            subject: 'Payment Receipt',
          );
        }
      } else if (response.statusCode == 404) {
        CustomToast.showError(context, 'Invoice not found on server');
      } else if (response.statusCode == 403) {
        CustomToast.showError(context, 'Unauthorized access');
      } else {
        CustomToast.showError(context, 'Error: ${response.statusCode}');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context, false);
        CustomToast.showError(context, 'Error: $e');
      }
    }
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
