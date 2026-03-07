import 'dart:convert';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class OneLinerHistoryScreen extends StatefulWidget {
  const OneLinerHistoryScreen({super.key});

  @override
  State<OneLinerHistoryScreen> createState() => _OneLinerHistoryScreenState();
}

class _OneLinerHistoryScreenState extends State<OneLinerHistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final response = await ApiService.getDashboardData();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['examResults'] ?? [];
        
        setState(() {
          _history = results
              .where((e) => e['type'] == 'ONELINER')
              .map((e) => {
                'title': e['title'],
                'date': e['date'],
                'accuracy': e['accuracy'] ?? 0,
                'score': e['obtainedMarks'],
                'total': e['totalMarks'],
              })
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error loading one-liner history from API: $e");
      // Fallback to local if API fails? For now just stop loading
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(
        title: "Exam History",
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CustomLoader())
          : _history.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    return _buildHistoryCard(item);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No exam history found",
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final colorScheme = Theme.of(context).colorScheme;
    final date = DateTime.parse(item['date']);
    final formattedDate = DateFormat('MMM dd, yyyy').format(date);

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
          child: Icon(Icons.assignment, color: colorScheme.primary),
        ),
        title: Text(
          item['title'] ?? "One-Liner Exam",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Date: $formattedDate",
              style: GoogleFonts.poppins(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
            Text(
              "Accuracy: ${item['accuracy']}%",
              style: GoogleFonts.poppins(
                fontSize: 12, 
                fontWeight: FontWeight.w600,
                color: (item['accuracy'] as num) >= 70 ? Colors.green : Colors.orange
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "Marks",
              style: GoogleFonts.poppins(fontSize: 10, color: colorScheme.onSurfaceVariant),
            ),
            Text(
              "${item['score']}/${item['total']}",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: colorScheme.primary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
