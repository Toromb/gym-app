
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

class UserProgress {
  final WeightStats weight;
  final VolumeStats volume;
  final WorkoutStats workouts;
  final LevelStats level;

  UserProgress({
    required this.weight,
    required this.volume,
    required this.workouts,
    required this.level,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      weight: WeightStats.fromJson(json['weight'] ?? {}),
      volume: VolumeStats.fromJson(json['volume'] ?? {}),
      workouts: WorkoutStats.fromJson(json['workouts'] ?? {}),
      level: LevelStats.fromJson(json['level'] ?? {}),
    );
  }
}

class WeightStats {
  final double initial;
  final double current;
  final double change;

  WeightStats({
    required this.initial,
    required this.current,
    required this.change,
  });

  factory WeightStats.fromJson(Map<String, dynamic> json) {
    return WeightStats(
      initial: (json['initial'] as num?)?.toDouble() ?? 0.0,
      current: (json['current'] as num?)?.toDouble() ?? 0.0,
      change: (json['change'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class VolumeStats {
  final double lifetime;
  final double thisWeek;
  final double thisMonth;
  final List<VolumePoint> chart;

  VolumeStats({
    required this.lifetime,
    required this.thisWeek,
    required this.thisMonth,
    required this.chart,
  });

  factory VolumeStats.fromJson(Map<String, dynamic> json) {
    return VolumeStats(
      lifetime: (json['lifetime'] as num?)?.toDouble() ?? 0.0,
      thisWeek: (json['thisWeek'] as num?)?.toDouble() ?? 0.0,
      thisMonth: (json['thisMonth'] as num?)?.toDouble() ?? 0.0,
      chart: (json['chart'] as List?)
          ?.map((e) => VolumePoint.fromJson(e))
          .toList() ?? [],
    );
  }
}

class VolumePoint {
  final String date;
  final double volume;

  VolumePoint({required this.date, required this.volume});

  factory VolumePoint.fromJson(Map<String, dynamic> json) {
    return VolumePoint(
      date: json['date'] ?? '',
      volume: (json['volume'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class WorkoutStats {
  final int total;
  final int thisMonth;
  final int thisWeek;
  final double weeklyAverage;

  WorkoutStats({
    required this.total, 
    required this.thisMonth, 
    required this.thisWeek,
    required this.weeklyAverage,
  });

  factory WorkoutStats.fromJson(Map<String, dynamic> json) {
    return WorkoutStats(
      total: json['total'] ?? 0,
      thisMonth: json['thisMonth'] ?? 0,
      thisWeek: json['thisWeek'] ?? 0,
      weeklyAverage: (json['weeklyAverage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class LevelStats {
  final int current; // Level 1-100+
  final int exp;     // Total Accumulated EXP

  LevelStats({
    required this.current,
    required this.exp,
  });

  factory LevelStats.fromJson(Map<String, dynamic> json) {
    return LevelStats(
      current: json['current'] ?? 1,
      exp: json['exp'] ?? 0,
    );
  }
}
