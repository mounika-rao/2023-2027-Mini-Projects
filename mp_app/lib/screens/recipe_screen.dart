import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});

  @override
  State<RecipeScreen> createState() =>
      _RecipeScreenState();
}

class _RecipeScreenState
    extends State<RecipeScreen> {

  final Set<String> selectedItems = {};

  bool loading = false;

  String recipeResult = "";

  // CHANGE THIS TO YOUR PC IP
 final String apiBase =
    "http://10.168.12.204:8000";

  Future<void> generateRecipes() async {

    if (selectedItems.isEmpty) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Select at least one ingredient",
          ),
        ),
      );

      return;
    }

    setState(() {
      loading = true;
    });

    try {

      final response = await http.post(
        Uri.parse(
          "$apiBase/recipes",
        ),

        headers: {
          "Content-Type":
              "application/json",
        },

        body: jsonEncode({
          "ingredients":
              selectedItems.toList(),
        }),
      );

      if (response.statusCode == 200) {

        final data =
            jsonDecode(response.body);

        setState(() {

          recipeResult =
              data["recipes"]
                  .toString();

        });

      } else {

        setState(() {
          recipeResult =
              "Unable to fetch recipes";
        });

      }

    } catch (e) {

      setState(() {
        recipeResult = e.toString();
      });

    }

    setState(() {
      loading = false;
    });
  }

  Color statusColor(String status) {

    switch (
        status.toUpperCase()) {

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

        title: const Text(
          "Recipe Suggestions",
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
                  Colors.green.shade50,

              borderRadius:
                  BorderRadius.circular(
                18,
              ),
            ),

            child: const Text(
              "Select available ingredients and generate recipes using Gemini AI.",
              style: TextStyle(
                fontSize: 15,
              ),
            ),
          ),

          Expanded(
            flex: 2,

            child: StreamBuilder<
                QuerySnapshot>(
              stream:
                  FirebaseFirestore
                      .instance
                      .collection(
                        "items",
                      )
                      .where(
                        "status",
                        whereIn: [
                          "FRESH",
                          "USE_SOON",
                          "NEAR_EXPIRY"
                        ],
                      )
                      .snapshots(),

              builder:
                  (context, snapshot) {

                if (!snapshot.hasData) {

                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );

                }

                final docs =
                    snapshot.data!.docs;

                if (docs.isEmpty) {

                  return const Center(
                    child: Text(
                      "No ingredients available",
                    ),
                  );

                }

                return ListView.builder(

                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 16,
                  ),

                  itemCount:
                      docs.length,

                  itemBuilder:
                      (context, index) {

                    final item =
                        docs[index]
                                .data()
                            as Map<
                                String,
                                dynamic>;

                    final name =
                        item["name"] ??
                            "Unknown";

                    final selected =
                        selectedItems
                            .contains(
                                name);

                    return Card(
  margin: const EdgeInsets.only(
    bottom: 10,
  ),

  child: ListTile(

    leading:
        item["image_url"] != null

            ? ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  8,
                ),

                child:
                    Image.network(

                  item["image_url"],

                  width: 60,
                  height: 60,

                  fit:
                      BoxFit.cover,

                  errorBuilder:
                      (
                    _,
                    __,
                    ___,
                  ) {

                    return const Icon(
                      Icons
                          .image_not_supported,
                    );
                  },
                ),
              )

            : const Icon(
                Icons.fastfood,
                size: 40,
              ),

    title: Text(
      name,
    ),

    subtitle: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        Text(
          item["status"] ??
              "",
        ),

        if (item[
                "days_remaining"] !=
            null)

          Text(
            "Expires in ${item["days_remaining"]} days",
          ),
      ],
    ),

    trailing:
        Checkbox(

      value:
          selected,

      onChanged:
          (value) {

        setState(() {

          if (value ==
              true) {

            selectedItems
                .add(
              name,
            );

          } else {

            selectedItems
                .remove(
              name,
            );
          }

        });
      },
    ),
  ),
);

          Expanded(
            flex: 2,

            child: Container(

              width:
                  double.infinity,

              margin:
                  const EdgeInsets
                      .fromLTRB(
                16,
                0,
                16,
                16,
              ),

              padding:
                  const EdgeInsets
                      .all(16),

              decoration:
                  BoxDecoration(
                color:
                    Colors.white,

                borderRadius:
                    BorderRadius
                        .circular(
                  18,
                ),

                boxShadow: [

                  BoxShadow(
                    color: Colors
                        .black
                        .withOpacity(
                      0.05,
                    ),

                    blurRadius:
                        8,
                  )

                ],
              ),

              child:
                  SingleChildScrollView(

                child: Text(

                  recipeResult.isEmpty
                      ? "Generated recipes will appear here..."
                      : recipeResult,

                  style:
                      const TextStyle(
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}