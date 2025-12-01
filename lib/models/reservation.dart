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
}
