
class Item {
  final String id;
  final String name;
  final String type;
  final int total;
  final String? imageBase64;
  final double pricePerDay;
  final double unitPrice;
  final Map<String, int> reservations = {}; // yyyy-MM-dd -> qty reserved

  Item({
    required this.id,
    required this.name,
    required this.type,
    required this.total,
    this.imageBase64,
    this.pricePerDay = 0.0,
    this.unitPrice = 0.0,
  });

  bool isAvailableOn(DateTime date, {int qty = 1}) {
    final key = keyFor(date);
    final reserved = reservations[key] ?? 0;
    return (total - reserved) >= qty;
  }

  void reserve(DateTime date, int qty) {
    final key = keyFor(date);
    reservations[key] = (reservations[key] ?? 0) + qty;
  }

  void unblock(DateTime date, int qty) {
    final key = keyFor(date);
    final cur = reservations[key] ?? 0;
    final next = (cur - qty).clamp(0, total);
    if (next == 0) reservations.remove(key);
    else reservations[key] = next;
  }

  List<DateTime> busyDays() {
    return reservations.keys.map((k) => DateTime.parse(k)).toList();
  }

  String keyFor(DateTime d) => DateTime(d.year, d.month, d.day).toIso8601String().split('T').first;
}
