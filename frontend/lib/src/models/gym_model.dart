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
  
  // Payment Info
  final String? paymentAlias;
  final String? paymentCbu;
  final String? paymentAccountName;
  final String? paymentBankName;
  final String? paymentNotes;

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
    this.paymentAlias,
    this.paymentCbu,
    this.paymentAccountName,
    this.paymentBankName,
    this.paymentNotes,
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
      paymentAlias: json['paymentAlias'],
      paymentCbu: json['paymentCbu'],
      paymentAccountName: json['paymentAccountName'],
      paymentBankName: json['paymentBankName'],
      paymentNotes: json['paymentNotes'],
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
      'paymentAlias': paymentAlias,
      'paymentCbu': paymentCbu,
      'paymentAccountName': paymentAccountName,
      'paymentBankName': paymentBankName,
      'paymentNotes': paymentNotes,
    };
  }

  Gym copyWith({
    String? id,
    String? businessName,
    String? address,
    String? phone,
    String? email,
    String? status,
    int? maxProfiles,
    String? logoUrl,
    String? primaryColor,
    String? secondaryColor,
    String? welcomeMessage,
    String? openingHours,
    String? paymentAlias,
    String? paymentCbu,
    String? paymentAccountName,
    String? paymentBankName,
    String? paymentNotes,
  }) {
    return Gym(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      status: status ?? this.status,
      maxProfiles: maxProfiles ?? this.maxProfiles,
      logoUrl: logoUrl ?? this.logoUrl,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      welcomeMessage: welcomeMessage ?? this.welcomeMessage,
      openingHours: openingHours ?? this.openingHours,
      paymentAlias: paymentAlias ?? this.paymentAlias,
      paymentCbu: paymentCbu ?? this.paymentCbu,
      paymentAccountName: paymentAccountName ?? this.paymentAccountName,
      paymentBankName: paymentBankName ?? this.paymentBankName,
      paymentNotes: paymentNotes ?? this.paymentNotes,
    );
  }
}
