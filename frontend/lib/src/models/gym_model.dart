class Gym {
  final String id;
  final String businessName;
  final String address;
  final String? phone;
  final String? email;
  final String status;
  final int maxProfiles;
  
  // Customization
  final String? logoUrl;
  final String? primaryColor;
  final String? secondaryColor;
  final String? welcomeMessage;
  final String? openingHours;

  Gym({
    required this.id,
    required this.businessName,
    required this.address,
    this.phone,
    this.email,
    required this.status,
    required this.maxProfiles,
    this.logoUrl,
    this.primaryColor,
    this.secondaryColor,
    this.welcomeMessage,
    this.openingHours,
  });

  factory Gym.fromJson(Map<String, dynamic> json) {
    return Gym(
      id: json['id'],
      businessName: json['businessName'],
      address: json['address'],
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      status: json['status'] ?? 'active',
      maxProfiles: json['maxProfiles'] ?? 0,
      logoUrl: json['logoUrl'],
      primaryColor: json['primaryColor'],
      secondaryColor: json['secondaryColor'],
      welcomeMessage: json['welcomeMessage'],
      openingHours: json['openingHours'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessName': businessName,
      'address': address,
      'phone': phone,
      'email': email,
      'status': status,
      'maxProfiles': maxProfiles,
      'logoUrl': logoUrl,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'welcomeMessage': welcomeMessage,
      'openingHours': openingHours,
    };
  }
}
