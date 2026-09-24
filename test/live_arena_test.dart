import 'package:dm_bhatt_tutions/model/live_exam.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/live_arena/live_arena_widgets.dart';
import 'package:dm_bhatt_tutions/utils/live_arena_service.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json(String myState, {bool canJoinQueue = false}) => {
      '_id': 'e1',
      'title': 'Science Challenge',
      'subject': 'Science',
      'std': '10',
      'board': 'GSEB',
      'medium': 'English',
      'questionCount': 10,
      'totalMarks': 100,
      'passingMarks': 35,
      'startAt': '2026-09-25T13:30:00.000Z',
      'endAt': '2026-09-25T14:00:00.000Z',
      'queueOpensAt': '2026-09-25T13:00:00.000Z',
      'durationMinutes': 30,
      'status': 'SCHEDULED',
      'myState': myState,
      'queueCount': 124,
      'onlineCount': 87,
      'inQueue': myState == 'IN_QUEUE',
      'canJoinQueue': canJoinQueue,
      'firstAttempt': myState == 'COMPLETED' ? {'obtainedMarks': 72, 'totalMarks': 100} : null,
    };

void main() {
  test('parses the server payload', () {
    final e = LiveExam.fromJson(_json('COMPLETED'));
    expect(e.id, 'e1');
    expect(e.queueCount, 124);
    expect(e.onlineCount, 87);
    expect(e.totalMarks, 100);
    expect(e.firstAttemptMarks, 72);
    expect(e.startAt.isUtc, isFalse); // shown in the phone's local time
    expect(e.isOver, isTrue);
  });

  test('each card state offers only its correct action', () {
    ({LiveAction action, String label}) of(String s, {bool join = false}) =>
        primaryActionFor(LiveExam.fromJson(_json(s, canJoinQueue: join)));

    expect(of('UPCOMING', join: true).action, LiveAction.joinQueue);
    expect(of('UPCOMING').action, LiveAction.none); // queue not open yet
    expect(of('IN_QUEUE').label, 'IN QUEUE');
    expect(of('IN_QUEUE').action, LiveAction.none);
    expect(of('LIVE').action, LiveAction.enter);
    expect(of('IN_PROGRESS').action, LiveAction.resume);
    expect(of('SUBMITTED').action, LiveAction.viewResult);
    expect(of('COMPLETED').action, LiveAction.viewResult);
    expect(of('EXPIRED').action, LiveAction.none);
    expect(of('CANCELLED').action, LiveAction.none);
  });

  test('countdown aligns to server time and never goes negative', () {
    LiveArenaClock.sync(DateTime.now().toUtc().toIso8601String());
    final target = LiveArenaClock.now().add(const Duration(hours: 1, minutes: 2, seconds: 3));
    expect(LiveArenaClock.countdown(target), anyOf('01:02:03', '01:02:02'));
    expect(LiveArenaClock.countdown(DateTime(2000)), '00:00:00');
  });

  test('time taken is shown as mm:ss', () {
    expect(formatTimeTaken(18 * 60000 + 42000), '18:42');
    expect(formatTimeTaken(null), '--:--');
    expect(formatMarks(82), '82');
    expect(formatMarks(82.5), '82.5');
  });
}
