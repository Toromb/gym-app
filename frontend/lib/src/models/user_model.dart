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
    };
  }
}
