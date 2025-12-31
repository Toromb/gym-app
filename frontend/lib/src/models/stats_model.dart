
class PlatformStats {
  final int totalGyms;
  final int activeGyms;
  final int totalUsers;

  PlatformStats({
    required this.totalGyms,
    required this.activeGyms,
    required this.totalUsers,
  });

  factory PlatformStats.fromJson(Map<String, dynamic> json) {
    return PlatformStats(
      totalGyms: json['totalGyms'] ?? 0,
      activeGyms: json['activeGyms'] ?? 0,
      totalUsers: json['totalUsers'] ?? 0,
    );
  }
}

class MuscleLoad {
  final String muscleId;
  final String muscleName;
  final double load; // 0-100
  final String status; // RECOVERED, ACTIVE, FATIGUED, OVERLOADED
  final String lastComputedDate;

  MuscleLoad({
    required this.muscleId,
    required this.muscleName,
    required this.load,
    required this.status,
    required this.lastComputedDate,
  });

  factory MuscleLoad.fromJson(Map<String, dynamic> json) {
    return MuscleLoad(
      muscleId: json['muscleId'],
      muscleName: json['muscleName'],
      load: (json['load'] as num).toDouble(),
      status: json['status'],
      lastComputedDate: json['lastComputedDate'],
    );
  }
}
