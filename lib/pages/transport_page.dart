import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/transport_service.dart';

class TransportPage extends StatefulWidget {
  const TransportPage({super.key});

  @override
  State<TransportPage> createState() => _TransportPageState();
}

class _TransportPageState extends State<TransportPage> {
  double _distance = 10.0;

  @override
  Widget build(BuildContext context) {
    final transport = Provider.of<TransportService>(context);
    final estimate = transport.estimateCost(_distance);
    return Scaffold(
      appBar: AppBar(title: const Text('Transporte')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Distancia: ${_distance.toStringAsFixed(1)} km'),
            Slider(
              min: 0,
              max: 300,
              value: _distance,
              onChanged: (v) => setState(() => _distance = v),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                title: const Text('Costo estimado'),
                subtitle: Text('\$ ${estimate.toStringAsFixed(2)}'),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Transporte solicitado. Estimado: \$${estimate.toStringAsFixed(2)}'),
                ));
              },
              child: const Text('Solicitar transporte'),
            ),
          ],
        ),
      ),
    );
  }
}
