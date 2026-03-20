import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ParentDashboradScreen extends StatefulWidget {
  const ParentDashboradScreen({super.key});

  @override
  State<ParentDashboradScreen> createState() =>
      _ParentDashboradScreenState();
}

class _ParentDashboradScreenState
    extends State<ParentDashboradScreen> {
  GoogleMapController? _mapController;

  // TEMP: Static location (replace later with backend data)
  LatLng childLocation =
  const LatLng(13.0827, 80.2707); // Chennai

  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();

    _markers.add(
      Marker(
        markerId: const MarkerId("child"),
        position: childLocation,
        infoWindow:
        const InfoWindow(title: "Alex (Live Location)"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [

              const SizedBox(height: 30),

              /// SAFE STATUS CARD
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius:
                  BorderRadius.circular(28),
                ),
                child: const Column(
                  children: [
                    Text(
                      "SAFE",
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// LIVE LOCATION TITLE
              const Text(
                "Live Location",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                    FontWeight.bold),
              ),

              const SizedBox(height: 14),

              /// 🔥 MINI LIVE MAP
              Container(
                height: 220,
                decoration: BoxDecoration(
                  borderRadius:
                  BorderRadius.circular(24),
                ),
                child: ClipRRect(
                  borderRadius:
                  BorderRadius.circular(24),
                  child: GoogleMap(
                    initialCameraPosition:
                    CameraPosition(
                      target: childLocation,
                      zoom: 14,
                    ),
                    markers: _markers,
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled:
                    false,
                    onMapCreated:
                        (GoogleMapController controller) {
                      _mapController =
                          controller;
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// MODE + ETA
              Row(
                children: [
                  Expanded(
                    child: _infoCard(
                        Icons.directions_walk,
                        "CURRENT MODE",
                        "Walking"),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _infoCard(
                        Icons.timer,
                        "ETA HOME",
                        "8 mins"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(
      IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius:
        BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.orange),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
                color: Colors.grey,
                fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.bold),
          ),
        ],
      ),
    );
  }
}