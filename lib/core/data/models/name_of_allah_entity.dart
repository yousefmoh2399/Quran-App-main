class NameOfAllahEntity {
  final int id;
  final String name;
  final String text;

  const NameOfAllahEntity({
    required this.id,
    required this.name,
    required this.text,
  });

  factory NameOfAllahEntity.fromMap(Map<String, dynamic> map) {
    return NameOfAllahEntity(
      id: map['id'] as int,
      name: map['name'] as String,
      text: map['text'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'text': text,
    };
  }
}
