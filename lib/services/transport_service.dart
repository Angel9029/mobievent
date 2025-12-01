import 'package:flutter/foundation.dart';
import 'dart:math';

class TransportService extends ChangeNotifier {
  double baseFee = 20.0;
  double perKm = 2.0;
  // Default company base location (lat, lng). Admin can change.
  double baseLat = 4.710989; // example: Bogotá
  double baseLng = -74.072090;

  double estimateCost(double distanceKm) {
    if (distanceKm <= 0) return 0.0;
    return baseFee + (distanceKm * perKm);
  }

  void setPerKm(double rate) {
    perKm = rate;
    notifyListeners();
  }

  // Haversine distance in kilometers
  double distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Earth radius km
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) + cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRad(double deg) => deg * (pi / 180);

  void setBaseLocation(double lat, double lng) {
    baseLat = lat;
    baseLng = lng;
    notifyListeners();
  }

  void setBaseFee(double fee) {
    baseFee = fee;
    notifyListeners();
  }
}
