class GymSchedule {
  final int id;
  final String dayOfWeek;
  bool isClosed;
  String? openTimeMorning;
  String? closeTimeMorning;
  String? openTimeAfternoon;
  String? closeTimeAfternoon;
  String? notes;

  GymSchedule({
    required this.id,
    required this.dayOfWeek,
    required this.isClosed,
    this.openTimeMorning,
    this.closeTimeMorning,
    this.openTimeAfternoon,
    this.closeTimeAfternoon,
    this.notes,
  });

  factory GymSchedule.fromJson(Map<String, dynamic> json) {
    return GymSchedule(
      id: json['id'],
      dayOfWeek: json['dayOfWeek'],
      isClosed: json['isClosed'],
      openTimeMorning: json['openTimeMorning'],
      closeTimeMorning: json['closeTimeMorning'],
      openTimeAfternoon: json['openTimeAfternoon'],
      closeTimeAfternoon: json['closeTimeAfternoon'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dayOfWeek': dayOfWeek,
      'isClosed': isClosed,
      'openTimeMorning': openTimeMorning,
      'closeTimeMorning': closeTimeMorning,
      'openTimeAfternoon': openTimeAfternoon,
      'closeTimeAfternoon': closeTimeAfternoon,
      'notes': notes,
    };
  }

  // Helper for UI
  String get rangeMorning => (openTimeMorning != null && closeTimeMorning != null) 
      ? '$openTimeMorning - $closeTimeMorning' : '';
  
  String get rangeAfternoon => (openTimeAfternoon != null && closeTimeAfternoon != null)
      ? '$openTimeAfternoon - $closeTimeAfternoon' : '';
      
  String get displayHours {
      if (isClosed) return 'Closed';
      List<String> parts = [];
      if (rangeMorning.isNotEmpty) parts.add(rangeMorning);
      if (rangeAfternoon.isNotEmpty) parts.add(rangeAfternoon);
      return parts.isEmpty ? 'Closed' : parts.join(' / ');
  }
}
