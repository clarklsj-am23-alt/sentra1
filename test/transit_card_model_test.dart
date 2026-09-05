import 'package:flutter_test/flutter_test.dart';
import 'package:sentra1/features/transit_card/models/transit_card_model.dart';

void main() {
  group('TransitCard Model Tests', () {
    test('toMap converts TransitCard correctly', () {
      final card = TransitCard(
        id: 1,
        cardName: 'My Concession',
        cardNumber: '1234 5678',
        balance: 25.50,
        cardType: 'OKU Concession',
      );

      final map = card.toMap();

      expect(map['id'], 1);
      expect(map['card_name'], 'My Concession');
      expect(map['card_number'], '1234 5678');
      expect(map['balance'], 25.50);
      expect(map['card_type'], 'OKU Concession');
    });

    test('fromMap instantiates TransitCard correctly', () {
      final map = {
        'id': 2,
        'card_name': 'Standard Card',
        'card_number': '9876 5432',
        'balance': 10.0,
        'card_type': 'Standard Adult',
      };

      final card = TransitCard.fromMap(map);

      expect(card.id, 2);
      expect(card.cardName, 'Standard Card');
      expect(card.balance, 10.0);
      expect(card.cardType, 'Standard Adult');
    });
  });
}
