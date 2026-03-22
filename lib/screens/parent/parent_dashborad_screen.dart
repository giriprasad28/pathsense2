import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

import '../auth/login_screen.dart';

class ParentDashboradScreen extends StatefulWidget {
  const ParentDashboradScreen({super.key});

  @override
  State<ParentDashboradScreen> createState() =>
      _ParentDashboradScreenState();
}

class _ParentDashboradScreenState
    extends State<ParentDashboradScreen> {
  GoogleMapController? _mapController;

  final supabase = Supabase.instance.client;

  LatLng childLocation =
  const LatLng(13.0827, 80.2707);

  Set<Marker> _markers = {};

  double _bearing = 0;

  String? currentParentId;
  bool alertShown = false;

  @override
  void initState() {
    super.initState();
    initParent();
  }

  // ================= INIT =================
  Future<void> initParent() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    currentParentId = user.id;

    listenToLocation();
    listenToAlerts();
  }

  // ================= LOGOUT =================
  Future<void> _logout() async {
    await supabase.auth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  // ================= LOCATION =================
  void listenToLocation() {
    supabase
        .from('live_location')
        .stream(primaryKey: ['id'])
        .listen((data) {
      if (data.isNotEmpty) {
        final latest = data.last;

        double lat = latest['latitude'];
        double lng = latest['longitude'];

        updateMap(lat, lng);
      }
    });
  }

  // ================= ALERT LISTENER =================
  void listenToAlerts() {
    supabase
        .from('alerts')
        .stream(primaryKey: ['id'])
        .eq('parent_id', currentParentId!)
        .listen((data) {
      if (data.isNotEmpty) {
        final alert = data.last;

        if (!alertShown) {
          alertShown = true;
          showAlertPopup(alert);
        }
      }
    });
  }

  // ================= ALERT POPUP =================
  void showAlertPopup(Map alert) {
    final lat = alert['latitude'];
    final lng = alert['longitude'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("🚨 EMERGENCY ALERT"),
        content: Text(
          "${alert['message']}\n\nLocation:\n$lat , $lng",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              moveToAlertLocation(lat, lng);
              alertShown = false;
            },
            child: const Text("VIEW ON MAP"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              alertShown = false;
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // ================= MOVE CAMERA =================
  void moveToAlertLocation(double lat, double lng) {
    final pos = LatLng(lat, lng);

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(pos, 18),
    );
  }

  // ================= UPDATE MAP =================
  void updateMap(double lat, double lng) {
    final newPosition = LatLng(lat, lng);

    final double bearing =
    _getBearing(childLocation, newPosition);

    setState(() {
      childLocation = newPosition;
      _bearing = bearing;

      _markers = {
        Marker(
          markerId: const MarkerId("child"),
          position: newPosition,
          rotation: _bearing,
          anchor: const Offset(0.5, 0.5),
          infoWindow:
          const InfoWindow(title: "Live Location"),
        ),
      };
    });

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: newPosition,
          zoom: 17,
          tilt: 45,
          bearing: _bearing,
        ),
      ),
    );
  }

  // ================= BEARING =================
  double _getBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * (pi / 180);
    final lon1 = start.longitude * (pi / 180);

    final lat2 = end.latitude * (pi / 180);
    final lon2 = end.longitude * (pi / 180);

    final dLon = lon2 - lon1;

    final y = sin(dLon) * cos(lat2);
    final x =
        cos(lat1) * sin(lat2) -
            sin(lat1) * cos(lat2) * cos(dLon);

    final brng = atan2(y, x);

    return (brng * 180 / pi + 360) % 360;
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),

      /// 🔥 APP BAR WITH LOGOUT
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Parent Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              const SizedBox(height: 20),

              /// STATUS CARD
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Column(
                  children: [
                    Text(
                      "SAFE",
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Live Location",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 14),

              /// MAP
              Container(
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: childLocation,
                      zoom: 14,
                    ),
                    markers: _markers,
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    compassEnabled: true,
                    tiltGesturesEnabled: true,
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _infoCard(
                        Icons.directions_walk,
                        "STATUS",
                        "Tracking"),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _infoCard(
                        Icons.warning,
                        "ALERT",
                        "Active"),
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
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.orange),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}