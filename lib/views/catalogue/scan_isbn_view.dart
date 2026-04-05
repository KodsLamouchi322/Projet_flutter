import 'package:flutter/material.dart';

class ScanIsbnView extends StatefulWidget {
  const ScanIsbnView({Key? key}) : super(key: key);

  @override
  State<ScanIsbnView> createState() => _ScanIsbnViewState();
}

class _ScanIsbnViewState extends State<ScanIsbnView> {
  String? scannedCode;
  bool isScanning = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner ISBN'), backgroundColor: Colors.orange),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 260, height: 140,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange, width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.qr_code_scanner, color: Colors.white, size: 60),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Pointez sur le code-barres du livre',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
          if (scannedCode != null)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('ISBN detecte: \', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    onPressed: () => Navigator.pop(context, scannedCode),
                    child: const Text('Rechercher ce livre'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
