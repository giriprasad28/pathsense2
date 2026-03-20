import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'emergency_contacts_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  bool tripStarted = false;
  String selectedMode = "Walk";

  final fromController =
  TextEditingController(text: "Chennai");
  final toController =
  TextEditingController(text: "Vellore");

  StreamSubscription<Position>? _positionStream;
  Position? _currentPosition;

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  String? estimatedTime;

  // ================== MODE MAPPING ==================

  String _getTravelMode() {
    switch (selectedMode) {
      case "Walk":
        return "walking";
      case "Bike":
        return "bicycling";
      case "Car":
        return "driving";
      default:
        return "walking";
    }
  }

  // ================== LOCATION PERMISSION ==================

  Future<bool> _handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  // ================== CALCULATE ETA ==================

  Future<void> _calculateDuration() async {
    final origin = fromController.text;
    final destination = toController.text;

    setState(() {
      estimatedTime = "Calculating...";
    });

    final url =
        "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=$origin"
        "&destination=$destination"
        "&mode=${_getTravelMode()}"
        "&key=AIzaSyDT79Gza-BJ4r0YwBLd7iiTtvZ7GOQUvVc";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("Directions API response:");
      print(data);

      if (data["routes"].isNotEmpty) {
        final duration =
        data["routes"][0]["legs"][0]["duration"]["text"];

        setState(() {
          estimatedTime = duration;
        });
      } else {
        setState(() {
          estimatedTime = "Route not found";
        });
      }
    } else {
      setState(() {
        estimatedTime = "Error fetching route";
      });
    }
  }

  // ================== START TRACKING ==================

  Future<void> _startTracking() async {
    final hasPermission = await _handlePermission();
    if (!hasPermission) return;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;

        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId("currentLocation"),
            position:
            LatLng(position.latitude, position.longitude),
          ),
        );
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude),
        ),
      );
    });
  }

  void _stopTracking() {
    _positionStream?.cancel();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    fromController.dispose();
    toController.dispose();
    super.dispose();
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

              /// STATUS CARD
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6A00),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("CURRENT STATUS",
                        style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 1,
                            color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text(
                      tripStarted ? selectedMode : "Ready to Go",
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    _locationInput("FROM", fromController),
                    const SizedBox(height: 12),
                    _locationInput("TO", toController),
                    const SizedBox(height: 24),

                    if (!tripStarted)
                      _startTripButton()
                    else
                      _endTripRow(),

                    const SizedBox(height: 10),

                    if (!tripStarted)
                      Text(
                        estimatedTime != null
                            ? "Estimated duration: $estimatedTime"
                            : "Enter locations",
                        style:
                        const TextStyle(color: Colors.white70),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// TRAVEL MODE
              const Text("TRAVEL MODE",
                  style: TextStyle(
                      color: Colors.grey,
                      letterSpacing: 1)),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  _modeButton("Walk", Icons.directions_walk),
                  _modeButton("Bike", Icons.directions_bike),
                  _modeButton("Car", Icons.directions_car),
                ],
              ),

              const SizedBox(height: 30),

              /// LIVE MAP
              const Text("LIVE TRACKING",
                  style: TextStyle(
                      color: Colors.grey,
                      letterSpacing: 1)),
              const SizedBox(height: 12),

              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: _currentPosition == null
                      ? const Center(
                      child: CircularProgressIndicator())
                      : GoogleMap(
                    initialCameraPosition:
                    CameraPosition(
                      target: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      zoom: 16,
                    ),
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _locationInput(
      String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style:
          const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor:
            Colors.white.withOpacity(0.15),
            border: OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _startTripButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding:
          const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(20),
          ),
        ),
        onPressed: () async {
          await _calculateDuration();
          await _startTracking();

          setState(() {
            tripStarted = true;
          });
        },
        icon: const Icon(Icons.play_arrow,
            color: Colors.orange),
        label: const Text(
          "START TRIP",
          style: TextStyle(
              color: Colors.orange,
              fontWeight:
              FontWeight.bold),
        ),
      ),
    );
  }

  Widget _endTripRow() {
    return Row(
      mainAxisAlignment:
      MainAxisAlignment.spaceBetween,
      children: [
        Text(
          estimatedTime != null
              ? "Arriving in $estimatedTime"
              : "Arriving...",
          style:
          const TextStyle(color: Colors.white),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
            Colors.white.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(18),
            ),
          ),
          onPressed: () {
            _stopTracking();
            setState(() {
              tripStarted = false;
            });
          },
          child: const Text("END TRIP"),
        )
      ],
    );
  }

  Widget _modeButton(
      String text, IconData icon) {
    final isSelected = selectedMode == text;

    return GestureDetector(
      onTap: () async {
        setState(() {
          selectedMode = text;
        });

        if (!tripStarted) {
          await _calculateDuration();
        }
      },
      child: Container(
        width: 100,
        padding:
        const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF6A00)
              : const Color(0xFF1A1A1A),
          borderRadius:
          BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected
                    ? Colors.white
                    : Colors.grey),
            const SizedBox(height: 8),
            Text(text,
                style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Colors.grey)),
          ],
        ),
      ),
    );
  }
}