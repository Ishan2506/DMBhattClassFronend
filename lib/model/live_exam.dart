/// A Live Arena exam as the student sees it.
///
/// Everything that decides what the student may do — [status], [myState] and
/// the `can*` flags — is computed by the server. The app only renders it.
class LiveExam {
  final String id;
  final String title;
  final String description;
  final String instructions;
  final String subject;
  final String std;
  final String board;
  final String medium;
  final int questionCount;
  final num totalMarks;
  final num passingMarks;
  final DateTime startAt;
  final DateTime endAt;
  final DateTime queueOpensAt;
  final int durationMinutes;

  /// SCHEDULED | QUEUE_OPEN | LIVE | COMPLETED | CANCELLED
  String status;

  /// UPCOMING | IN_QUEUE | LIVE | IN_PROGRESS | SUBMITTED | COMPLETED | EXPIRED | CANCELLED
  final String myState;
  int queueCount;
  int onlineCount;
  final bool inQueue;
  final bool canJoinQueue;
  final bool canLeaveQueue;
  final bool canStart;
  final bool canRetake;
  final int attemptsCount;
  final num? firstAttemptMarks;

  LiveExam({
    required this.id,
    required this.title,
    required this.description,
    required this.instructions,
    required this.subject,
    required this.std,
    required this.board,
    required this.medium,
    required this.questionCount,
    required this.totalMarks,
    required this.passingMarks,
    required this.startAt,
    required this.endAt,
    required this.queueOpensAt,
    required this.durationMinutes,
    required this.status,
    required this.myState,
    required this.queueCount,
    required this.onlineCount,
    required this.inQueue,
    required this.canJoinQueue,
    required this.canLeaveQueue,
    required this.canStart,
    required this.canRetake,
    required this.attemptsCount,
    required this.firstAttemptMarks,
  });

  static DateTime _date(dynamic v) =>
      DateTime.tryParse(v?.toString() ?? '')?.toLocal() ?? DateTime.now();

  static int _int(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

  factory LiveExam.fromJson(Map<String, dynamic> j) {
    final first = j['firstAttempt'];
    return LiveExam(
      id: j['_id'].toString(),
      title: j['title']?.toString() ?? '',
      description: j['description']?.toString() ?? '',
      instructions: j['instructions']?.toString() ?? '',
      subject: j['subject']?.toString() ?? '',
      std: j['std']?.toString() ?? '',
      board: j['board']?.toString() ?? '',
      medium: j['medium']?.toString() ?? '',
      questionCount: _int(j['questionCount']),
      totalMarks: (j['totalMarks'] as num?) ?? 0,
      passingMarks: (j['passingMarks'] as num?) ?? 0,
      startAt: _date(j['startAt']),
      endAt: _date(j['endAt']),
      queueOpensAt: _date(j['queueOpensAt']),
      durationMinutes: _int(j['durationMinutes']),
      status: j['status']?.toString() ?? 'SCHEDULED',
      myState: j['myState']?.toString() ?? 'UPCOMING',
      queueCount: _int(j['queueCount']),
      onlineCount: _int(j['onlineCount']),
      inQueue: j['inQueue'] == true,
      canJoinQueue: j['canJoinQueue'] == true,
      canLeaveQueue: j['canLeaveQueue'] == true,
      canStart: j['canStart'] == true,
      canRetake: j['canRetake'] == true,
      attemptsCount: _int(j['attemptsCount']),
      firstAttemptMarks: first is Map ? first['obtainedMarks'] as num? : null,
    );
  }

  /// Exam has finished for this student (nothing more to wait for).
  bool get isOver =>
      myState == 'COMPLETED' || myState == 'EXPIRED' || myState == 'CANCELLED';
}
