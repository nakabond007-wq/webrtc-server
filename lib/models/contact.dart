class Contact {
  final String id;
  final String name;
  final DateTime addedAt;

  Contact({
    required this.id,
    required this.name,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'addedAt': addedAt.toIso8601String(),
  };

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
    id: json['id'] as String,
    name: json['name'] as String,
    addedAt: DateTime.parse(json['addedAt'] as String),
  );
}
