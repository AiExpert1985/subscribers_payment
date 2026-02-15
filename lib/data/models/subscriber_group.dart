/// Represents a group of subscriber accounts.
///
/// A subscriber group contains related account numbers that belong to
/// the same subscriber/customer.
class SubscriberGroup {
  final int? id;
  final String name;

  SubscriberGroup({this.id, required this.name});

  /// Creates a SubscriberGroup from a database map
  factory SubscriberGroup.fromMap(Map<String, dynamic> map) {
    return SubscriberGroup(id: map['id'] as int?, name: map['name'] as String);
  }

  /// Converts this SubscriberGroup to a database map
  Map<String, dynamic> toMap() {
    return {if (id != null) 'id': id, 'name': name};
  }

  SubscriberGroup copyWith({int? id, String? name}) {
    return SubscriberGroup(id: id ?? this.id, name: name ?? this.name);
  }

  @override
  String toString() => 'SubscriberGroup(id: $id, name: $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubscriberGroup && other.id == id && other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, name);
}
