class OnboardingProfile {
  final String id;
  final String goal;
  final String? goalDetails;
  final String experience;
  final List<String> injuries;
  final String? injuryDetails;
  final String activityLevel;
  final String? desiredFrequency;
  final String? preferences;
  final bool canLieDown;
  final bool canKneel;
  final DateTime createdAt;

  OnboardingProfile({
    required this.id,
    required this.goal,
    this.goalDetails,
    required this.experience,
    required this.injuries,
    this.injuryDetails,
    required this.activityLevel,
    this.desiredFrequency,
    this.preferences,
    required this.canLieDown,
    required this.canKneel,
    required this.createdAt,
  });

  factory OnboardingProfile.fromJson(Map<String, dynamic> json) {
    return OnboardingProfile(
      id: json['id'],
      goal: json['goal'],
      goalDetails: json['goalDetails'],
      experience: json['experience'],
      injuries: (json['injuries'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      injuryDetails: json['injuryDetails'],
      activityLevel: json['activityLevel'],
      desiredFrequency: json['desiredFrequency'],
      preferences: json['preferences'],
      canLieDown: json['canLieDown'] ?? true, // Default safe assumption? Or explicit?
      canKneel: json['canKneel'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class CreateOnboardingDto {
  final String goal;
  final String? goalDetails;
  final String experience;
  final List<String> injuries;
  final String? injuryDetails;
  final String activityLevel;
  final String desiredFrequency;
  final String? preferences;
  final bool canLieDown;
  final bool canKneel;
  
  // User updates
  final String? birthDate; // YYYY-MM-DD
  final double? weight;
  final double? height;
  final String? phone;
  final String? gender;

  CreateOnboardingDto({
    required this.goal,
    this.goalDetails,
    required this.experience,
    required this.injuries,
    this.injuryDetails,
    required this.activityLevel,
    required this.desiredFrequency,
    this.preferences,
    required this.canLieDown,
    required this.canKneel,
    this.birthDate,
    this.weight,
    this.height,
    this.phone,
    this.gender,
  });

  Map<String, dynamic> toJson() {
    return {
      'goal': goal,
      'goalDetails': goalDetails,
      'experience': experience,
      'injuries': injuries,
      'injuryDetails': injuryDetails,
      'activityLevel': activityLevel,
      'desiredFrequency': desiredFrequency,
      'preferences': preferences,
      'canLieDown': canLieDown,
      'canKneel': canKneel,
      'birthDate': birthDate,
      'weight': weight,
      'height': height,
      'phone': phone,
      'gender': gender,
    };
  }
}
