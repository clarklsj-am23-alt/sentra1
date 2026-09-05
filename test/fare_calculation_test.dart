import 'package:flutter_test/flutter_test.dart';
import 'package:sentra1/features/transit_card/services/fare_calculation_service.dart';

void main() {
  group('FareCalculationService Tests', () {
    test('Zero hops returns 0.00', () {
      final fare = FareCalculationService.calculateFare(
        stationHops: 0,
        cardType: 'Standard Adult',
      );
      expect(fare, 0.0);
    });

    test('Tier 1 (1-3 hops) standard fare calculation', () {
      // Base: 1.20 + (2 * 0.30) = 1.80
      final fare = FareCalculationService.calculateFare(
        stationHops: 2,
        cardType: 'Standard Adult',
      );
      expect(fare, 1.80);
    });

    test('Tier 2 (4-8 hops) standard fare calculation', () {
      // Base: 1.20 + (3 * 0.30) + (2 * 0.25) = 1.20 + 0.90 + 0.50 = 2.60
      final fare = FareCalculationService.calculateFare(
        stationHops: 5,
        cardType: 'Standard Adult',
      );
      expect(fare, 2.60);
    });

    test('Concession applies 50% discount for OKU', () {
      // 5 hops = RM 2.60 -> 50% = RM 1.30
      final fare = FareCalculationService.calculateFare(
        stationHops: 5,
        cardType: 'OKU Concession',
      );
      expect(fare, 1.30);
    });

    test('Concession applies 50% discount for Student', () {
      final fare = FareCalculationService.calculateFare(
        stationHops: 2,
        cardType: 'Student',
      );
      expect(fare, 0.90);
    });
  });
}
