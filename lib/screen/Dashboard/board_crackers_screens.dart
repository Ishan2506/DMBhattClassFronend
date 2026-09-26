import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_dropdown.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_filled_button.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/board_cracker_history_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/pdf_preview_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:dm_bhatt_tutions/utils/guest_utils.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:shared_preferences/shared_preferences.dart';

const List<String> _optionLetters = ['A', 'B', 'C', 'D'];

/// Objectives Test Series colours (home banner, headers, leaderboard) - the
/// app's own theme primary (blue.shade900) fading to a lighter blue, so this
/// feature matches the rest of the app instead of using its own brand colour.
const Color kBoardCrackerStart = Color(0xFF0D47A1); // Theme primary (blue.shade900)
const Color kBoardCrackerEnd = Color(0xFF1976D2); // Colors.blue.shade700

String _formatDuration(int totalSeconds) {
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  final s = totalSeconds % 60;
  final mm = m.toString().padLeft(2, '0');
  final ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
}

/// "1 Oct, 8:00 PM" in the device's local time.
String _formatStartAt(dynamic startAt) {
  final parsed = DateTime.tryParse(startAt?.toString() ?? '');
  if (parsed == null) return '';
  return DateFormat('d MMM, h:mm a').format(parsed.toLocal());
}

/// Countdown label: "2d 4h", "3h 12m", or "04:59".
String _formatCountdown(int seconds) {
  if (seconds >= 86400) return "${seconds ~/ 86400}d ${(seconds % 86400) ~/ 3600}h";
  if (seconds >= 3600) return "${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}m";
  return _formatDuration(seconds);
}

bool _hasImage(dynamic value) =>
    value != null && value.toString().isNotEmpty && value.toString() != 'null';

// ---------------------------------------------------------------------------
// Paper list
// ---------------------------------------------------------------------------

class BoardCrackersScreen extends StatefulWidget {
  const BoardCrackersScreen({super.key});

  @override
  State<BoardCrackersScreen> createState() => _BoardCrackersScreenState();
}

class _BoardCrackersScreenState extends State<BoardCrackersScreen> {
  List<dynamic> _papers = [];
  List<String> _subjects = [];
  String? _selectedSubject;
  String? _selectedPaperId;
  bool _isLoading = true;

  // Countdown for scheduled papers. The server sends secondsUntilStart, and
  // we count down from the moment the list arrived - so the lock never
  // depends on the phone's clock being right. The server re-checks on open.
  final Stopwatch _sinceFetch = Stopwatch();
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _fetchPapers();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  int _secondsUntilStart(dynamic paper) {
    if (paper['isLocked'] != true) return 0;
    final total = (paper['secondsUntilStart'] as num?)?.toInt() ?? 0;
    final remaining = total - _sinceFetch.elapsed.inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  bool _isLocked(dynamic paper) => _secondsUntilStart(paper) > 0;

  /// Seconds until the ranked window closes, or null when it never does.
  int? _secondsUntilEnd(dynamic paper) {
    final end = DateTime.tryParse(paper['endAt']?.toString() ?? '');
    if (end == null) return null;
    int total;
    switch (paper['status']) {
      case 'LIVE':
        total = (paper['secondsUntilEnd'] as num?)?.toInt() ?? 0;
        break;
      case 'UPCOMING':
        final start = DateTime.tryParse(paper['startAt']?.toString() ?? '');
        final untilStart = (paper['secondsUntilStart'] as num?)?.toInt() ?? 0;
        total = untilStart + (start == null ? 0 : end.difference(start).inSeconds);
        break;
      default:
        return 0;
    }
    final remaining = total - _sinceFetch.elapsed.inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// UPCOMING (locked) -> LIVE (first attempt ranked) -> ENDED (practice),
  /// advanced locally by the countdown without refetching.
  String _statusOf(dynamic paper) {
    if (_isLocked(paper)) return 'UPCOMING';
    final end = _secondsUntilEnd(paper);
    if (paper['status'] == 'ENDED' || (end != null && end <= 0)) return 'ENDED';
    return 'LIVE';
  }

  bool get _needsTicking => _papers.any((p) {
        if (_isLocked(p)) return true;
        final end = _secondsUntilEnd(p);
        return end != null && end > 0;
      });

  void _syncCountdown() {
    _countdownTimer?.cancel();
    if (!_needsTicking) return;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (!_needsTicking) _countdownTimer?.cancel();
    });
  }

  Future<void> _fetchPapers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? std = prefs.getString('std');
      String? medium = prefs.getString('medium');
      String? stream = prefs.getString('stream');

      final profileResponse = await ApiService.getProfile(forceRefresh: true);
      if (profileResponse.statusCode == 200) {
        final profileData = jsonDecode(profileResponse.body);
        final profile = profileData['profile'];
        std = profile?['std']?.toString() ?? std;
        medium = profile?['medium']?.toString() ?? medium;
        stream = profile?['stream']?.toString() ?? stream;
      }

      // Backward compatibility: some profiles store "11 Science" as the std.
      if (std != null && std.contains(' ')) {
        final parts = std.split(' ');
        std = parts[0];
        if (stream == null || stream == '-' || stream.isEmpty) {
          stream = parts.skip(1).join(' ');
        }
      }

