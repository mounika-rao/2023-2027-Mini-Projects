import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends State<DashboardScreen> {

  List images = [];

  final String apiBase =
      "http://10.168.12.204:8000";

  @override
  void initState() {
    super.initState();
    loadImages();
  }

  Future<void> loadImages() async {

    try {

      final response = await http.get(
        Uri.parse("$apiBase/images"),
      );

      if (response.statusCode == 200) {

        setState(() {
          images =
              jsonDecode(response.body);
        });

      }

    } catch (_) {}
  }

  Widget sensorCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(16),
        ),

        child: Column(
          children: [

            Icon(
              icon,
              color: Colors.green,
            ),

            const SizedBox(height: 8),

            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            Text(title),

          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xffF8FAFC),

      appBar: AppBar(
        backgroundColor:
            const Color(0xff1B4332),

        foregroundColor:
            Colors.white,

        title:
            const Text("Smart Pantry"),
      ),

      body: StreamBuilder<
          QuerySnapshot>(

        stream:
            FirebaseFirestore.instance
                .collection(
                  "sensor_readings",
                )
                .orderBy(
                  "created_at",
                  descending: true,
                )
                .limit(1)
                .snapshots(),

        builder:
            (context, snapshot) {

          double temp = 0;
          double humidity = 0;
          int gas = 0;
          bool door = false;

          if (snapshot.hasData &&
              snapshot.data!.docs.isNotEmpty) {

            final data =
                snapshot.data!.docs.first
                    .data()
                    as Map<String,
                        dynamic>;

            temp =
                (data["temperature"] ??
                        0)
                    .toDouble();

            humidity =
                (data["humidity"] ??
                        0)
                    .toDouble();

            gas =
                data["gas_value"] ??
                    0;

            door =
                data["door_open"] ??
                    false;
          }

          return RefreshIndicator(

            onRefresh: loadImages,

            child: ListView(

              padding:
                  const EdgeInsets.all(
                16,
              ),

              children: [

                Row(
                  children: [

                    sensorCard(
                      "Temp",
                      "$temp°C",
                      Icons.thermostat,
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    sensorCard(
                      "Humidity",
                      "$humidity%",
                      Icons.water_drop,
                    ),
                  ],
                ),

                const SizedBox(
                  height: 12,
                ),

                Row(
                  children: [

                    sensorCard(
                      "Gas",
                      "$gas",
                      Icons.air,
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    sensorCard(
                      "Door",
                      door
                          ? "OPEN"
                          : "CLOSED",
                      Icons.door_front_door,
                    ),
                  ],
                ),

                const SizedBox(
                  height: 24,
                ),

                const Text(
                  "Captured Images",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                GridView.builder(

                  shrinkWrap: true,

                  physics:
                      const NeverScrollableScrollPhysics(),

                  itemCount:
                      images.length,

                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),

                  itemBuilder:
                      (context, index) {

                    final image =
                        images[index];

                    return Card(

                      child: Column(

                        children: [

                          Expanded(
                            child:
                                Image.network(

                              image["url"],

                              fit:
                                  BoxFit.cover,

                              width:
                                  double.infinity,
                            ),
                          ),

                          Padding(
                            padding:
                                const EdgeInsets
                                    .all(
                              8,
                            ),

                            child: Text(

                              image["name"],

                              maxLines: 1,

                              overflow:
                                  TextOverflow
                                      .ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}