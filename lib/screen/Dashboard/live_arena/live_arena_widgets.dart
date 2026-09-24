import 'package:dm_bhatt_tutions/model/live_exam.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

String formatLiveDate(DateTime d) => DateFormat('d MMM yyyy').format(d);
String formatLiveTime(DateTime d) => DateFormat('h:mm a').format(d);

String formatTimeTaken(num? ms) {
  if (ms == null) return '--:--';
  final total = (ms / 1000).round();
  return '${(total ~/ 60).toString().padLeft(2, '0')}:${(total % 60).toString().padLeft(2, '0')}';
}

String formatMarks(num? v) {
  if (v == null) return '-';
  return v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

/// Label + colour for the card state chip.
({String label, Color color}) liveStateStyle(String myState) {
  switch (myState) {
    case 'IN_QUEUE':
      return (label: 'IN QUEUE', color: Colors.orange.shade700);
    case 'LIVE':
      return (label: 'LIVE NOW', color: Colors.green.shade600);
    case 'IN_PROGRESS':
      return (label: 'IN PROGRESS', color: Colors.green.shade600);
    case 'SUBMITTED':
      return (label: 'SUBMITTED', color: Colors.blue.shade600);
    case 'COMPLETED':
      return (label: 'COMPLETED', color: Colors.blueGrey.shade600);
    case 'EXPIRED':
      return (label: 'EXPIRED', color: Colors.grey.shade600);
    case 'CANCELLED':
      return (label: 'CANCELLED', color: Colors.red.shade600);
    default:
      return (label: 'UPCOMING', color: Colors.indigo.shade400);
  }
}

class LiveStateChip extends StatelessWidget {
  final String myState;
  const LiveStateChip({super.key, required this.myState});

  @override
  Widget build(BuildContext context) {
    final s = liveStateStyle(myState);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: s.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: s.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (myState == 'LIVE' || myState == 'IN_PROGRESS') ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            s.label,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: s.color,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class LiveCountPill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const LiveCountPill({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

/// What the main button on a card / waiting room does.
enum LiveAction { joinQueue, enter, resume, viewResult, none }

({LiveAction action, String label}) primaryActionFor(LiveExam exam) {
  switch (exam.myState) {
    case 'UPCOMING':
      return exam.canJoinQueue
          ? (action: LiveAction.joinQueue, label: 'JOIN QUEUE')
          : (
              action: LiveAction.none,
              label: 'Queue opens ${formatLiveTime(exam.queueOpensAt)}',
            );
    case 'IN_QUEUE':
      return (action: LiveAction.none, label: 'IN QUEUE');
    case 'LIVE':
      return (action: LiveAction.enter, label: 'ENTER EXAM');
    case 'IN_PROGRESS':
      return (action: LiveAction.resume, label: 'RESUME EXAM');
    case 'SUBMITTED':
    case 'COMPLETED':
      return (action: LiveAction.viewResult, label: 'VIEW RESULT');
    case 'EXPIRED':
      return (action: LiveAction.none, label: 'EXPIRED');
    case 'CANCELLED':
      return (action: LiveAction.none, label: 'CANCELLED');
    default:
      return (action: LiveAction.none, label: '');
  }
}
