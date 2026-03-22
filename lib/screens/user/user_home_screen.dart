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

  final String orsKey = "eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImVjZjgxMzllNzc3MjRlNDQ4M2Y5Yjg5NmE4MWRiOGRjIiwiaCI6Im11cm11cjY0In0=";

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  // ================= LOGOUT =================
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

    final placemarks =
    await placemarkFromCoordinates(pos.latitude, pos.longitude);

    if (placemarks.isNotEmpty) {
      final p = placemarks.first;

      setState(() {
        fromController.text =
        "${p.subLocality ?? ""}, ${p.locality ?? ""}";
      });
    }
  }

  String _getORSProfile() {
    switch (selectedMode) {
      case "Walk":
        return "foot-walking";
      case "Bike":
        return "driving-car";
      case "Car":
        return "driving-car";
      default:
        return "driving-car";
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

  Future<Map<String, double>?> _getCoordinates(String place) async {
    final query = "$place, Chennai, Tamil Nadu, India";

    final url =
        "https://api.openrouteservice.org/geocode/search?api_key=$orsKey&text=$query";

    final res = await http.get(Uri.parse(url));
    final data = json.decode(res.body);

    if (data["features"] != null && data["features"].isNotEmpty) {
      final c = data["features"][0]["geometry"]["coordinates"];
      return {"lng": c[0], "lat": c[1]};
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
        Uri.parse(
            "https://api.openrouteservice.org/v2/directions/${_getORSProfile()}"),
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

      final duration = route["summary"]["duration"];
      final totalMinutes = (duration / 60).round();

      final hours = totalMinutes ~/ 60;
      final mins = totalMinutes % 60;

      final polyPoints = _decodePolyline(route["geometry"]);

      setState(() {
        estimatedTime =
        hours > 0 ? "${hours}h ${mins}m" : "${mins} mins";

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
            _boundsFromLatLngList(polyPoints), 50),
      );
    } catch (e) {
      setState(() => estimatedTime = "Error");
    }
  }

  Future<void> _startTracking() async {
    final ok = await _handlePermission();
    if (!ok) return;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
      ),
    ).listen((pos) async {
      setState(() {
        _currentPosition = pos;
        _bearing = pos.heading;

        _markers = {
          Marker(
            markerId: const MarkerId("me"),
            position: LatLng(pos.latitude, pos.longitude),
            rotation: _bearing,
          ),
        };
      });

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(pos.latitude, pos.longitude),
            zoom: 18,
            tilt: 60,
            bearing: _bearing,
          ),
        ),
      );

      await _sendLocation(pos);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.orange),
              ),
            ),

            _input(fromController),

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
            _input(toController),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                await _calculateRoute();
                await _startTracking();
              },
              child: const Text("START TRIP"),
            ),

            const SizedBox(height: 10),
            Text(estimatedTime ?? "",
                style: const TextStyle(color: Colors.white)),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _mode("Walk"),
                _mode("Bike"),
                _mode("Car"),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
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
                myLocationEnabled: false,
                onMapCreated: (c) => _mapController = c,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(TextEditingController c) {
    return TextField(controller: c);
  }

  Widget _mode(String text) {
    final selected = selectedMode == text;

    return GestureDetector(
      onTap: () async {
        setState(() => selectedMode = text);
        await _calculateRoute();
      },
      child: Text(
        text,
        style: TextStyle(
          color: selected ? Colors.orange : Colors.white,
        ),
      ),
    );
  }
}