/// Represents an account belonging to a subscriber group.
///
/// Account numbers are unique globally across all subscriber groups.
/// Each account belongs to exactly one subscriber group.
class Account {
  final int? id;
  final int accountNumber;
  final int subscriberGroupId;

  Account({
    this.id,
    required this.accountNumber,
    required this.subscriberGroupId,
  });

  /// Creates an Account from a database map
  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as int?,
      accountNumber: map['account_number'] as int,
      subscriberGroupId: map['subscriber_group_id'] as int,
    );
  }

  /// Converts this Account to a database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'account_number': accountNumber,
      'subscriber_group_id': subscriberGroupId,
    };
  }

  Account copyWith({int? id, int? accountNumber, int? subscriberGroupId}) {
    return Account(
      id: id ?? this.id,
      accountNumber: accountNumber ?? this.accountNumber,
      subscriberGroupId: subscriberGroupId ?? this.subscriberGroupId,
    );
  }

  @override
  String toString() =>
      'Account(id: $id, accountNumber: $accountNumber, subscriberGroupId: $subscriberGroupId)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Account &&
        other.id == id &&
        other.accountNumber == accountNumber &&
        other.subscriberGroupId == subscriberGroupId;
  }

  @override
  int get hashCode => Object.hash(id, accountNumber, subscriberGroupId);
}
