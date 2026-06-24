import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  Color getColor(String title, String body) {
    final text =
        "$title $body".toLowerCase();

    if (text.contains("expired") ||
        text.contains("spoiled")) {
      return Colors.red;
    }

    if (text.contains("1 day") ||
        text.contains("tomorrow")) {
      return Colors.deepOrange;
    }

    if (text.contains("2 day") ||
        text.contains("3 day")) {
      return Colors.orange;
    }

    return Colors.blue;
  }

  IconData getIcon(String title, String body) {
    final text =
        "$title $body".toLowerCase();

    if (text.contains("expired")) {
      return Icons.dangerous;
    }

    if (text.contains("spoiled")) {
      return Icons.warning;
    }

    if (text.contains("expire")) {
      return Icons.notifications_active;
    }

    return Icons.notifications;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xffF8FAFC,
      ),

      appBar: AppBar(
        backgroundColor:
            const Color(0xff1B4332),

        foregroundColor: Colors.white,

        title: const Text(
          "Alerts Center",
        ),
      ),

      body: Column(
        children: [

          Container(
            width: double.infinity,
            margin:
                const EdgeInsets.all(16),

            padding:
                const EdgeInsets.all(18),

            decoration: BoxDecoration(
              color:
                  Colors.orange.shade50,

              borderRadius:
                  BorderRadius.circular(
                18,
              ),
            ),

            child: const Row(
              children: [

                Icon(
                  Icons.info_outline,
                  color: Colors.orange,
                ),

                SizedBox(width: 12),

                Expanded(
                  child: Text(
                    "Food expiry and spoilage alerts appear here automatically.",
                  ),
                ),

              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<
                QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection(
                        "notifications",
                      )
                      .orderBy(
                        "created_at",
                        descending: true,
                      )
                      .snapshots(),

              builder:
                  (context, snapshot) {

                if (snapshot
                        .connectionState ==
                    ConnectionState
                        .waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot
                        .data!
                        .docs
                        .isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [

                        Icon(
                          Icons
                              .notifications_none,
                          size: 80,
                          color:
                              Colors.grey,
                        ),

                        SizedBox(
                          height: 12,
                        ),

                        Text(
                          "No alerts available",
                          style:
                              TextStyle(
                            fontSize:
                                18,
                            color: Colors
                                .grey,
                          ),
                        ),

                      ],
                    ),
                  );
                }

                final docs =
                    snapshot.data!.docs;

                return ListView.builder(
                  padding:
                      const EdgeInsets
                          .all(16),

                  itemCount:
                      docs.length,

                  itemBuilder:
                      (context, index) {

                    final data =
                        docs[index]
                                .data()
                            as Map<
                                String,
                                dynamic>;

                    final title =
                        data["title"] ??
                            "Alert";

                    final body =
                        data["body"] ??
                            "";

                    final color =
                        getColor(
                      title,
                      body,
                    );

                    final icon =
                        getIcon(
                      title,
                      body,
                    );

                    return Card(
                      elevation: 2,

                      margin:
                          const EdgeInsets
                              .only(
                        bottom: 12,
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          18,
                        ),
                      ),

                      child: Padding(
                        padding:
                            const EdgeInsets
                                .all(
                          16,
                        ),

                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [

                            CircleAvatar(
                              radius:
                                  24,

                              backgroundColor:
                                  color
                                      .withOpacity(
                                0.15,
                              ),

                              child:
                                  Icon(
                                icon,
                                color:
                                    color,
                              ),
                            ),

                            const SizedBox(
                              width: 14,
                            ),

                            Expanded(
                              child:
                                  Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [

                                  Text(
                                    title,

                                    style:
                                        const TextStyle(
                                      fontSize:
                                          16,

                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(
                                    height:
                                        5,
                                  ),

                                  Text(
                                    body,

                                    style:
                                        TextStyle(
                                      color:
                                          Colors
                                              .grey
                                              .shade700,
                                    ),
                                  ),

                                  const SizedBox(
                                    height:
                                        8,
                                  ),

                                  Text(
                                    data["created_at"]
                                            ?.toString() ??
                                        "",

                                    style:
                                        TextStyle(
                                      fontSize:
                                          12,

                                      color:
                                          Colors
                                              .grey,
                                    ),
                                  ),

                                ],
                              ),
                            ),

                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

        ],
      ),
    );
  }
}