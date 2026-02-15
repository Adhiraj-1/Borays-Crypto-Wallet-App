import 'package:flutter/material.dart';

class QRGenerator extends StatelessWidget {
  final String data;
  final double size;
  
  const QRGenerator({
    Key? key,
    required this.data,
    this.size = 200,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code, size: 100),
            const SizedBox(height: 10),
            const Text(
              'QR Code',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              'Data: ${data.substring(0, 10)}...',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
