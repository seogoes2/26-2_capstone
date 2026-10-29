enum AlertKind {
  overuse('warning'),
  wear('wear'),
  goal('check');

  const AlertKind(this.icon);

  final String icon;
}

class AppAlert {
  const AppAlert({
    required this.kind,
    required this.title,
    this.message,
    required this.detail,
    required this.time,
  });

  factory AppAlert.overuse({
    required int count,
    required int limitAngle,
    required int maxOver,
    required DateTime time,
  }) => AppAlert(
    kind: AlertKind.overuse,
    title: '손 사용을 잠시 쉬어주세요',
    message: '최근 1시간 동안 과굴곡 $count회',
    detail: '설정 각도 $limitAngle°보다 최대 $maxOver° 초과',
    time: time,
  );

  factory AppAlert.wear({required int hours, required DateTime time}) =>
      AppAlert(
        kind: AlertKind.wear,
        title: '보조기 착용을 잊지 마세요',
        detail: '$hours시간 동안 착용 기록이 없어요.',
        time: time,
      );

  factory AppAlert.goal({required Duration left, required DateTime time}) {
    final h = left.inHours;
    final m = left.inMinutes.remainder(60);
    final rest = [if (h > 0) '$h시간', if (m > 0 || h == 0) '$m분'].join(' ');
    return AppAlert(
      kind: AlertKind.goal,
      title: '오늘 목표까지 $rest',
      detail: '착용 목표에 가까워졌어요.',
      time: time,
    );
  }

  final AlertKind kind;
  final String title;
  final String? message;
  final String detail;
  final DateTime time;

  String timeLabel(DateTime now) {
    final hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final clock =
        '${time.hour < 12 ? '오전' : '오후'} $hour12:${time.minute.toString().padLeft(2, '0')}';
    final day = DateTime(time.year, time.month, time.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return clock;
    if (diff == 1) return '어제 $clock';
    return '${time.month}월 ${time.day}일 $clock';
  }

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'title': title,
    'message': message,
    'detail': detail,
    'time': time.toIso8601String(),
  };

  static AppAlert? fromJson(Object? json) {
    if (json is! Map) return null;
    final kind = AlertKind.values
        .where((k) => k.name == json['kind'])
        .firstOrNull;
    final time = DateTime.tryParse('${json['time']}');
    final title = json['title'];
    final detail = json['detail'];
    if (kind == null || time == null || title is! String || detail is! String) {
      return null;
    }
    final message = json['message'];
    return AppAlert(
      kind: kind,
      title: title,
      message: message is String ? message : null,
      detail: detail,
      time: time,
    );
  }
}