      final response = await ApiService.getAllBoardCrackers(
        std: std,
        medium: medium,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final stdNum =
            int.tryParse(RegExp(r'\d+').firstMatch(std ?? '')?.group(0) ?? '') ??
                0;

        final papers = data.where((p) {
          if (stdNum < 11) return true;
          final paperStream = p['stream']?.toString();
          if (stream == null || paperStream == null) return true;
          if (paperStream.isEmpty || paperStream == 'None' || paperStream == '-') {
            return true;
          }
          return paperStream == stream;
        }).toList();

        if (mounted) {
          _sinceFetch
            ..reset()
            ..start();
          setState(() {
            _papers = papers;
            _subjects =
                papers.map((p) => p['subject'].toString()).toSet().toList();
            if (_selectedSubject != null &&
                !_subjects.contains(_selectedSubject)) {
              _selectedSubject = null;
            }
            // Only one subject - nothing to choose, so pre-select it.
            if (_selectedSubject == null && _subjects.length == 1) {
              _selectedSubject = _subjects.first;
            }
            if (_selectedPaper == null) _selectedPaperId = null;
            _isLoading = false;
          });
          _syncCountdown();
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching board crackers: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _visiblePapers => _selectedSubject == null
      ? []
      : _papers.where((p) => p['subject'] == _selectedSubject).toList();

  dynamic get _selectedPaper {
    for (final p in _visiblePapers) {
      if (p['_id']?.toString() == _selectedPaperId) return p;
    }
    return null;
  }

  void _showNotStartedDialog(dynamic startAt) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_clock_rounded, color: kBoardCrackerStart),
            SizedBox(width: 8),
            Text("Not open yet", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "This paper opens on ${_formatStartAt(startAt)}. "
          "You can start it any time after that.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _openPaper(dynamic paper) async {
    if (_isLocked(paper)) {
      _showNotStartedDialog(paper['startAt']);
      return;
    }
    // Guests (skipped login) get one free paper; logged-in students - free or
    // paid - have no attempt limit.
    if (!await GuestUtils.canGuestAccessExam(context, 'BOARDCRACKER')) return;

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BoardCrackerInstructionScreen(
          paper: paper,
          status: _statusOf(paper),
        ),
      ),
    ).then((_) => _fetchPapers());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedPaper = _selectedPaper;

