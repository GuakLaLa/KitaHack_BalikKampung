class HotlineArea {
  final String id;
  final String state;
  final String? district;
  final List<String> phones;
  final String level;

  HotlineArea({
    required this.id,
    required this.state,
    this.district,
    required this.phones,
    required this.level,
  });

  factory HotlineArea.fromFirestore(String id, Map<String, dynamic> data) {
    return HotlineArea(
      id: id,
      state: data['state'] ?? '',
      district: data['district'],
      phones: List<String>.from(data['phones'] ?? []),
      level: data['level'] ?? 'state',
    );
  }
}