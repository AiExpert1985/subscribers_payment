/// Represents a payment record.
///
/// Payments are immutable historical facts. The referenceAccountNumber field
/// does NOT have a foreign key constraint to the accounts table - mapping is
/// resolved dynamically at query time. This allows payments to remain intact
/// even when account/group mappings change.
class Payment {
  final int? id;
  final int referenceAccountNumber;
  final int paymentDate; // Unix timestamp
  final double amount; // REAL with 3 decimal precision
  final String? type;
  final String? collectorStamp;

  Payment({
    this.id,
    required this.referenceAccountNumber,
    required this.paymentDate,
    required this.amount,
    this.type,
    this.collectorStamp,
  });

  /// Creates a Payment from a database map
  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int?,
      referenceAccountNumber: map['reference_account_number'] as int,
      paymentDate: map['payment_date'] as int,
      amount: map['amount'] as double,
      type: map['type'] as String?,
      collectorStamp: map['collector_stamp'] as String?,
    );
  }

  /// Converts this Payment to a database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'reference_account_number': referenceAccountNumber,
      'payment_date': paymentDate,
      'amount': amount,
      if (type != null) 'type': type,
      if (collectorStamp != null) 'collector_stamp': collectorStamp,
    };
  }

  Payment copyWith({
    int? id,
    int? referenceAccountNumber,
    int? paymentDate,
    double? amount,
    String? type,
    String? collectorStamp,
  }) {
    return Payment(
      id: id ?? this.id,
      referenceAccountNumber:
          referenceAccountNumber ?? this.referenceAccountNumber,
      paymentDate: paymentDate ?? this.paymentDate,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      collectorStamp: collectorStamp ?? this.collectorStamp,
    );
  }

  @override
  String toString() =>
      'Payment(id: $id, referenceAccountNumber: $referenceAccountNumber, '
      'paymentDate: $paymentDate, amount: $amount, type: $type, '
      'collectorStamp: $collectorStamp)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Payment &&
        other.id == id &&
        other.referenceAccountNumber == referenceAccountNumber &&
        other.paymentDate == paymentDate &&
        other.amount == amount &&
        other.type == type &&
        other.collectorStamp == collectorStamp;
  }

  @override
  int get hashCode => Object.hash(
    id,
    referenceAccountNumber,
    paymentDate,
    amount,
    type,
    collectorStamp,
  );
}
