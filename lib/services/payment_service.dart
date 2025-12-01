import 'dart:async';
import 'package:flutter/foundation.dart';

class PaymentService extends ChangeNotifier {
  bool depositPaid = false;
  bool contractSigned = false;
  double lastAmount = 0.0;

  Future<bool> payDeposit(double amount) async {
    // Simulate network/payment delay
    await Future.delayed(const Duration(seconds: 1));
    depositPaid = true;
    lastAmount = amount;
    notifyListeners();
    return true;
  }

  void signContract() {
    contractSigned = true;
    notifyListeners();
  }

  void reset() {
    depositPaid = false;
    contractSigned = false;
    lastAmount = 0.0;
    notifyListeners();
  }
}