    return Scaffold(
      appBar: CustomAppBar(
        title: "Objectives Test Series",
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const BoardCrackerHistoryScreen()),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const CustomLoader()
          : Padding(
              padding: P.all24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_papers.isEmpty)
                    _buildEmpty(isDark)
                  else ...[
                    CustomDropdown<String>(
                      labelText: "Subject",
                      hintText: "Select Subject",
                      value: _selectedSubject,
                      items: _subjects,
                      itemLabelBuilder: (String item) => item,
                      onChanged: (value) => setState(() {
                        _selectedSubject = value;
                        _selectedPaperId = null;
                      }),
                    ),
                    blankVerticalSpace16,
                    CustomDropdown<String>(
                      // CustomDropdown only reads its initial value, so rebuild
                      // it when the subject changes to clear the old paper.
                      key: ValueKey('paper-$_selectedSubject'),
                      labelText: "Paper",
                      hintText: "Select Paper",
                      value: _selectedPaperId,
                      items: _visiblePapers
                          .map((p) => p['_id'].toString())
                          .toList(),
                      itemLabelBuilder: (String id) =>
                          _visiblePapers
                              .firstWhere((p) => p['_id'].toString() == id)['title']
                              ?.toString() ??
                          'Objectives Test Series',
                      onChanged: (value) =>
                          setState(() => _selectedPaperId = value),
                    ),
                    if (selectedPaper != null) ...[
                      blankVerticalSpace16,
                      _buildPaperDetails(selectedPaper, theme),
                    ],
                  ],
                  const Spacer(),
                  _buildStartButton(selectedPaper),
                ],
              ),
            ),
    );
  }

  /// Question count, time limit and ranked/practice status of the chosen paper.
  Widget _buildPaperDetails(dynamic paper, ThemeData theme) {
    final count = paper['questionCount'] ?? 0;
    final duration = paper['duration'] ?? 0;
    final secondsLeft = _secondsUntilStart(paper);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          children: [
            _metaItem(Icons.quiz_outlined, "$count MCQs", theme.colorScheme),
            _metaItem(
              Icons.timer_outlined,
              duration > 0 ? "$duration min" : "Untimed",
              theme.colorScheme,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildStatusChip(paper, _statusOf(paper), secondsLeft),
      ],
    );
  }

  Widget _buildStartButton(dynamic selectedPaper) {
    final primary = Theme.of(context).primaryColor;
    final enabled = selectedPaper != null;

    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.065,
      decoration: BoxDecoration(
        gradient: enabled
            ? LinearGradient(
                colors: [primary, primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(S.s12),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: enabled ? () => _openPaper(selectedPaper) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.grey.shade400,
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(S.s12)),
        ),
        child: Text(
          "Start Exam",
          style: TextStyle(
            letterSpacing: 0.5,
            fontSize: MediaQuery.of(context).size.width * 0.045,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(dynamic paper, String status, int secondsToStart) {
    final ranked = paper['myRankedResult'];
    final rankedScore = ranked == null
        ? null
        : "${ranked['obtainedMarks']}/${ranked['totalMarks']}";
    final attempted = paper['attempted'] == true;

    final (MaterialColor color, IconData icon, String text) = switch (status) {
      'UPCOMING' => (
          Colors.orange,
          Icons.lock_clock_rounded,
          "Opens ${_formatStartAt(paper['startAt'])} · in ${_formatCountdown(secondsToStart)}",
        ),
      'LIVE' when attempted => (
          Colors.blue,
          Icons.replay_rounded,
          rankedScore != null
              ? "Ranked score $rankedScore · retakes are practice"
              : "Attempted · retakes are practice",
        ),
      'LIVE' => (
          Colors.green,
          Icons.emoji_events_outlined,
          _secondsUntilEnd(paper) != null
              ? "Ranked · ends ${_formatStartAt(paper['endAt'])} · in ${_formatCountdown(_secondsUntilEnd(paper)!)}"
              : "Ranked · your first attempt counts",
        ),
      _ => (
          Colors.grey,
          Icons.school_outlined,
          rankedScore != null
              ? "Ranked score $rankedScore · now practice only"
              : "Practice mode · ranking closed",
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color.shade800),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaItem(IconData icon, String text, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Icon(Icons.workspace_premium_outlined,
              size: 64, color: isDark ? Colors.white24 : Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No Objectives Test Series papers yet",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "New papers for your standard will appear here.",
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Instructions
// ---------------------------------------------------------------------------

class BoardCrackerInstructionScreen extends StatelessWidget {
  final dynamic paper;

  /// UPCOMING / LIVE / ENDED, as shown on the paper list.
  final String status;

  const BoardCrackerInstructionScreen({
    super.key,
    required this.paper,
    this.status = 'LIVE',
  });

  Widget _buildModeBanner(BuildContext context) {
    final attempted = paper['attempted'] == true;
    final ranked = status == 'LIVE' && !attempted;
    final endAt = paper['endAt'];

    final String text;
    if (ranked) {
      text = endAt != null
          ? "Ranked attempt: this attempt counts on the leaderboard (ranking closes ${_formatStartAt(endAt)}). Only your first attempt is ranked - retakes are practice."
          : "Ranked attempt: this attempt counts on the leaderboard. Only your first attempt is ranked - retakes are practice.";
    } else if (attempted) {
      text =
          "Practice attempt: you've already taken this paper, so this attempt won't change your leaderboard rank.";
    } else {
      text = endAt != null
          ? "Practice mode: ranking closed on ${_formatStartAt(endAt)}. Your score won't count on the leaderboard."
          : "Practice mode: your score won't count on the leaderboard.";
    }

    final color = ranked ? Colors.green : Colors.blueGrey;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ranked ? Icons.emoji_events_rounded : Icons.school_outlined,
              color: color.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: color.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final int count = paper['questionCount'] ?? 0;
    final int duration = paper['duration'] ?? 0;
    final String description = paper['description']?.toString() ?? '';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(title: "Instructions", centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    paper['title']?.toString() ?? 'Objectives Test Series',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    paper['subject']?.toString() ?? '',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _stat(context, "$count", "Questions"),
                      _stat(context, "$count", "Marks"),
                      _stat(context, duration > 0 ? "$duration" : "∞",
                          duration > 0 ? "Minutes" : "No limit"),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildModeBanner(context),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        height: 1.5,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _instruction(context, Icons.check_circle_outline,
                      "Each question has one correct option. Every correct answer is worth 1 mark; there is no negative marking."),
                  if (duration > 0)
                    _instruction(context, Icons.timer_outlined,
                        "The paper is auto-submitted when the $duration-minute timer runs out."),
                  _instruction(context, Icons.grid_view_rounded,
                      "Use the question palette to jump between questions and see which ones are still unanswered."),
                  _instruction(context, Icons.warning_amber_rounded,
                      "Stay in the app until you submit. Leaving the app, using split-screen or floating apps, pressing Back, or taking a screenshot counts as a violation."),
                  _instruction(context, Icons.gpp_bad_outlined,
                      "You get one warning. A second violation submits your paper automatically with the answers given so far."),
                  _instruction(context, Icons.analytics_outlined,
                      "After submitting you'll see your score and the correct answer for every question."),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: count == 0
                      ? null
                      : () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BoardCrackerExamScreen(
                                examId: paper['_id'].toString(),
                                title: paper['title']?.toString() ??
                                    'Objectives Test Series',
                                durationMinutes: duration,
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    "Start Exam Now",
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _instruction(BuildContext context, IconData icon, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.5,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exam
// ---------------------------------------------------------------------------

class BoardCrackerExamScreen extends StatefulWidget {
  final String examId;
  final String title;
  final int durationMinutes;

  const BoardCrackerExamScreen({
    super.key,
    required this.examId,
    required this.title,
    required this.durationMinutes,
  });

  @override
  State<BoardCrackerExamScreen> createState() => _BoardCrackerExamScreenState();
}

/// Why a paper was submitted - stored with the result so admins can tell a
/// finished paper from one cut short by the timer or by violations.
enum BoardCrackerSubmitReason { manual, timeUp, violations }

extension on BoardCrackerSubmitReason {
  String get apiValue => switch (this) {
        BoardCrackerSubmitReason.manual => 'MANUAL',
        BoardCrackerSubmitReason.timeUp => 'TIME_UP',
        BoardCrackerSubmitReason.violations => 'VIOLATIONS',
      };
}

class _BoardCrackerExamScreenState extends State<BoardCrackerExamScreen>
    with WidgetsBindingObserver {
  /// The paper is auto-submitted on this many violations.
  static const int _maxViolations = 2;

  /// Split-screen, floating apps and the notification shade only make the app
  /// `inactive`. Brief blips (a system permission prompt, biometrics) are
  /// ignored; staying inactive longer than this counts as a violation.
  static const Duration _inactiveGrace = Duration(seconds: 3);

  List<Map<String, dynamic>> _questions = [];
  final Map<int, String> _selected = {};
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _loadError;
  bool _isSubmitting = false;
  bool _submitted = false;

  // RANKED (first attempt in the window) or PRACTICE - decided by the server.
  String _attemptMode = 'PRACTICE';

  int _violationCount = 0;
  final List<String> _violationLog = [];
  // One trip away from the exam counts once, even though leaving fires
  // inactive -> hidden -> paused in a row.
  bool _awayCounted = false;
  String? _pendingWarning;
  Timer? _inactiveTimer;
  bool _warningOpen = false;

  Timer? _timer;
  // Wall-clock based, so time spent outside the app still counts against the
  // limit (Dart timers stop while the app is suspended).
  DateTime? _startedAt;
  int _elapsedSeconds = 0;

  int get _limitSeconds => widget.durationMinutes * 60;
  bool get _isTimed => widget.durationMinutes > 0;
  int get _remainingSeconds =>
      (_limitSeconds - _elapsedSeconds).clamp(0, _limitSeconds);
  bool get _examActive =>
      !_isLoading && _loadError == null && !_isSubmitting && !_submitted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _inactiveTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _disableScreenProtection();
    super.dispose();
  }

  // --- Screen protection --------------------------------------------------

  Future<void> _enableScreenProtection() async {
    if (kIsWeb) return;
    try {
      // Android: FLAG_SECURE blocks screenshots and screen recording.
      // iOS: screenshots come out blank.
      await ScreenProtector.preventScreenshotOn();
      if (Platform.isIOS) {
        ScreenProtector.addListener(
          () => _registerViolation("A screenshot was taken during the exam."),
          (isRecording) {
            if (isRecording) {
              _registerViolation(
                  "Screen recording was started during the exam.");
            }
          },
        );
        if (await ScreenProtector.isRecording()) {
          _registerViolation("The screen is being recorded.");
        }
      }
    } catch (e) {
      debugPrint("Screen protection unavailable: $e");
    }
  }

  Future<void> _disableScreenProtection() async {
    if (kIsWeb) return;
    try {
      await ScreenProtector.preventScreenshotOff();
      if (Platform.isIOS) ScreenProtector.removeListener();
    } catch (e) {
      debugPrint("Error disabling screen protection: $e");
    }
  }

  // --- Leaving the app ----------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        if (!_examActive || _awayCounted) return;
        _inactiveTimer ??= Timer(_inactiveGrace, () {
          _inactiveTimer = null;
          _markAway("You opened another app or window over the exam.");
        });
        break;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _inactiveTimer?.cancel();
        _inactiveTimer = null;
        if (_examActive) _markAway("You left the app during the exam.");
        break;
      case AppLifecycleState.resumed:
        _inactiveTimer?.cancel();
        _inactiveTimer = null;
        _awayCounted = false;
        _tick(); // catch the clock up on time spent away
        final warning = _pendingWarning;
        _pendingWarning = null;
        if (warning != null && _examActive) _showWarning(warning);
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  void _markAway(String message) {
    if (_awayCounted) return;
    _awayCounted = true;
    // The warning is shown once they come back to the app.
    _registerViolation(message, showWarningNow: false);
  }

  // --- Violations ---------------------------------------------------------

  void _registerViolation(String message, {bool showWarningNow = true}) {
    if (!_examActive || !mounted) return;
    setState(() {
      _violationCount++;
      _violationLog.add(message);
    });

    ApiService.updateViolationCount(
      examId: widget.examId,
      examType: 'BOARD_CRACKER',
    ).catchError((e) {
      debugPrint("Error updating violation: $e");
      return http.Response('', 500);
    });

    if (_violationCount >= _maxViolations) {
      CustomToast.showError(
          context, "Multiple violations detected. Auto-submitting your paper.");
      _submit(BoardCrackerSubmitReason.violations);
      return;
    }

    if (showWarningNow) {
      _showWarning(message);
    } else {
      _pendingWarning = message;
    }
  }

  void _showWarning(String message) {
    if (!mounted || _warningOpen) return;
    _warningOpen = true;
    final remaining = _maxViolations - _violationCount;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              "Warning $_violationCount of $_maxViolations",
              style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          "$message\n\n"
          "${remaining == 1 ? 'One more violation' : '$remaining more violations'} "
          "will automatically submit your paper. Stay in the app, don't use "
          "split-screen or floating apps, and don't take screenshots.",
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("I Understand"),
          ),
        ],
      ),
    ).whenComplete(() => _warningOpen = false);
  }

  // --- Loading & timer ----------------------------------------------------

  Future<void> _fetchQuestions() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final response = await ApiService.getBoardCrackerById(widget.examId);
      if (response.statusCode == 403) {
        final body = jsonDecode(response.body);
        if (body is Map && body['code'] == 'NOT_STARTED') {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _loadError =
                "This paper opens on ${_formatStartAt(body['startAt'])}. Please come back then.";
          });
          return;
        }
      }
      if (response.statusCode != 200) {
        throw Exception("Server returned ${response.statusCode}");
      }
      final data = jsonDecode(response.body);
      final List<dynamic> raw = data['questions'] ?? [];
      // A reopened ranked attempt continues its server-side clock.
      final alreadyElapsed = (data['elapsedSeconds'] as num?)?.toInt() ?? 0;
      if (!mounted) return;
      setState(() {
        _questions = raw.map((q) => Map<String, dynamic>.from(q)).toList();
        _attemptMode = data['attemptMode']?.toString() ?? 'PRACTICE';
        _isLoading = false;
      });
      _startTimer(alreadyElapsed: alreadyElapsed);
      _enableScreenProtection();
      if (alreadyElapsed > 5 && mounted) {
        CustomToast.showInfo(context,
            "Resuming your ranked attempt - the timer kept running while you were away.");
      }
    } catch (e) {
      debugPrint("Error loading board cracker: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = "Could not load this paper. Please try again.";
        });
      }
    }
  }

  void _startTimer({int alreadyElapsed = 0}) {
    _startedAt = DateTime.now().subtract(Duration(seconds: alreadyElapsed));
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted || _startedAt == null || _submitted) return;
    setState(() {
      _elapsedSeconds = DateTime.now().difference(_startedAt!).inSeconds;
    });
    if (_isTimed && _elapsedSeconds >= _limitSeconds && !_isSubmitting) {
      _timer?.cancel();
      CustomToast.showInfo(context, "Time's up! Submitting your paper.");
      _submit(BoardCrackerSubmitReason.timeUp);
    }
  }

  List<String> _availableOptions(Map<String, dynamic> q) => _optionLetters
      .where((l) =>
          (q['option$l']?.toString().trim().isNotEmpty ?? false) ||
          _hasImage(q['option${l}Image']))
      .toList();

  Future<void> _confirmSubmit() async {
    final unanswered = _questions.length - _selected.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Submit paper?",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(unanswered > 0
            ? "You have $unanswered unanswered question${unanswered == 1 ? '' : 's'}. You can't change your answers after submitting."
            : "You have answered every question. You can't change your answers after submitting."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Keep Going"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Submit"),
          ),
        ],
      ),
    );
    if (confirmed == true) _submit(BoardCrackerSubmitReason.manual);
  }

  Future<void> _submit(BoardCrackerSubmitReason reason) async {
    if (_isSubmitting || _submitted || !mounted) return;
    _isSubmitting = true;
    _timer?.cancel();
    _inactiveTimer?.cancel();

    // An auto-submit can fire while a warning, the confirm dialog or the
    // palette is open. Close them first so the result screen replaces the
    // exam screen rather than the popup.
    final examRoute = ModalRoute.of(context);
    Navigator.of(context).popUntil((route) => route == examRoute);

    final answers = <Map<String, dynamic>>[];
    for (int i = 0; i < _questions.length; i++) {
      answers.add({
        'questionId': _questions[i]['_id'],
        'selectedAnswer': _selected[i] ?? '',
      });
    }

    CustomLoader.show(context);
    try {
      final response = await ApiService.submitBoardCrackerResult(
        examId: widget.examId,
        answers: answers,
        timeTakenSeconds: _elapsedSeconds,
        violationCount: _violationCount,
        violations: _violationLog,
        submitReason: reason.apiValue,
      );
      if (!mounted) return;
      CustomLoader.hide(context);

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception("Server returned ${response.statusCode}");
      }

      _submitted = true;
      await _disableScreenProtection();
      if (await GuestUtils.isGuest()) {
        await GuestUtils.incrementGuestExamCount('BOARDCRACKER');
      }
      if (!mounted) return;

      final result = jsonDecode(response.body) as Map<String, dynamic>;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BoardCrackerResultScreen(
            examId: widget.examId,
            title: widget.title,
            questions: _questions,
            result: result,
            timeTakenSeconds:
                (result['timeTakenSeconds'] as num?)?.toInt() ?? _elapsedSeconds,
            violationCount: _violationCount,
            submitReason: reason,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error submitting board cracker: $e");
      if (!mounted) return;
      CustomLoader.hide(context);
      // Answers are kept in memory, so the student can simply retry. The
      // exam stays locked (_isSubmitting) - a failed submit must not reopen it.
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text("Submission failed"),
          content: const Text(
              "We couldn't submit your paper. Check your internet connection and try again - your answers are saved."),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _isSubmitting = false;
                _submit(reason);
              },
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }
  }

  void _openPalette() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Answered ${_selected.length} of ${_questions.length}",
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: GridView.builder(
                      shrinkWrap: true,
                      itemCount: _questions.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                      itemBuilder: (_, i) {
                        final answered = _selected.containsKey(i);
                        final isCurrent = i == _currentIndex;
                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            setState(() => _currentIndex = i);
                          },
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: answered
                                  ? colorScheme.primary
                                  : colorScheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: isCurrent
                                  ? Border.all(color: Colors.orange, width: 2)
                                  : null,
                            ),
                            child: Text(
                              "${i + 1}",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: answered
                                    ? Colors.white
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loaded = !_isLoading && _loadError == null && _questions.isNotEmpty;
    final lowTime = _isTimed && _remainingSeconds <= 60;
    final timeColor = lowTime ? Colors.orangeAccent : Colors.white;

    return PopScope(
      canPop: _isLoading || _loadError != null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _registerViolation("Back navigation is not allowed during the exam.");
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: CustomAppBar(
          title: loaded
              ? "Question ${_currentIndex + 1}/${_questions.length}"
              : widget.title,
          centerTitle: true,
          actions: [
            if (loaded) ...[
              IconButton(
                tooltip: "Question palette",
                icon: const Icon(Icons.grid_view_rounded, color: Colors.white),
                onPressed: _openPalette,
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    Icon(Icons.timer, color: timeColor),
                    const SizedBox(width: 6),
                    Text(
                      _formatDuration(
                          _isTimed ? _remainingSeconds : _elapsedSeconds),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: timeColor),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        body: _isLoading
            ? const Center(child: CustomLoader())
            : _loadError != null
                ? _buildError()
                : _questions.isEmpty
                    ? const Center(child: Text("No questions in this paper."))
                    : _buildExam(colorScheme),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_loadError!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchQuestions,
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExam(ColorScheme colorScheme) {
    final q = _questions[_currentIndex];
    final options = _availableOptions(q);
    final isLast = _currentIndex == _questions.length - 1;
    final ranked = _attemptMode == 'RANKED';

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // "Question X of Y" chip, plus ranked/practice and violations.
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: colorScheme.primary.withOpacity(0.3)),
                  ),
                  child: Text(
                    "Question ${_currentIndex + 1} of ${_questions.length}",
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (ranked ? Colors.green : Colors.blueGrey)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    ranked ? "RANKED" : "PRACTICE",
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: ranked
                          ? Colors.green.shade700
                          : Colors.blueGrey.shade700,
                    ),
                  ),
                ),
                const Spacer(),
                if (_violationCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 16, color: Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          "$_violationCount/$_maxViolations",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Question card and options scroll together.
          Expanded(
            child: SingleChildScrollView(
              key: ValueKey(_currentIndex),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(24),
                    constraints: const BoxConstraints(minHeight: 120),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_hasImage(q['questionImage']))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                ApiService.getFileUrl(q['questionImage']),
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 100,
                                  color: Colors.white24,
                                  child: const Icon(Icons.broken_image,
                                      color: Colors.white, size: 40),
                                ),
                              ),
                            ),
                          ),
                        Text(
                          q['question']?.toString() ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.4,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: options
                          .map((letter) => _buildOption(q, letter, colorScheme))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom navigation
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 24, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentIndex > 0)
                  IconButton(
                    tooltip: "Previous",
                    onPressed: () => setState(() => _currentIndex--),
                    icon: Icon(Icons.arrow_back, color: Colors.grey[600]),
                  ),
                if (!isLast)
                  TextButton(
                    onPressed: () => setState(() => _currentIndex++),
                    child: Text(
                      "Skip",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                const Spacer(),
                ElevatedButton(
                  // Next needs an answer (use Skip otherwise); Submit is
                  // always allowed since unanswered questions count as skipped.
                  onPressed: isLast
                      ? _confirmSubmit
                      : (_selected.containsKey(_currentIndex)
                          ? () => setState(() => _currentIndex++)
                          : null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isLast ? "Submit" : "Next",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
      Map<String, dynamic> q, String letter, ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;
    final isSelected = _selected[_currentIndex] == letter;
    final text = q['option$letter']?.toString() ?? '';
    final image = q['option${letter}Image'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.5)
              : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() {
          // Tapping the selected option again clears it.
          if (isSelected) {
            _selected.remove(_currentIndex);
          } else {
            _selected[_currentIndex] = letter;
          }
        }),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Text(
                  letter,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (text.isNotEmpty)
                      Text(
                        text,
                        style: textTheme.titleMedium?.copyWith(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    if (_hasImage(image))
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            ApiService.getFileUrl(image),
                            height: 120,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Result
// ---------------------------------------------------------------------------

class BoardCrackerResultScreen extends StatelessWidget {
  final String examId;
  final String title;
  final List<Map<String, dynamic>> questions;
  final Map<String, dynamic> result;
  final int timeTakenSeconds;
  final int violationCount;
  final BoardCrackerSubmitReason submitReason;

  const BoardCrackerResultScreen({
    super.key,
    required this.examId,
    required this.title,
    required this.questions,
    required this.result,
    required this.timeTakenSeconds,
    this.violationCount = 0,
    this.submitReason = BoardCrackerSubmitReason.manual,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final int obtained = result['obtainedMarks'] ?? 0;
    final int total = result['totalMarks'] ?? questions.length;
    final int correct = result['correctCount'] ?? 0;
    final int wrong = result['wrongCount'] ?? 0;
    final int skipped = result['skippedCount'] ?? 0;
    final num accuracy = result['accuracy'] ?? 0;

    final Map<String, dynamic> reviewById = {
      for (final r in (result['review'] as List<dynamic>? ?? []))
        r['questionId'].toString(): r,
    };

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: "Result",
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kBoardCrackerStart, kBoardCrackerEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "$obtained / $total",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "$accuracy% · ${_formatDuration(timeTakenSeconds)}",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildRankCard(context),
          if (submitReason != BoardCrackerSubmitReason.manual ||
              violationCount > 0) ...[
            const SizedBox(height: 16),
            _buildSubmitNotice(),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _countTile("Correct", correct, Colors.green),
              _countTile("Wrong", wrong, Colors.red),
              _countTile("Skipped", skipped, Colors.grey),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            "Answer Review",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(questions.length, (i) {
            final q = questions[i];
            final review = reviewById[q['_id'].toString()];
            return _reviewCard(context, i, q, review);
          }),
          const SizedBox(height: 12),
          CustomFilledButton(
            label: "Preview Question Paper",
            icon: Icons.visibility_rounded,
            onPressed: () => _previewPdf(context, reviewById),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text("Back to Objectives Test Series"),
          ),
        ],
      ),
    );
  }

  Future<void> _previewPdf(
      BuildContext context, Map<String, dynamic> reviewById) async {
    CustomLoader.show(context);
    try {
      final bytes = await buildObjectivesPaperPdf(
        title: title,
        obtainedMarks: result['obtainedMarks'] ?? 0,
        totalMarks: result['totalMarks'] ?? questions.length,
        accuracy: result['accuracy'] ?? 0,
        questions: questions,
        reviewById: reviewById,
      );
      if (!context.mounted) return;
      CustomLoader.hide(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfPreviewScreen(
            product: {'name': title, 'id': examId},
            pdfBytes: bytes,
            isFullAccess: true,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      CustomLoader.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating preview: $e')),
      );
    }
  }

  Widget _buildRankCard(BuildContext context) {
    final bool isRanked = result['isRanked'] == true;
    final rank = result['rank'];
    final totalRanked = result['totalRanked'];

    final String headline;
    final String detail;
    if (isRanked) {
      headline = "Rank #$rank of $totalRanked";
      detail = "This attempt counts on the leaderboard.";
    } else {
      headline = "Practice attempt";
      detail = switch (result['practiceReason']) {
        'ALREADY_ATTEMPTED' =>
          "Only your first attempt is ranked, so this score isn't on the leaderboard.",
        'ENDED' =>
          "Ranking for this paper has closed, so this score isn't on the leaderboard.",
        'RANKED_TIME_EXPIRED' =>
          "Your ranked attempt ran out of time before it was submitted, so this one is practice.",
        'GUEST' => "Log in to appear on the leaderboard.",
        _ => "This score isn't counted on the leaderboard.",
      };
    }

    final color = isRanked ? kBoardCrackerStart : Colors.blueGrey;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isRanked ? Icons.emoji_events_rounded : Icons.school_outlined,
                color: isRanked ? Colors.amber.shade700 : color,
              ),
              const SizedBox(width: 8),
              Text(
                headline,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(detail, style: GoogleFonts.poppins(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSubmitNotice() {
    final (IconData icon, Color color, String text) = switch (submitReason) {
      BoardCrackerSubmitReason.violations => (
          Icons.gpp_bad_outlined,
          Colors.red,
          "Auto-submitted after $violationCount exam violations.",
        ),
      BoardCrackerSubmitReason.timeUp => (
          Icons.timer_off_outlined,
          Colors.orange,
          "Auto-submitted because time ran out.",
        ),
      BoardCrackerSubmitReason.manual => (
          Icons.warning_amber_rounded,
          Colors.orange,
          "$violationCount exam violation${violationCount == 1 ? '' : 's'} recorded during this paper.",
        ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _countTile(String label, int value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              "$value",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label, style: GoogleFonts.poppins(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _reviewCard(BuildContext context, int index, Map<String, dynamic> q,
      dynamic review) {
    final colorScheme = Theme.of(context).colorScheme;
    final String selected = review?['selectedAnswer']?.toString() ?? '';
    final String correct = review?['correctAnswer']?.toString() ?? '';
    final String explanation = review?['explanation']?.toString() ?? '';
    final bool isCorrect = review?['isCorrect'] == true;

    final statusColor = selected.isEmpty
        ? Colors.grey
        : (isCorrect ? Colors.green : Colors.red);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  "Q${index + 1}. ${q['question'] ?? ''}",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                selected.isEmpty
                    ? Icons.remove_circle_outline
                    : (isCorrect ? Icons.check_circle : Icons.cancel),
                color: statusColor,
              ),
            ],
          ),
          if (_hasImage(q['questionImage']))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Image.network(
                ApiService.getFileUrl(q['questionImage']),
                height: 120,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          const SizedBox(height: 8),
          ..._optionLetters
              .where((l) => (q['option$l']?.toString().trim().isNotEmpty ??
                  false))
              .map((l) {
            final isAnswer = l == correct;
            final isWrongPick = l == selected && !isCorrect;
            final color = isAnswer
                ? Colors.green
                : (isWrongPick ? Colors.red : colorScheme.onSurfaceVariant);
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$l. ",
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, color: color),
                  ),
                  Expanded(
                    child: Text(
                      q['option$l'].toString(),
                      style: GoogleFonts.poppins(
                        color: color,
                        fontWeight: isAnswer || isWrongPick
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (l == selected)
                    Text(
                      " (your answer)",
                      style: GoogleFonts.poppins(fontSize: 11, color: color),
                    ),
                ],
              ),
            );
          }),
          if (explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              explanation,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Leaderboard
// ---------------------------------------------------------------------------

/// Ranked results for one paper: each student's first attempt inside the
/// ranked window, ordered by marks and then time taken.
class BoardCrackerLeaderboardScreen extends StatefulWidget {
  final String examId;
  final String title;

  const BoardCrackerLeaderboardScreen({
    super.key,
    required this.examId,
    required this.title,
  });

  @override
  State<BoardCrackerLeaderboardScreen> createState() =>
      _BoardCrackerLeaderboardScreenState();
}

class _BoardCrackerLeaderboardScreenState
    extends State<BoardCrackerLeaderboardScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response =
          await ApiService.getBoardCrackerLeaderboard(widget.examId);
      if (response.statusCode != 200) {
        throw Exception("Server returned ${response.statusCode}");
      }
      if (!mounted) return;
      setState(() {
        _data = jsonDecode(response.body) as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading leaderboard: $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = "Could not load the leaderboard.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F1626) : const Color(0xFFF2F4F8),
      appBar: const CustomAppBar(title: "Leaderboard", centerTitle: true),
      body: _isLoading
          ? const CustomLoader()
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _load, child: const Text("Retry")),
                    ],
                  ),
                )
              : RefreshIndicator(onRefresh: _load, child: _buildBody(theme)),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final entries = (_data?['entries'] as List<dynamic>? ?? []);
    final me = _data?['me'];
    final exam = _data?['exam'] ?? {};
    final int total = (_data?['totalParticipants'] as num?)?.toInt() ?? 0;
    final meInTop = entries.any((e) => e['isMe'] == true);

    final String statusText = switch (exam['status']) {
      'LIVE' => exam['endAt'] != null
          ? "Ranking open until ${_formatStartAt(exam['endAt'])}"
          : "Ranking open",
      'ENDED' => "Ranking closed · final standings",
      _ => "Not started yet",
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kBoardCrackerStart, kBoardCrackerEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exam['title']?.toString() ?? widget.title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "$total ranked participant${total == 1 ? '' : 's'} · $statusText",
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                "Only first attempts are ranked. Practice attempts don't count.",
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (me != null && !meInTop) ...[
          Text("Your position",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _LeaderboardEntryTile(entry: me),
          const SizedBox(height: 16),
        ],
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 48),
            child: Column(
              children: [
                Icon(Icons.leaderboard_outlined,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  "No ranked attempts yet",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          )
        else
          ...entries.map((e) => _LeaderboardEntryTile(entry: e)),
      ],
    );
  }
}

/// One row of a paper's standings; shared by the full leaderboard screen and
/// the home-page leaderboard card.
class _LeaderboardEntryTile extends StatelessWidget {
  final dynamic entry;
  final bool showTime;

  const _LeaderboardEntryTile({required this.entry, this.showTime = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final int rank = (entry['rank'] as num?)?.toInt() ?? 0;
    final bool isMe = entry['isMe'] == true;
    final String name = entry['name']?.toString() ?? 'Student';
    final String photo = ApiService.getFileUrl(entry['photoPath']?.toString());
    const medalColors = [Color(0xFFFFC107), Color(0xFFB0BEC5), Color(0xFFCD7F32)];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe
            ? kBoardCrackerStart.withOpacity(0.1)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe
              ? kBoardCrackerStart.withOpacity(0.5)
              : colorScheme.outline.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: rank >= 1 && rank <= 3
                ? Icon(Icons.emoji_events_rounded,
                    color: medalColors[rank - 1], size: 26)
                : Text(
                    "#$rank",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: kBoardCrackerEnd.withOpacity(0.15),
            backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
            child: photo.isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: kBoardCrackerEnd,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? "$name (You)" : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (showTime)
                  Text(
                    "Time ${_formatDuration((entry['timeTakenSeconds'] as num?)?.toInt() ?? 0)}",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            "${entry['obtainedMarks']}/${entry['totalMarks']}",
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: kBoardCrackerStart,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home-page combined leaderboard card
// ---------------------------------------------------------------------------

/// Home-page podium (2nd · 1st · 3rd) for the combined Objectives Test
/// Series standings: total ranked marks across every currently-open paper
/// for the student's std, not one leaderboard per paper. Hidden until the
/// student's standard has at least one open paper.
class BoardCrackerLeaderboardCard extends StatefulWidget {
  const BoardCrackerLeaderboardCard({super.key});

  @override
  State<BoardCrackerLeaderboardCard> createState() =>
      _BoardCrackerLeaderboardCardState();
}

class _BoardCrackerLeaderboardCardState
    extends State<BoardCrackerLeaderboardCard> {
  Map<String, dynamic>? _data;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? std = prefs.getString('std');
      String? medium = prefs.getString('medium');
      String? stream = prefs.getString('stream');
      // Some profiles store "11 Science" as the std.
      if (std != null && std.contains(' ')) {
        final parts = std.split(' ');
        std = parts[0];
        if (stream == null || stream == '-' || stream.isEmpty) {
          stream = parts.skip(1).join(' ');
        }
      }

      final response = await ApiService.getCombinedBoardCrackerLeaderboard(
        std: std,
        medium: medium,
        stream: stream,
      );
      if (response.statusCode != 200) return;

      if (!mounted) return;
      setState(() {
        _data = jsonDecode(response.body) as Map<String, dynamic>;
        _loaded = true;
      });
    } catch (e) {
      debugPrint("Error loading home leaderboard: $e");
      if (mounted) setState(() => _loaded = true);
    }
  }

  void _openFullLeaderboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CombinedBoardCrackerLeaderboardScreen(),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final papers = (_data?['papers'] as List<dynamic>? ?? []);
    // Nothing open for this student's std - stay hidden, same as before.
    if (!_loaded || papers.isEmpty) return const SizedBox.shrink();

    final entries = (_data?['entries'] as List<dynamic>? ?? []);
    final screenWidth = MediaQuery.of(context).size.width;
    dynamic at(int i) => i < entries.length ? entries[i] : null;

    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth * 0.03),
      child: GestureDetector(
        onTap: _openFullLeaderboard,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kBoardCrackerStart, kBoardCrackerEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kBoardCrackerStart.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.leaderboard_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Test Series Leaderboard",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Combined across ${papers.length} open paper${papers.length == 1 ? '' : 's'}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "View all",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white, size: 18),
                ],
              ),
              const SizedBox(height: 12),
              if (entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    "No ranked attempts yet — be the first!",
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildPodiumSpot(at(1), 2, 56, Colors.grey.shade300),
                  _buildPodiumSpot(at(0), 1, 70, Colors.amber),
                  _buildPodiumSpot(at(2), 3, 56, Colors.brown.shade300),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// One podium position; an empty spot shows a placeholder until someone
  /// takes that rank.
  Widget _buildPodiumSpot(dynamic entry, int rank, double size, Color color) {
    final String fullName = entry?['name']?.toString() ?? '';
    final String firstName =
        fullName.trim().isEmpty ? '' : fullName.trim().split(' ').first;
    final bool isMe = entry?['isMe'] == true;
    final String photo =
        entry == null ? '' : ApiService.getFileUrl(entry['photoPath']?.toString());

    return SizedBox(
      width: 96,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(
                margin: EdgeInsets.only(top: rank == 1 ? 18 : 0, bottom: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: entry == null ? Colors.white38 : color, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: size / 2,
                  backgroundColor: entry == null
                      ? Colors.white.withOpacity(0.15)
                      : Colors.white,
                  backgroundImage:
                      photo.isNotEmpty ? NetworkImage(photo) : null,
                  child: photo.isNotEmpty
                      ? null
                      : entry == null
                          ? Icon(Icons.person_outline_rounded,
                              color: Colors.white70, size: size * 0.45)
                          : Text(
                              firstName.isNotEmpty
                                  ? firstName[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.poppins(
                                fontSize: size * 0.4,
                                fontWeight: FontWeight.bold,
                                color: kBoardCrackerStart,
                              ),
                            ),
                ),
              ),
              if (rank == 1)
                const Positioned(
                  top: 0,
                  child: Icon(Icons.workspace_premium,
                      color: Colors.amber, size: 28),
                ),
              Positioned(
                bottom: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  decoration: BoxDecoration(
                    color: entry == null ? Colors.white38 : color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "$rank",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            entry == null ? "—" : (isMe ? "You" : firstName),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          Text(
            entry == null
                ? " "
                : "${entry['obtainedMarks']}/${entry['totalMarks']}",
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Combined leaderboard (full screen)
// ---------------------------------------------------------------------------

/// Full standings for the combined leaderboard: total ranked marks across
/// every currently-open Objectives Test Series paper for the student's std.
class CombinedBoardCrackerLeaderboardScreen extends StatefulWidget {
  const CombinedBoardCrackerLeaderboardScreen({super.key});

  @override
  State<CombinedBoardCrackerLeaderboardScreen> createState() =>
      _CombinedBoardCrackerLeaderboardScreenState();
}

class _CombinedBoardCrackerLeaderboardScreenState
    extends State<CombinedBoardCrackerLeaderboardScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      String? std = prefs.getString('std');
      String? medium = prefs.getString('medium');
      String? stream = prefs.getString('stream');
      if (std != null && std.contains(' ')) {
        final parts = std.split(' ');
        std = parts[0];
        if (stream == null || stream == '-' || stream.isEmpty) {
          stream = parts.skip(1).join(' ');
        }
      }

      final response = await ApiService.getCombinedBoardCrackerLeaderboard(
        std: std,
        medium: medium,
        stream: stream,
      );
      if (response.statusCode != 200) {
        throw Exception("Server returned ${response.statusCode}");
      }
      if (!mounted) return;
      setState(() {
        _data = jsonDecode(response.body) as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading combined leaderboard: $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = "Could not load the leaderboard.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F1626) : const Color(0xFFF2F4F8),
      appBar: const CustomAppBar(title: "Leaderboard", centerTitle: true),
      body: _isLoading
          ? const CustomLoader()
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _load, child: const Text("Retry")),
                    ],
                  ),
                )
              : RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    final entries = (_data?['entries'] as List<dynamic>? ?? []);
    final me = _data?['me'];
    final meInTop = entries.any((e) => e['isMe'] == true);
    // Ranks 1-3 go on the podium; the rest are listed below it.
    final rest = entries.length > 3 ? entries.sublist(3) : <dynamic>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 48),
            child: Column(
              children: [
                Icon(Icons.leaderboard_outlined,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  "No ranked attempts yet",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          )
        else ...[
          _buildPodium(entries),
          const SizedBox(height: 20),
          if (me != null && !meInTop) ...[
            Text("Your position",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _LeaderboardEntryTile(entry: me),
            const SizedBox(height: 16),
          ],
          if (rest.isNotEmpty)
            ...rest.map(
                (e) => _LeaderboardEntryTile(entry: e, showTime: false)),
        ],
      ],
    );
  }

  /// Top 3 shown as a podium (2nd · 1st · 3rd); an empty spot shows a
  /// placeholder until someone takes that rank.
  Widget _buildPodium(List<dynamic> entries) {
    dynamic at(int i) => i < entries.length ? entries[i] : null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kBoardCrackerStart, kBoardCrackerEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kBoardCrackerStart.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildPodiumSpot(at(1), 2, 64, Colors.grey.shade300),
          _buildPodiumSpot(at(0), 1, 80, Colors.amber),
          _buildPodiumSpot(at(2), 3, 64, Colors.brown.shade300),
        ],
      ),
    );
  }

  /// One podium position; an empty spot shows a placeholder until someone
  /// takes that rank. Same look as the home-page leaderboard card's podium.
  Widget _buildPodiumSpot(dynamic entry, int rank, double size, Color color) {
    final String fullName = entry?['name']?.toString() ?? '';
    final String firstName =
        fullName.trim().isEmpty ? '' : fullName.trim().split(' ').first;
    final bool isMe = entry?['isMe'] == true;
    final String photo =
        entry == null ? '' : ApiService.getFileUrl(entry['photoPath']?.toString());

    return SizedBox(
      width: 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(
                margin: EdgeInsets.only(top: rank == 1 ? 18 : 0, bottom: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: entry == null ? Colors.white38 : color, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: size / 2,
                  backgroundColor: entry == null
                      ? Colors.white.withOpacity(0.15)
                      : Colors.white,
                  backgroundImage:
                      photo.isNotEmpty ? NetworkImage(photo) : null,
                  child: photo.isNotEmpty
                      ? null
                      : entry == null
                          ? Icon(Icons.person_outline_rounded,
                              color: Colors.white70, size: size * 0.45)
                          : Text(
                              firstName.isNotEmpty
                                  ? firstName[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.poppins(
                                fontSize: size * 0.4,
                                fontWeight: FontWeight.bold,
                                color: kBoardCrackerStart,
                              ),
                            ),
                ),
              ),
              if (rank == 1)
                const Positioned(
                  top: 0,
                  child: Icon(Icons.workspace_premium,
                      color: Colors.amber, size: 30),
                ),
              Positioned(
                bottom: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  decoration: BoxDecoration(
                    color: entry == null ? Colors.white38 : color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "$rank",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            entry == null ? "—" : (isMe ? "You" : firstName),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          Text(
            entry == null
                ? " "
                : "${entry['obtainedMarks']}/${entry['totalMarks']}",
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
