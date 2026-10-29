enum Mood {
  good('좋음', 'smile'),
  okay('보통', 'smile'),
  uncomfortable('불편', 'neutral'),
  bad('심함', 'frown'),
  veryBad('매우 심함', 'frown');

  const Mood(this.label, this.icon);

  final String label;

  final String icon;
}

enum Symptom {
  pain('통증'),
  stiffness('뻣뻣함'),
  swelling('붓기'),
  numbness('저림'),
  other('기타'),
  none('없음');

  const Symptom(this.label);

  final String label;
}

enum Activity {
  typing('타이핑'),
  chores('집안일'),
  exercise('운동'),
  other('기타');

  const Activity(this.label);

  final String label;
}

class JournalEntry {
  const JournalEntry({
    this.mood,
    this.symptoms = const {},
    this.activities = const {},
    this.memo = '',
  });

  final Mood? mood;
  final Set<Symptom> symptoms;
  final Set<Activity> activities;
  final String memo;

  static const empty = JournalEntry();

  Map<String, Object?> toJson() => {
    'mood': mood?.name,
    'symptoms': [for (final s in symptoms) s.name],
    'activities': [for (final a in activities) a.name],
    'memo': memo,
  };

  factory JournalEntry.fromJson(Map<String, Object?> json) {
    T? byName<T extends Enum>(List<T> values, Object? name) {
      for (final v in values) {
        if (v.name == name) return v;
      }
      return null;
    }

    List<Object?> list(Object? v) => v is List ? v : const [];

    return JournalEntry(
      mood: byName(Mood.values, json['mood']),
      symptoms: {
        for (final n in list(json['symptoms'])) ?byName(Symptom.values, n),
      },
      activities: {
        for (final n in list(json['activities'])) ?byName(Activity.values, n),
      },
      memo: json['memo'] is String ? json['memo'] as String : '',
    );
  }
}
