
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
