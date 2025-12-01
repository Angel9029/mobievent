import 'package:cloud_firestore/cloud_firestore.dart';

class Reservation {
  final String id;
  final String userId;
  final String itemId;
  final int qty;
  final DateTime start;
  final DateTime end;
  String status; // active, cancelled, completed
  final DateTime createdAt;
  final int? daysCount;
  final double? pricePerDay;
  final double? totalPrice;
  final double? distanceKm;
  final bool? pickup;
  final String? assignedVehicleId;
  final DateTime? lastRescheduleDate;

  Reservation({
    required this.id,
    required this.userId,
    required this.itemId,
    required this.qty,
    required this.start,
    required this.end,
    this.status = 'active',
    DateTime? createdAt,
    this.daysCount,
    this.pricePerDay,
    this.totalPrice,
    this.distanceKm,
    this.pickup,
    this.assignedVehicleId,
    this.lastRescheduleDate,
  }) : createdAt = createdAt ?? DateTime.now();

  bool overlaps(DateTime s, DateTime e) {
    return !(e.isBefore(start) || s.isAfter(end));
  }

  List<DateTime> days() {
    final res = <DateTime>[];
    for (var d = DateTime(start.year, start.month, start.day);
        !d.isAfter(DateTime(end.year, end.month, end.day));
        d = d.add(const Duration(days: 1))) {
      res.add(d);
    }
    return res;
  }

  factory Reservation.fromJson(String id, Map<String, dynamic> json) {
    return Reservation(
      id: id,
      userId: json['userId'] ?? '',
      itemId: json['itemId'] ?? '',
      qty: json['qty'] ?? 1,
      start: json['start'] != null ? (json['start'] is Timestamp ? (json['start'] as Timestamp).toDate() : DateTime.parse(json['start'])) : DateTime.now(),
      end: json['end'] != null ? (json['end'] is Timestamp ? (json['end'] as Timestamp).toDate() : DateTime.parse(json['end'])) : DateTime.now(),
      status: json['status'] ?? 'active',
      createdAt: json['createdAt'] != null ? (json['createdAt'] is Timestamp ? (json['createdAt'] as Timestamp).toDate() : DateTime.parse(json['createdAt'])) : DateTime.now(),
      daysCount: json['daysCount'],
      pricePerDay: (json['pricePerDay'] as num?)?.toDouble(),
      totalPrice: (json['totalPrice'] as num?)?.toDouble(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      pickup: json['pickup'],
      assignedVehicleId: json['assignedVehicleId'],
      lastRescheduleDate: json['lastRescheduleDate'] != null ? (json['lastRescheduleDate'] is Timestamp ? (json['lastRescheduleDate'] as Timestamp).toDate() : DateTime.parse(json['lastRescheduleDate'])) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'itemId': itemId,
      'qty': qty,
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'daysCount': daysCount,
      'pricePerDay': pricePerDay,
      'totalPrice': totalPrice,
      'distanceKm': distanceKm,
      'pickup': pickup,
      'assignedVehicleId': assignedVehicleId,
      'lastRescheduleDate': lastRescheduleDate != null ? Timestamp.fromDate(lastRescheduleDate!) : null,
    };
  }
}
