import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/reservation.dart';
import '../models/item.dart';
import 'inventory_service.dart';
import 'transport_service.dart';
import 'payment_service.dart';

class CartEntry {
  final String id;
  final Item item;
  final int qty;
  final DateTime start;
  final DateTime end;
  final bool pickup; // true = user picks up
  final double? destDistanceKm;

  CartEntry({
    required this.id,
    required this.item,
    required this.qty,
    required this.start,
    required this.end,
    this.pickup = true,
    this.destDistanceKm,
  });

  int days() => end.difference(start).inDays + 1;
}

class CartService extends ChangeNotifier {
  final List<CartEntry> _entries = [];

  List<CartEntry> get entries => List.unmodifiable(_entries);

  void add(Item item, int qty, DateTime start, DateTime end, {bool pickup = true, double? distanceKm}) {
    final entry = CartEntry(id: const Uuid().v4(), item: item, qty: qty, start: start, end: end, pickup: pickup, destDistanceKm: distanceKm);
    _entries.add(entry);
    notifyListeners();
  }

  void remove(String id) {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void clear() {
    _entries.clear();
    notifyListeners();
  }

  /// Apply a saved destination distance to all entries that are marked as delivery (pickup == false).
  /// This replaces entries in-place with new CartEntry instances carrying the destination distance.
  void applySavedLocationToDeliveries({double? distanceKm}) {
    for (var i = 0; i < _entries.length; i++) {
      final e = _entries[i];
      if (!e.pickup) {
        _entries[i] = CartEntry(
          id: e.id,
          item: e.item,
          qty: e.qty,
          start: e.start,
          end: e.end,
          pickup: false,
          destDistanceKm: distanceKm ?? e.destDistanceKm,
        );
      }
    }
    notifyListeners();
  }

  double subtotal() {
    double s = 0;
    for (final e in _entries) {
      s += e.item.total * 0; // placeholder, price should come from InventoryService
    }
    return s;
  }

  // Checkout: try to reserve each entry, simulate payment and return results
  Future<List<Reservation?>> checkout(String userId, InventoryService inv, TransportService transport, PaymentService pay) async {
    final results = <Reservation?>[];
    for (final e in List<CartEntry>.from(_entries)) {
      // check availability
      final avail = inv.availableForRange(e.item, e.start, e.end);
      if (avail < e.qty) {
        results.add(null);
        continue;
      }
      // estimate transport cost if delivery
      double transportCost = 0.0;
      if (!e.pickup && e.destDistanceKm != null) {
        transportCost = transport.estimateCost(e.destDistanceKm!);
      }
      // simulate payment of deposit = price per day * days * qty * 0.2 + transportCost*0.5
      final days = e.days();
      final pricePerDay = e.item.pricePerDay > 0.0 ? e.item.pricePerDay : (inv.typeRates[e.item.type] ?? 0.0);
      final amount = (pricePerDay * days * e.qty) * 0.2 + transportCost * 0.5;
      final paid = await pay.payDeposit(amount);
      if (!paid) {
        results.add(null);
        continue;
      }
      final r = inv.reserveForUser(userId, e.item, e.start, e.end, e.qty, pickup: e.pickup, destDistanceKm: e.destDistanceKm);
      results.add(r);
    }
    // remove successful ones from cart
    clear();
    return results;
  }
}
