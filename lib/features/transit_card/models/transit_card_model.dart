class TransitCard {
  final int? id;
  final String cardName;
  final String cardNumber;
  final double balance;
  final String cardType;

  TransitCard({
    this.id,
    required this.cardName,
    required this.cardNumber,
    required this.balance,
    required this.cardType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'card_name': cardName,
      'card_number': cardNumber,
      'balance': balance,
      'card_type': cardType,
    };
  }

  factory TransitCard.fromMap(Map<String, dynamic> map) {
    return TransitCard(
      id: map['id'] as int?,
      cardName: map['card_name'] as String,
      cardNumber: map['card_number'] as String,
      balance: (map['balance'] as num).toDouble(),
      cardType: map['card_type'] as String,
    );
  }
}