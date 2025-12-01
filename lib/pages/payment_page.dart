import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/payment_service.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _amountCtrl = TextEditingController(text: '50.0');

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pay = Provider.of<PaymentService>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Pago y Contrato')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Monto señal (USD)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(_amountCtrl.text) ?? 0.0;
                final ok = await pay.payDeposit(amount);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? 'Señal pagada: \$$amount' : 'Pago fallido')),
                );
              },
              child: const Text('Pagar señal (simulado)'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Checkbox(
                  value: pay.contractSigned,
                  onChanged: (v) => pay.signContract(),
                ),
                const Expanded(child: Text('Firmar contrato digital (simulado)')),
              ],
            ),
            const SizedBox(height: 12),
            Text('Estado: Señal pagada: ${pay.depositPaid ? 'Sí' : 'No'} • Contrato: ${pay.contractSigned ? 'Firmado' : 'Pendiente'}'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                pay.reset();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estado reseteado')));
              },
              child: const Text('Resetear estado (solo demo)'),
            ),
          ],
        ),
      ),
    );
  }
}
