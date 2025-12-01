import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item.dart';
import '../models/reservation.dart';
import 'package:uuid/uuid.dart';

/// Firestore-backed inventory service.
/// Listens to `/items` and `/reservations` collections and exposes helper methods.

class InventoryService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Item> _items = [];
  final List<Reservation> _reservations = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _itemsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _resSub;

  Map<String, double> typeRates = {
    'mesa': 10.0,
    'silla': 2.0,
    'escenario': 150.0,
    'decor': 30.0,
  };

  List<Item> get items => List.unmodifiable(_items);
  List<Reservation> get reservations => List.unmodifiable(_reservations);

  InventoryService() {
    _listenItems();
    _listenReservations();
  }

  void dispose() {
    _itemsSub?.cancel();
    _resSub?.cancel();
    super.dispose();
  }

  Item? findById(String id) {
    try {
      return _items.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  void _listenItems() {
    _itemsSub = _firestore.collection('items').snapshots().listen((snap) {
      _items.clear();
      for (final doc in snap.docs) {
        final data = doc.data();
        final it = Item(
          id: doc.id,
          name: data['name'] ?? '',
          type: data['type'] ?? 'other',
          total: (data['total'] ?? 0) as int,
          imageBase64: data['imageBase64'] as String?,
          pricePerDay: (data['pricePerDay'] as num?)?.toDouble() ?? (typeRates[data['type']] ?? 0.0),
          unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0.0,
        );
        // load reservations map if present
        final Map<String, dynamic>? resMap = (data['reservations'] as Map<String, dynamic>?) ?? null;
        if (resMap != null) {
          resMap.forEach((k, v) {
            try {
              it.reservations[k] = (v as num).toInt();
            } catch (_) {}
          });
        }
        _items.add(it);
      }
      notifyListeners();
    });
  }

  void _listenReservations() {
    _resSub = _firestore.collection('reservations').snapshots().listen((snap) {
      _reservations.clear();
      for (final doc in snap.docs) {
        final d = doc.data();
        try {
          final r = Reservation(
            id: doc.id,
            userId: d['userId'] ?? '',
            itemId: d['itemId'] ?? '',
            qty: (d['qty'] ?? 0) as int,
            start: (d['start'] as Timestamp).toDate(),
            end: (d['end'] as Timestamp).toDate(),
            status: d['status'] ?? 'active',
            createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
            daysCount: (d['days'] as num?)?.toInt(),
            pricePerDay: (d['pricePerDay'] as num?)?.toDouble(),
            totalPrice: (d['totalPrice'] as num?)?.toDouble(),
            distanceKm: (d['distanceKm'] as num?)?.toDouble(),
            pickup: d['pickup'] as bool?,
          );
          _reservations.add(r);
        } catch (_) {}
      }
      notifyListeners();
    });
  }

  // Check available quantity for an item across a date range
  int availableForRange(Item item, DateTime start, DateTime end) {
    final total = item.total;
    // compute max reserved for any day in range using local _reservations
    int maxReserved = 0;
    for (var d = DateTime(start.year, start.month, start.day);
        !d.isAfter(DateTime(end.year, end.month, end.day));
        d = d.add(const Duration(days: 1))) {
      int reserved = 0;
      for (final r in _reservations) {
        if (r.itemId == item.id && r.status == 'active' && r.overlaps(d, d)) {
          reserved += r.qty;
        }
      }
      if (reserved > maxReserved) maxReserved = reserved;
    }
    return (total - maxReserved).clamp(0, total);
  }

  // Reserve item across date range if available
  Reservation? reserveForUser(String userId, Item item, DateTime start, DateTime end, int qty, {bool pickup = true, double? destLat, double? destLng, double? destDistanceKm}) {
    final avail = availableForRange(item, start, end);
    if (avail < qty) return null;
    final id = const Uuid().v4();
    final days = end.difference(start).inDays + 1;
    final pricePerDay = (item.pricePerDay > 0.0) ? item.pricePerDay : (typeRates[item.type] ?? 0.0);
    final totalPrice = pricePerDay * days * qty;
    final r = Reservation(
      id: id,
      userId: userId,
      itemId: item.id,
      qty: qty,
      start: start,
      end: end,
      daysCount: days,
      pricePerDay: pricePerDay,
      totalPrice: totalPrice,
      distanceKm: destDistanceKm,
      pickup: pickup,
    );

    // Create reservation document in Firestore
    final docRef = _firestore.collection('reservations').doc(id);
    final payload = {
      'userId': userId,
      'itemId': item.id,
      'qty': qty,
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'days': days,
      'pricePerDay': pricePerDay,
      'totalPrice': totalPrice,
      'status': 'active',
      'pickup': pickup,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (destLat != null && destLng != null) {
      payload['destLat'] = destLat;
      payload['destLng'] = destLng;
    }
    if (destDistanceKm != null) {
      payload['distanceKm'] = destDistanceKm;
    }
    docRef.set(payload);

    // update local cache optimistically
    _reservations.add(r);
    for (var d = DateTime(start.year, start.month, start.day);
        !d.isAfter(DateTime(end.year, end.month, end.day));
        d = d.add(const Duration(days: 1))) {
      final key = item.keyFor(d);
      item.reservations[key] = (item.reservations[key] ?? 0) + qty;
    }
    notifyListeners();
    return r;
  }

  void cancelReservation(String reservationId) {
    final r = _reservations.firstWhere((x) => x.id == reservationId, orElse: () => throw Exception('Not found'));
    if (r.status != 'active') return;
    r.status = 'cancelled';

    // Update Firestore
    _firestore.collection('reservations').doc(reservationId).update({'status': 'cancelled'});

    final item = findById(r.itemId);
    if (item != null) {
      for (var d in r.days()) {
        final key = item.keyFor(d);
        final cur = item.reservations[key] ?? 0;
        final next = (cur - r.qty).clamp(0, item.total);
        if (next == 0) item.reservations.remove(key);
        else item.reservations[key] = next;
      }
    }
    notifyListeners();
  }

  void setRateForType(String type, double rate) {
    typeRates[type] = rate;
    notifyListeners();
  }

  double priceFor(Item item, int days) {
    final price = (item.pricePerDay > 0.0) ? item.pricePerDay : (typeRates[item.type] ?? 0.0);
    return price * days;
  }

  List<DateTime> busyDays(Item item) => item.busyDays();

  // Admin CRUD helpers
  void addItem(String name, String type, int total, {String? imageBase64, double pricePerDay = 0.0, double unitPrice = 0.0}) {
    final id = const Uuid().v4();
    final it = Item(id: id, name: name, type: type, total: total, imageBase64: imageBase64, pricePerDay: pricePerDay, unitPrice: unitPrice);
    final payload = {
      'name': name,
      'type': type,
      'total': total,
      'pricePerDay': pricePerDay,
      'unitPrice': unitPrice,
    };
    if (imageBase64 != null && imageBase64.isNotEmpty) payload['imageBase64'] = imageBase64;
    _firestore.collection('items').doc(id).set(payload);
    _items.add(it);
    notifyListeners();
  }

  /// Seed the `items` collection with some example products if it's empty.
  /// Safe to call multiple times: it checks for existing documents first.
  Future<void> seedDefaultItems() async {
    final snap = await _firestore.collection('items').limit(1).get();
    if (snap.docs.isNotEmpty) return; // already have data

    final samples = [
      {'name': 'Mesa redonda', 'type': 'mesa', 'total': 10, 'pricePerDay': 25.0, 'unitPrice': 25.0},
      {'name': 'Mesa rectangular', 'type': 'mesa', 'total': 6, 'pricePerDay': 30.0, 'unitPrice': 30.0},
      {'name': 'Silla plegable', 'type': 'silla', 'total': 100, 'pricePerDay': 2.5, 'unitPrice': 2.5},
      {'name': 'Sofá 3 plazas', 'type': 'decor', 'total': 5, 'pricePerDay': 80.0, 'unitPrice': 80.0},
      {'name': 'Escenario pequeño', 'type': 'escenario', 'total': 2, 'pricePerDay': 300.0, 'unitPrice': 300.0},
      {'name': 'Alfombra decorativa', 'type': 'decor', 'total': 8, 'pricePerDay': 15.0, 'unitPrice': 15.0},
      {'name': 'Mesa auxiliar', 'type': 'mesa', 'total': 12, 'pricePerDay': 18.0, 'unitPrice': 18.0},
    ];

    for (final s in samples) {
      addItem(s['name'] as String, s['type'] as String, s['total'] as int,
          pricePerDay: s['pricePerDay'] as double, unitPrice: s['unitPrice'] as double);
    }
  }

  void updateItem(String id, String name, String type, int total, {String? imageBase64, double? pricePerDay, double? unitPrice}) {
    final it = findById(id);
    if (it == null) return;
    final updatePayload = {'name': name, 'type': type, 'total': total};
    if (imageBase64 != null) updatePayload['imageBase64'] = imageBase64;
    if (pricePerDay != null) updatePayload['pricePerDay'] = pricePerDay;
    if (unitPrice != null) updatePayload['unitPrice'] = unitPrice;
    _firestore.collection('items').doc(id).update(updatePayload);
    final idx = _items.indexWhere((e) => e.id == id);
    _items[idx] = Item(
      id: id,
      name: name,
      type: type,
      total: total,
      imageBase64: imageBase64 ?? it.imageBase64,
      pricePerDay: pricePerDay ?? it.pricePerDay,
      unitPrice: unitPrice ?? it.unitPrice,
    );
    notifyListeners();
  }

  void deleteItem(String id) {
    _firestore.collection('items').doc(id).delete();
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // Reservation management
  void updateReservationStatus(String reservationId, String status) {
    final r = _reservations.firstWhere((x) => x.id == reservationId, orElse: () => throw Exception('Not found'));
    r.status = status;
    _firestore.collection('reservations').doc(reservationId).update({'status': status});
    notifyListeners();
  }

  // Warehouse helpers: block/unblock items on a specific date (for admin)
  void blockDay(Item item, DateTime date, int qty) {
    final key = item.keyFor(date);
    item.reservations[key] = (item.reservations[key] ?? 0) + qty;
    notifyListeners();
  }

  void unblockDay(Item item, DateTime date, int qty) {
    final key = item.keyFor(date);
    final cur = item.reservations[key] ?? 0;
    final next = (cur - qty).clamp(0, item.total);
    if (next == 0) item.reservations.remove(key);
    else item.reservations[key] = next;
    notifyListeners();
  }
}

