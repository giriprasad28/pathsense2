import 'package:flutter/material.dart';

class ParentDashboradScreen extends StatelessWidget {
  const ParentDashboradScreen({super.key});

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
                    radius: 26,
                    backgroundImage:
                    AssetImage("assets/avatar_parent.png"),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Michael Rivera",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "PARENT ADMINISTRATOR",
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius:
                      BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.orange),
                    ),
                    child: const Text(
                      "LINKED: ALEX",
                      style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12),
                    ),
                  )
                ],
              ),

              const SizedBox(height: 30),

              /// SAFE STATUS CARD
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius:
                  BorderRadius.circular(28),
                ),
                child: Column(
                  children: [

                    const Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified,
                            color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          "CURRENT STATUS",
                          style: TextStyle(
                              color: Colors.grey,
                              letterSpacing: 1),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "SAFE",
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.green
                            .withOpacity(0.15),
                        borderRadius:
                        BorderRadius.circular(30),
                      ),
                      child: const Text(
                        "SECURE ZONE",
                        style: TextStyle(
                            color: Colors.green),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time,
                            size: 16,
                            color: Colors.grey),
                        SizedBox(width: 6),
                        Text(
                          "LAST UPDATED: JUST NOW",
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// LIVE LOCATION TITLE
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Live Location",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.bold),
                  ),
                  Text(
                    "FULL MAP",
                    style:
                    TextStyle(color: Colors.orange),
                  )
                ],
              ),

              const SizedBox(height: 14),

              /// MAP CARD
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius:
                  BorderRadius.circular(24),
                ),
                child: Stack(
                  children: [

                    const Center(
                      child: Icon(Icons.map,
                          size: 60,
                          color: Colors.grey),
                    ),

                    Positioned(
                      top: 20,
                      left: 20,
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black
                              .withOpacity(0.8),
                          borderRadius:
                          BorderRadius.circular(
                              20),
                        ),
                        child: const Text(
                          "Alex (Near Oak St)",
                          style: TextStyle(
                              fontSize: 12),
                        ),
                      ),
                    ),

                    Positioned(
                      right: 20,
                      bottom: 20,
                      child: Column(
                        children: [
                          _mapControl(Icons.my_location),
                          const SizedBox(height: 10),
                          _mapControl(Icons.layers),
                        ],
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// MODE + ETA ROW
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

              const SizedBox(height: 30),

              /// CONTACT BAR
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius:
                  BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          Text(
                            "Contact Alex",
                            style: TextStyle(
                                fontWeight:
                                FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Fast communication enabled",
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      backgroundColor:
                      Colors.grey.shade800,
                      child: const Icon(
                          Icons.call),
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      backgroundColor:
                      Colors.grey.shade800,
                      child: const Icon(
                          Icons.message),
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

  Widget _mapControl(IconData icon) {
    return CircleAvatar(
      backgroundColor: Colors.black,
      child: Icon(icon, color: Colors.white),
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
}// TODO Implement this library.