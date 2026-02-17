/// Represents a payment record.
///
/// Payments are immutable historical facts. The referenceAccountNumber field
/// does NOT have a foreign key constraint to the accounts table - mapping is
/// resolved dynamically at query time. This allows payments to remain intact
/// even when account/group mappings change.
///
/// subscriberName is stored as-is from the import source (standalone, not
/// resolved from subscriber_groups).
class Payment {
  final int? id;
  final int referenceAccountNumber;
  final int paymentDate; // Unix timestamp
  final double amount; // REAL with 3 decimal precision
  final String? subscriberName;
  final String? type;
  final String? stampNumber;

  Payment({
    this.id,
    required this.referenceAccountNumber,
    required this.paymentDate,
    required this.amount,
    this.subscriberName,
    this.type,
    this.stampNumber,
  });

  /// Creates a Payment from a database map
  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int?,
      referenceAccountNumber: map['reference_account_number'] as int,
      paymentDate: map['payment_date'] as int,
      amount: (map['amount'] as num).toDouble(),
      subscriberName: map['subscriber_name'] as String?,
      type: map['type'] as String?,
      stampNumber: map['stamp_number'] as String?,
    );
  }

  /// Converts this Payment to a database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'reference_account_number': referenceAccountNumber,
      'payment_date': paymentDate,
      'amount': amount,
      if (subscriberName != null) 'subscriber_name': subscriberName,
      if (type != null) 'type': type,
      if (stampNumber != null) 'stamp_number': stampNumber,
    };
  }

  Payment copyWith({
    int? id,
    int? referenceAccountNumber,
    int? paymentDate,
    double? amount,
    String? subscriberName,
    String? type,
    String? stampNumber,
  }) {
    return Payment(
      id: id ?? this.id,
      referenceAccountNumber:
          referenceAccountNumber ?? this.referenceAccountNumber,
      paymentDate: paymentDate ?? this.paymentDate,
      amount: amount ?? this.amount,
      subscriberName: subscriberName ?? this.subscriberName,
      type: type ?? this.type,
      stampNumber: stampNumber ?? this.stampNumber,
    );
  }

  @override
  String toString() =>
      'Payment(id: $id, referenceAccountNumber: $referenceAccountNumber, '
      'paymentDate: $paymentDate, amount: $amount, '
      'subscriberName: $subscriberName, type: $type, '
      'stampNumber: $stampNumber)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Payment &&
        other.id == id &&
        other.referenceAccountNumber == referenceAccountNumber &&
        other.paymentDate == paymentDate &&
        other.amount == amount &&
        other.subscriberName == subscriberName &&
        other.type == type &&
        other.stampNumber == stampNumber;
  }

  @override
  int get hashCode => Object.hash(
    id,
    referenceAccountNumber,
    paymentDate,
    amount,
    subscriberName,
    type,
    stampNumber,
  );
}
