import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ItemDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;

  const ItemDetailScreen({
    super.key,
    required this.item,
  });

  Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case "FRESH":
        return Colors.green;

      case "USE_SOON":
        return Colors.orange;

      case "NEAR_EXPIRY":
        return Colors.amber;

      case "EXPIRED":
      case "SPOILED":
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  String getExpiryText() {
    int days = item["days_remaining"] ?? 0;

    if (days <= 0) {
      return "Expired";
    }

    return "$days day${days == 1 ? '' : 's'} remaining";
  }

  @override
  Widget build(BuildContext context) {
    final status = item["status"] ?? "Unknown";
    final color = getStatusColor(status);

    String expiryDate = "Unknown";

    try {
      if (item["expiry_date"] != null) {
        expiryDate = DateFormat("dd MMM yyyy")
            .format(DateTime.parse(item["expiry_date"]));
      }
    } catch (_) {}

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),

      appBar: AppBar(
        backgroundColor: const Color(0xff1B4332),
        foregroundColor: Colors.white,
        title: Text(item["name"] ?? "Food Item"),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            // IMAGE
            Container(
              height: 280,
              width: double.infinity,

              child: item["image_url"] != null
                  ? Image.network(
                      item["image_url"],
                      fit: BoxFit.cover,

                      errorBuilder: (_, __, ___) {
                        return Container(
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: Icon(
                              Icons.fastfood,
                              size: 90,
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Icon(
                          Icons.fastfood,
                          size: 90,
                        ),
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(
                    item["name"] ?? "Unknown Item",

                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),

                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius:
                          BorderRadius.circular(25),
                    ),

                    child: Text(
                      status,

                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    "Food Information",

                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Card(
                    elevation: 1,

                    child: Padding(
                      padding:
                          const EdgeInsets.all(16),

                      child: Column(
                        children: [

                          infoRow(
                            Icons.calendar_month,
                            "Expiry Date",
                            expiryDate,
                          ),

                          const Divider(),

                          infoRow(
                            Icons.timelapse,
                            "Remaining Life",
                            getExpiryText(),
                          ),

                          const Divider(),

                          infoRow(
                            Icons.label,
                            "Status",
                            status,
                          ),

                          const Divider(),

                          infoRow(
                            Icons.category,
                            "Item Type",
                            item["item_type"] ??
                                "Unknown",
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Freshness Indicator",

                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(18),

                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),

                      borderRadius:
                          BorderRadius.circular(18),
                    ),

                    child: Row(
                      children: [

                        Icon(
                          Icons.health_and_safety,
                          color: color,
                          size: 40,
                        ),

                        const SizedBox(width: 15),

                        Expanded(
                          child: Text(
                            status == "FRESH"
                                ? "Food is fresh and safe to consume."
                                : status ==
                                        "USE_SOON"
                                    ? "Use this item soon."
                                    : status ==
                                            "NEAR_EXPIRY"
                                        ? "Food is close to expiry."
                                        : "Food has expired or spoiled.",

                            style:
                                const TextStyle(
                              fontSize: 15,
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (item["days_remaining"] != null)

                    Center(
                      child: SizedBox(
                        width: 170,
                        height: 170,

                        child:
                            CircularProgressIndicator(
                          strokeWidth: 12,

                          value:
                              ((item["days_remaining"] ??
                                          0)
                                      .toDouble() /
                                  30)
                                  .clamp(0, 1),

                          color: color,
                          backgroundColor:
                              Colors.grey.shade300,
                        ),
                      ),
                    ),

                  const SizedBox(height: 25),

                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget infoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      children: [

        Icon(icon),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            title,

            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        Text(value),
      ],
    );
  }
}