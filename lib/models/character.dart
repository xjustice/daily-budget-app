class Character {
  final int level;
  final int xp;
  final int maxXP;
  final String status; // 'happy', 'sad', 'neutral'

  Character({
    required this.level,
    required this.xp,
    required this.maxXP,
    required this.status,
  });

  Character copyWith({
    int? level,
    int? xp,
    int? maxXP,
    String? status,
  }) {
    return Character(
      level: level ?? this.level,
      xp: xp ?? this.xp,
      maxXP: maxXP ?? this.maxXP,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'xp': xp,
      'maxXP': maxXP,
      'status': status,
    };
  }

  factory Character.fromMap(Map<String, dynamic> map) {
    return Character(
      level: map['level'] ?? 1,
      xp: map['xp'] ?? 0,
      maxXP: map['maxXP'] ?? 100,
      status: map['status'] ?? 'neutral',
    );
  }
}
