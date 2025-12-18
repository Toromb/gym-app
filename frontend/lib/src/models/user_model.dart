class UserRoles {
  static const String superAdmin = 'super_admin';
  static const String admin = 'admin';
  static const String profe = 'profe';
  static const String alumno = 'alumno';
}

class User {
  final String id;
  final String email;
  final String role;
  final String firstName;
  final String lastName;
  final String? phone;
  final int? age;
  final String? gender;
  final String? notes;
  final String? paymentStatus;
  final String? lastPaymentDate;
  final double? height;

  // Student Specific
  final String? trainingGoal;
  final String? professorObservations;
  final double? initialWeight;
  final double? currentWeight;
  final String? weightUpdateDate;
  final String? personalComment;
  final bool? isActive;
  final String? membershipStartDate;
  final String? membershipExpirationDate;

  // Professor Specific
  final String? specialty;
  final String? internalNotes;

  // Admin Specific
  final String? adminNotes;
  
  // Gym Info
  final String? gymName;
  
  // Professor Info (for students)
  final String? professorId;
  final String? professorName;

  User({
    required this.id,
    required this.email,
    required this.role,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.age,
    this.gender,
    this.notes,
    this.paymentStatus,
    this.lastPaymentDate,
    this.height,
    this.trainingGoal,
    this.professorObservations,
    this.initialWeight,
    this.currentWeight,
    this.weightUpdateDate,
    this.personalComment,
    this.isActive,
    this.membershipStartDate,
    this.membershipExpirationDate,
    this.specialty,
    this.internalNotes,
    this.adminNotes,
    this.gymName,
    this.professorId,
    this.professorName,
  });

  String get name => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      role: json['role'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phone: json['phone'],
      age: json['age'],
      gender: json['gender'],
      notes: json['notes'],
      paymentStatus: json['paymentStatus'],
      lastPaymentDate: json['lastPaymentDate'],
      height: json['height'] != null ? (json['height'] as num).toDouble() : null,
      trainingGoal: json['trainingGoal'],
      professorObservations: json['professorObservations'],
      initialWeight: json['initialWeight'] != null ? (json['initialWeight'] as num).toDouble() : null,
      currentWeight: json['currentWeight'] != null ? (json['currentWeight'] as num).toDouble() : null,
      weightUpdateDate: json['weightUpdateDate'],
      personalComment: json['personalComment'],
      isActive: json['isActive'],
      membershipStartDate: json['membershipStartDate'],
      membershipExpirationDate: json['membershipExpirationDate'],
      specialty: json['specialty'],
      internalNotes: json['internalNotes'],
      adminNotes: json['adminNotes'],
      gymName: json['gym'] != null ? json['gym']['businessName'] : null,
      professorId: json['professor'] != null ? json['professor']['id'] : null,
      professorName: json['professor'] != null ? "${json['professor']['firstName']} ${json['professor']['lastName']}" : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'age': age,
      'gender': gender,
      'notes': notes,
      'paymentStatus': paymentStatus,
      'lastPaymentDate': lastPaymentDate,
      'height': height,
      'trainingGoal': trainingGoal,
      'professorObservations': professorObservations,
      'initialWeight': initialWeight,
      'currentWeight': currentWeight,
      'weightUpdateDate': weightUpdateDate,
      'personalComment': personalComment,
      'isActive': isActive,
      'membershipStartDate': membershipStartDate,
      'membershipExpirationDate': membershipExpirationDate,
      'specialty': specialty,
      'internalNotes': internalNotes,
      'adminNotes': adminNotes,
    };
  }
}
