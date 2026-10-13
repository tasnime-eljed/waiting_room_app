class Client {
  final String id;
  final String name;
  final DateTime createdAt;

  Client({required this.id, required this.name, required this.createdAt});

  // Supabase -> Dart : transforme une Map en objet Client
  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Dart -> Map : transforme un objet Client en Map
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'created_at': createdAt.toIso8601String()};
  }

  @override
  String toString() => 'Client(id: $id, name: $name, created_at: $createdAt)';
}
