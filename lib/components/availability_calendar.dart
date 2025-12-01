import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/item.dart';

class AvailabilityCalendar extends StatelessWidget {
  final Item item;
  final int desiredQty;
  final int daysToShow;

  const AvailabilityCalendar({super.key, required this.item, this.desiredQty = 1, this.daysToShow = 30});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(daysToShow, (i) => DateTime(today.year, today.month, today.day).add(Duration(days: i)));
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (ctx, i) {
          final d = days[i];
          final key = item.keyFor(d);
          final reserved = item.reservations[key] ?? 0;
          final available = (item.total - reserved) >= desiredQty;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
            child: Column(children: [
              Container(
                width: 60,
                height: 50,
                decoration: BoxDecoration(color: available ? Colors.green[100] : Colors.red[200], borderRadius: BorderRadius.circular(8)),
                child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(DateFormat('d').format(d), style: const TextStyle(fontWeight: FontWeight.bold)), Text(DateFormat('E').format(d), style: const TextStyle(fontSize: 11))])),
              ),
              const SizedBox(height: 6),
              Text(available ? 'OK' : 'No', style: TextStyle(color: available ? Colors.green : Colors.red, fontSize: 12)),
            ]),
          );
        },
      ),
    );
  }
}
