import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geocoding/geocoding.dart';

import '../auth/login_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {

  final supabase = Supabase.instance.client;

  String selectedMode = "Car";

  final fromController = TextEditingController(text: "Chennai");
  final toController = TextEditingController(text: "Vellore");

  StreamSubscription<Position>? _positionStream;
  Position? _currentPosition;

  GoogleMapController? _mapController;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  String? estimatedTime;
  double _bearing = 0;

  bool isTripStarted = false;

  final String orsKey = "eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImVjZjgxMzllNzc3MjRlNDQ4M2Y5Yjg5NmE4MWRiOGRjIiwiaCI6Im11cm11cjY0In0=";

  /// ================= NEW SMART STOP DETECTION =================
  LatLng? lastPosition;
  DateTime? lastMoveTime;
  bool isPromptShown = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _initLocation() async {
    final ok = await _handlePermission();
    if (!ok) return;

    final pos = await Geolocator.getCurrentPosition();

    setState(() {
      _currentPosition = pos;
      _markers = {
        Marker(
          markerId: const MarkerId("me"),
          position: LatLng(pos.latitude, pos.longitude),
        ),
      };
    });
  }

  Future<void> _setCurrentLocationToFrom() async {
    final ok = await _handlePermission();
    if (!ok) return;

    final pos = await Geolocator.getCurrentPosition();
    final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);

    if (placemarks.isNotEmpty) {
      final p = placemarks.first;
      setState(() {
        fromController.text = "${p.subLocality ?? ""}, ${p.locality ?? ""}";
      });
    }
  }

  Future<bool> _handlePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  Future<void> _sendLocation(Position p) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('live_location').upsert({
      'user_id': user.id,
      'latitude': p.latitude,
      'longitude': p.longitude,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  String _getORSProfile() {
    switch (selectedMode) {
      case "Walk":
        return "foot-walking";
      case "Bike":
      case "Car":
        return "driving-car";
      default:
        return "driving-car";
    }
  }

  Future<Map<String, double>?> _getCoordinates(String place) async {
    try {
      List<Location> locations = await locationFromAddress("$place,Tamil Nadu, India");

      if (locations.isNotEmpty) {
        return {
          "lat": locations.first.latitude,
          "lng": locations.first.longitude,
        };
      }
    } catch (e) {
      print("Geocoding error: $e");
    }

    return null;
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return poly;
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double x0 = list.first.latitude;
    double x1 = list.first.latitude;
    double y0 = list.first.longitude;
    double y1 = list.first.longitude;

    for (var latLng in list) {
      if (latLng.latitude > x1) x1 = latLng.latitude;
      if (latLng.latitude < x0) x0 = latLng.latitude;
      if (latLng.longitude > y1) y1 = latLng.longitude;
      if (latLng.longitude < y0) y0 = latLng.longitude;
    }

    return LatLngBounds(
      northeast: LatLng(x1, y1),
      southwest: LatLng(x0, y0),
    );
  }

  Future<void> _calculateRoute() async {
    try {
      setState(() => estimatedTime = "Calculating...");

      final start = await _getCoordinates(fromController.text);
      final end = await _getCoordinates(toController.text);

      if (start == null || end == null) {
        setState(() => estimatedTime = "Invalid location");
        return;
      }

      final res = await http.post(
        Uri.parse("https://api.openrouteservice.org/v2/directions/${_getORSProfile()}"),
        headers: {
          "Authorization": orsKey,
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          "coordinates": [
            [start["lng"], start["lat"]],
            [end["lng"], end["lat"]]
          ]
        }),
      );

      final data = json.decode(res.body);

      if (data["routes"] == null || data["routes"].isEmpty) {
        setState(() => estimatedTime = "Route not found");
        return;
      }

      final route = data["routes"][0];
      final polyPoints = _decodePolyline(route["geometry"]);

      final duration = route["summary"]["duration"];
      double mins = (duration / 60);

      int totalMinutes = mins.round();

      setState(() {
        estimatedTime = "$totalMinutes min";
        _polylines = {
          Polyline(
            polylineId: const PolylineId("route"),
            points: polyPoints,
            color: Colors.orange,
            width: 5,
          )
        };
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          _boundsFromLatLngList(polyPoints),
          50,
        ),
      );
    } catch (e) {
      setState(() => estimatedTime = "Error");
    }
  }

  /// ================= SMART TRACKING =================
  Future<void> _startTracking() async {
    final ok = await _handlePermission();
    if (!ok) return;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) async {

      final currentLatLng = LatLng(pos.latitude, pos.longitude);

      /// 🔥 STOP DETECTION LOGIC
      if (lastPosition != null) {
        final distance = Geolocator.distanceBetween(
          lastPosition!.latitude,
          lastPosition!.longitude,
          currentLatLng.latitude,
          currentLatLng.longitude,
        );

        if (distance < 10) {
          final now = DateTime.now();

          if (lastMoveTime != null &&
              now.difference(lastMoveTime!).inMinutes >= 1 &&
              !isPromptShown) {

            isPromptShown = true;
            showUserStatusPrompt();
          }
        } else {
          lastMoveTime = DateTime.now();
          isPromptShown = false;
        }
      } else {
        lastMoveTime = DateTime.now();
      }

      lastPosition = currentLatLng;

      /// NORMAL TRACKING
      setState(() {
        _currentPosition = pos;

        _markers = {
          Marker(
            markerId: const MarkerId("me"),
            position: LatLng(pos.latitude, pos.longitude),
          ),
        };
      });

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(pos.latitude, pos.longitude),
            zoom: 17,
          ),
        ),
      );

      await _sendLocation(pos);
    });
  }

  /// ================= USER PROMPT =================
  void showUserStatusPrompt() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("What are you doing?"),
        content: const Text("You've been in the same place for a while."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              sendUserStatus("Waiting");
            },
            child: const Text("Waiting"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              sendUserStatus("Shopping");
            },
            child: const Text("Shopping"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              sendUserStatus("Food Break");
            },
            child: const Text("Food"),
          ),
        ],
      ),
    );
  }

  Future<void> sendUserStatus(String status) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;


    final links = await supabase
        .from('user_parent_link')
        .select()
        .eq('user_id', user.id);

    for (var parent in links) {
      await supabase.from('alerts').insert({
        'parent_id': parent['parent_id'],
        'message': 'User is $status',
        'latitude': _currentPosition?.latitude,
        'longitude': _currentPosition?.longitude,
      });
    }
  }
  Future<void> sendSOSAlert() async {
    final user = supabase.auth.currentUser;
    if (user == null || _currentPosition == null) return;

    final links = await supabase
        .from('user_parent_link')
        .select()
        .eq('user_id', user.id);

    for (var parent in links) {
      await supabase.from('alerts').insert({
        'parent_id': parent['parent_id'],
        'message': '🚨 SOS EMERGENCY!',
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("SOS Alert Sent 🚨")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Good Evening",
                    style: TextStyle(color: Colors.grey)),
                IconButton(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.orange),
                )
              ],
            ),

            const SizedBox(height: 20),

            TextField(
              controller: fromController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputStyle("Enter Starting Location"),
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _setCurrentLocationToFrom,
                icon: const Icon(Icons.my_location, color: Colors.orange),
                label: const Text("Use Current Location",
                    style: TextStyle(color: Colors.orange)),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: toController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputStyle("Enter Destination"),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF7A00), Color(0xFFFF5E00)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("CURRENT STATUS",
                      style: TextStyle(color: Colors.white70)),

                  const SizedBox(height: 10),

                  Text(selectedMode,
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),

                  const SizedBox(height: 20),

                  Text("FROM: ${fromController.text}",
                      style: const TextStyle(color: Colors.white)),

                  Text("TO: ${toController.text}",
                      style: const TextStyle(color: Colors.white)),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Arriving in ${estimatedTime ?? '--'}",
                          style: const TextStyle(color: Colors.white)),

                      if (!isTripStarted)
                        ElevatedButton(
                          onPressed: () async {
                            await _calculateRoute();
                            await _startTracking();
                            setState(() => isTripStarted = true);
                          },
                          child: const Text("START"),
                        )
                      else
                        ElevatedButton(
                          onPressed: () {
                            _positionStream?.cancel();
                            setState(() => isTripStarted = false);
                          },
                          child: const Text("END"),
                        )
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Text("TRAVEL MODE",
                style: TextStyle(color: Colors.grey)),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _modeButton("Walk", Icons.directions_walk),
                _modeButton("Bike", Icons.directions_bike),
                _modeButton("Car", Icons.directions_car),
              ],
            ),

            const SizedBox(height: 20),

            Container(
              height: 200,
              child: _currentPosition == null
                  ? const Center(child: CircularProgressIndicator())
                  : GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  ),
                  zoom: 14,
                ),
                markers: _markers,
                polylines: _polylines,
                onMapCreated: (c) => _mapController = c,
              ),
            ),
             SizedBox(height: 20),

            /// 🚨 SOS BUTTON
            SizedBox(
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: sendSOSAlert,
                child: Text(
                  "🚨 SOS",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
      ),
    );
  }

  Widget _modeButton(String text, IconData icon) {
    final selected = selectedMode == text;

    return GestureDetector(
      onTap: () async {
        setState(() => selectedMode = text);
        await _calculateRoute();
      },
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? Colors.orange : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 5),
            Text(text, style: const TextStyle(color: Colors.white))
          ],
        ),
      ),
    );
  }
}
