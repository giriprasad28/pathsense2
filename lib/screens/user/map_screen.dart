import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Full Map")),
      body: const Center(
        child: Icon(Icons.map, size: 80),
      ),
    );
  }
}