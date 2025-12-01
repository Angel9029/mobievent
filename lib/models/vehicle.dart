class Vehicle {
  final String id;
  final String plate; // Placa del vehículo
  final String model;
  final String driver;
  final String status; // available, in_transit, maintenance
  final int capacity; // Capacidad de carga (unidades)
  final DateTime createdAt;

  Vehicle({
    required this.id,
    required this.plate,
    required this.model,
    required this.driver,
    this.status = 'available',
    this.capacity = 100,
    required this.createdAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json, String docId) {
    return Vehicle(
      id: docId,
      plate: json['plate'] as String? ?? '',
      model: json['model'] as String? ?? '',
      driver: json['driver'] as String? ?? '',
      status: json['status'] as String? ?? 'available',
      capacity: (json['capacity'] as num?)?.toInt() ?? 100,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'plate': plate,
        'model': model,
        'driver': driver,
        'status': status,
        'capacity': capacity,
        'createdAt': createdAt,
      };
}
