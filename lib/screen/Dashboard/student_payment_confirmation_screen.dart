import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/landing_screen.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class StudentPaymentConfirmationScreen extends StatelessWidget {
  final Map<String, dynamic> transactionDetails;

  const StudentPaymentConfirmationScreen({
    super.key,
    required this.transactionDetails, // must contain: title, standard, medium, date, transactionId, amountRaw
  });

  Future<void> _downloadReceipt(BuildContext context) async {
    final invoiceId = transactionDetails['invoiceId']?.toString();

    if (invoiceId != null && invoiceId.isNotEmpty) {
      final bytes = await ApiService.downloadInvoice(invoiceId);
      if (bytes != null) {
        await Printing.sharePdf(
          bytes: bytes,
          filename: 'invoice_$invoiceId.pdf',
        );
        return;
      }
      // Server invoice unavailable — fall through to the local receipt.
      if (!context.mounted) return;
    }

    await _buildLocalReceipt(context);
  }

  Future<void> _buildLocalReceipt(BuildContext context) async {
    try {
      final pdf = pw.Document();

      // Load app logo for watermark
      final ByteData data = await rootBundle.load('assets/images/app_logo.png');
      final Uint8List logoBytes = data.buffer.asUint8List();

      // Poppins stays primary for the Latin/English labels; Noto Gujarati/Devanagari
      // are fallbacks so Gujarati/Hindi values (material name, subject, etc.) render
      // instead of tofu boxes. (Same setup as the exam-history PDF.)
      final font = await PdfGoogleFonts.poppinsRegular();
      final boldFont = await PdfGoogleFonts.poppinsBold();
      final theme = pw.ThemeData.withFont(
        base: font,
        bold: boldFont,
        fontFallback: [
          await PdfGoogleFonts.notoSansGujaratiRegular(),
          await PdfGoogleFonts.notoSansDevanagariRegular(),
        ],
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          build: (pw.Context context) {
            return pw.Stack(
              children: [
                // Watermark
                pw.Center(
                  child: pw.Opacity(
                    opacity: 0.1,
                    child: pw.Image(
                      pw.MemoryImage(logoBytes),
                      width: 300,
                      height: 300,
                    ),
                  ),
                ),

                // Content
                pw.Padding(
                  padding: const pw.EdgeInsets.all(32),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Header(
                        level: 0,
                        child: pw.Center(
                          child: pw.Text("Payment Receipt",
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 28,
                                  color: PdfColors.blue900)),
                        ),
                      ),
                      pw.SizedBox(height: 32),
                      pw.Text("Material Name:",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                      pw.Text(transactionDetails['title'] ?? "N/A",
                          style: const pw.TextStyle(fontSize: 18)),
                      pw.Divider(color: PdfColors.grey400),
                      pw.SizedBox(height: 16),
                      if (transactionDetails['standard'] != null && transactionDetails['standard'] != "N/A") ...[
                        _buildPdfRow("Standard", transactionDetails['standard']),
                        pw.SizedBox(height: 12),
                      ],
                      if (transactionDetails['medium'] != null && transactionDetails['medium'] != "N/A") ...[
                        _buildPdfRow("Medium", transactionDetails['medium']),
                        pw.SizedBox(height: 12),
                      ],
                      if (transactionDetails['category'] != null && transactionDetails['category'] != "N/A") ...[
                        _buildPdfRow("Category", transactionDetails['category']),
                        pw.SizedBox(height: 12),
                      ],
                      if (transactionDetails['subject'] != null && transactionDetails['subject'] != "N/A") ...[
                        _buildPdfRow("Subject", transactionDetails['subject']),
                        pw.SizedBox(height: 12),
                      ],
                      _buildPdfRow("Date", transactionDetails['date'] ?? "N/A"),
                      pw.SizedBox(height: 12),
                      _buildPdfRow("Transaction ID", transactionDetails['transactionId'] ?? "N/A"),
                      pw.SizedBox(height: 12),
                      _buildPdfRow("Amount", "₹${transactionDetails['amountRaw']}"),
                      pw.SizedBox(height: 50),
                      pw.Center(
                        child: pw.Text(
                          "Thank you for your purchase!",
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 18,
                              color: PdfColors.grey700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'receipt_${transactionDetails['transactionId'] ?? "dmbhatt"}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        CustomToast.showError(context, "Failed to generate receipt: $e");
      }
    }
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
        pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.black)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(
        title: "Payment Confirmation",
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Success Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Payment Successful!",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 32),

            // Details Card
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    if (transactionDetails['standard'] != null && transactionDetails['standard'] != "N/A") ...[
                      _buildRowItem("Standard", transactionDetails['standard'], colorScheme),
                      const Divider(height: 32),
                    ],
                    if (transactionDetails['medium'] != null && transactionDetails['medium'] != "N/A") ...[
                      _buildRowItem("Medium", transactionDetails['medium'], colorScheme),
                      const Divider(height: 32),
                    ],
                    if (transactionDetails['category'] != null && transactionDetails['category'] != "N/A") ...[
                      _buildRowItem("Category", transactionDetails['category'], colorScheme),
                      const Divider(height: 32),
                    ],
                    if (transactionDetails['subject'] != null && transactionDetails['subject'] != "N/A") ...[
                      _buildRowItem("Subject", transactionDetails['subject'], colorScheme),
                      const Divider(height: 32),
                    ],
                    _buildRowItem("Date", transactionDetails['date'] ?? "N/A", colorScheme),
                    const Divider(height: 32),
                    _buildRowItem("Transaction ID", transactionDetails['transactionId'] ?? "N/A", colorScheme),
                    const Divider(height: 32),
                    _buildRowItem(
                      "Amount", 
                      "₹${transactionDetails['amountRaw']}", 
                      colorScheme,
                      isAmount: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Download Receipt Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _downloadReceipt(context),
                icon: const Icon(Icons.download),
                label: Text(
                  "Download Receipt",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary, // using theme primary
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Back to Dashboard
            TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LandingScreen()),
                  (route) => false,
                );
              },
              child: Text(
                "Back to Dashboard",
                style: GoogleFonts.poppins(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowItem(String title, String value, ColorScheme colorScheme, {bool isAmount = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.poppins(
              fontSize: isAmount ? 18 : 15,
              fontWeight: FontWeight.w600,
              color: isAmount ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
