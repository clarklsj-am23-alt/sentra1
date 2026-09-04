class FareCalculationService {
  /// Computes transit fare based on station stops and card concession type.
  static double calculateFare({
    required int stationHops,
    required String cardType,
  }) {
    if (stationHops <= 0) return 0.0;

    // Standard Rapid KL Tiered Base Fare Formula
    double baseFare = 1.20;
    if (stationHops <= 3) {
      baseFare += (stationHops * 0.30);
    } else if (stationHops <= 8) {
      baseFare += (3 * 0.30) + ((stationHops - 3) * 0.25);
    } else {
      baseFare += (3 * 0.30) + (5 * 0.25) + ((stationHops - 8) * 0.18);
    }

    // Apply Concession Discounts
    if (cardType == 'OKU Concession' || cardType == 'Student') {
      return baseFare * 0.50; // 50% concession discount
    }

    return baseFare;
  }
}