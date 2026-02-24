import 'package:flutter/material.dart';
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
  TextEditingController(text: "University Campus");
  final toController =
  TextEditingController(text: "Home (Downtown)");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [

              /// HEADER
              Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundImage: AssetImage("assets/avatar.png"),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("GOOD EVENING",
                            style: TextStyle(
                                color: Colors.grey, fontSize: 12)),
                        Text("Alex Rivera",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF1A1A1A),
                    child: const Icon(Icons.notifications_none),
                  )
                ],
              ),

              const SizedBox(height: 30),

              /// STATUS CARD
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6A00),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.4),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    )
                  ],
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
                      tripStarted ? "Walking" : "Ready to Go",
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 20),

                    /// FROM
                    _locationInput("FROM", fromController),

                    const SizedBox(height: 12),

                    /// TO
                    _locationInput("TO", toController),

                    const SizedBox(height: 24),

                    if (!tripStarted)
                      _startTripButton()
                    else
                      _endTripRow(),

                    const SizedBox(height: 10),

                    if (!tripStarted)
                      const Text(
                        "Estimated duration: 12 mins",
                        style: TextStyle(color: Colors.white70),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _modeButton("Walk", Icons.directions_walk),
                  _modeButton("Bike", Icons.directions_bike),
                  _modeButton("Car", Icons.directions_car),
                ],
              ),

              const SizedBox(height: 30),

              /// LIVE TRACKING
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text("LIVE TRACKING",
                      style: TextStyle(
                          color: Colors.grey,
                          letterSpacing: 1)),
                  Text("• LIVE",
                      style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12)),
                ],
              ),

              const SizedBox(height: 12),

              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                    child: Icon(Icons.navigation,
                        size: 40,
                        color: Colors.orange)),
              ),

              const SizedBox(height: 30),

              /// EMERGENCY CONTACTS
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: const [
                        Text("EMERGENCY CONTACTS",
                            style: TextStyle(
                                fontWeight: FontWeight.bold)),
                        Text("2 Active",
                            style:
                            TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Sarah and Marcus are being notified of your trip status.",
                      style:
                      TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Colors.orange),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const EmergencyContactsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add,
                          color: Colors.orange),
                      label: const Text("Add Contact",
                          style: TextStyle(
                              color: Colors.orange)),
                    ),
                  ],
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
          style: const TextStyle(color: Colors.white),
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
        onPressed: () {
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
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _endTripRow() {
    return Row(
      mainAxisAlignment:
      MainAxisAlignment.spaceBetween,
      children: [
        const Text("Arriving in 12 mins",
            style: TextStyle(color: Colors.white)),
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
      onTap: () {
        setState(() {
          selectedMode = text;
        });
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