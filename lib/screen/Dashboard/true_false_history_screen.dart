import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';

class TrueFalseHistoryScreen extends StatefulWidget {
  const TrueFalseHistoryScreen({super.key});

  @override
  State<TrueFalseHistoryScreen> createState() => _TrueFalseHistoryScreenState();
}

class _TrueFalseHistoryScreenState extends State<TrueFalseHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _historyItems = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final historyList = prefs.getStringList('true_false_history') ?? [];
      
      final parsedItems = historyList
          .map((item) => jsonDecode(item) as Map<String, dynamic>)
          .toList();

      setState(() {
        _historyItems = parsedItems;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading true false history: $e");
      setState(() {
        _historyItems = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEntry(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyList = prefs.getStringList('true_false_history') ?? [];
      if (index >= 0 && index < historyList.length) {
        historyList.removeAt(index);
        await prefs.setStringList('true_false_history', historyList);
        _loadHistory();
      }
    } catch (e) {
      debugPrint("Error deleting true false history entry: $e");
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getTranslation(context, 'confirmClearTitle'), style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(_getTranslation(context, 'confirmClearMsg'), style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_getTranslation(context, 'cancel'), style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_getTranslation(context, 'clearAllBtn'), style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('true_false_history');
        _loadHistory();
      } catch (e) {
        debugPrint("Error clearing true false history: $e");
      }
    }
  }

  String _formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = months[dateTime.month - 1];
      final year = dateTime.year;
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return "$month $day, $year • $hour:$minute";
    } catch (_) {
      return isoString;
    }
  }

  String _getTranslation(BuildContext context, String key) {
    final locale = Localizations.localeOf(context).languageCode;
    const translations = {
      'en': {
        'title': 'True / False History',
        'noHistory': 'No history found.',
        'score': 'Score',
        'accuracy': 'Accuracy',
        'clearAll': 'Clear All',
        'confirmClearTitle': 'Clear History',
        'confirmClearMsg': 'Are you sure you want to permanently clear all True/False history?',
        'cancel': 'Cancel',
        'clearAllBtn': 'Clear All',
      },
      'gu': {
        'title': 'ખરા / ખોટાનો ઇતિહાસ',
        'noHistory': 'કોઈ ઇતિહાસ મળ્યો નથી.',
        'score': 'ગુણ',
        'accuracy': 'ચોકસાઈ',
        'clearAll': 'બધું સાફ કરો',
        'confirmClearTitle': 'ઇતિહાસ સાફ કરો',
        'confirmClearMsg': 'શું તમે ખરેખર બધો ખરા/ખોટાનો ઇતિહાસ કાયમ માટે સાફ કરવા માંગો છો?',
        'cancel': 'રદ કરો',
        'clearAllBtn': 'સાફ કરો',
      },
      'hi': {
        'title': 'सही / गलत इतिहास',
        'noHistory': 'कोई इतिहास नहीं मिला।',
        'score': 'अंक',
        'accuracy': 'सटीकता',
        'clearAll': 'सभी साफ़ करें',
        'confirmClearTitle': 'इतिहास साफ़ करें',
        'confirmClearMsg': 'क्या आप वाकई सारा इतिहास स्थायी रूप से साफ़ करना चाहते हैं?',
        'cancel': 'रद्द करें',
        'clearAllBtn': 'साफ़ करें',
      },
      'mr': {
        'title': 'चूक / बरोबर इतिहास',
        'noHistory': 'कोणताही इतिहास आढळला नाही.',
        'score': 'गुण',
        'accuracy': 'अचूकता',
        'clearAll': 'सर्व साफ करा',
        'confirmClearTitle': 'इतिहास नष्ट करा',
        'confirmClearMsg': 'तुम्हाला खात्री आहे की तुम्ही सर्व इतिहास कायमचा हटवू इच्छिता?',
        'cancel': 'रद्द करा',
        'clearAllBtn': 'हटवा',
      },
      'ta': {
        'title': 'சரி / தவறு வரலாறு',
        'noHistory': 'வரலாறு எதுவும் இல்லை.',
        'score': 'மதிப்பெண்',
        'accuracy': 'துல்லியம்',
        'clearAll': 'அனைத்தையும் நீக்கு',
        'confirmClearTitle': 'வரலாற்றை நீக்கு',
        'confirmClearMsg': 'அனைத்து விளையாட்டு வரலாற்றையும் நிரந்தரமாக நீக்க விரும்புகிறீர்களா?',
        'cancel': 'ரத்துசெய்',
        'clearAllBtn': 'நீக்கு',
      }
    };
    final langMap = translations[locale] ?? translations['en']!;
    return langMap[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: CustomAppBar(
        title: _getTranslation(context, 'title'),
        centerTitle: true,
        actions: _historyItems.isNotEmpty
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
                  tooltip: _getTranslation(context, 'clearAll'),
                  onPressed: _clearAll,
                )
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _historyItems.isEmpty
              ? _buildEmptyState(isDark)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _historyItems.length,
                  itemBuilder: (context, index) {
                    final item = _historyItems[index];
                    final title = item['title'] ?? 'True/False Quiz';
                    final subject = item['subject'] ?? 'General';
                    final score = item['score'] ?? 0;
                    final total = item['total'] ?? 0;
                    final timestamp = item['timestamp'] ?? '';
                    final accuracy = total > 0 ? (score / total * 100).toInt() : 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                      color: isDark ? const Color(0xFF1E284A) : Colors.white,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200, width: 1.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            subject,
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _formatDateTime(timestamp),
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: isDark ? Colors.white38 : Colors.grey.shade500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      title,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.grey.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          "${_getTranslation(context, 'score')}: ",
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                                          ),
                                        ),
                                        Text(
                                          "$score / $total",
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: primary,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          "${_getTranslation(context, 'accuracy')}: ",
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                                          ),
                                        ),
                                        Text(
                                          "$accuracy%",
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: accuracy >= 80
                                                ? Colors.green
                                                : (accuracy >= 50 ? Colors.orange : Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                onPressed: () => _deleteEntry(index),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history_rounded,
            size: 64,
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _getTranslation(context, 'noHistory'),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
