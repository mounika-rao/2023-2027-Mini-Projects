import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/recipe_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {

  int currentIndex = 0;

  final pages = const [
    DashboardScreen(),
    AlertsScreen(),
    RecipeScreen(),
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: pages[currentIndex],

      bottomNavigationBar: NavigationBar(

        selectedIndex: currentIndex,

        onDestinationSelected: (index) {

          setState(() {
            currentIndex = index;
          });

        },

        destinations: const [

          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: "Pantry",
          ),

          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: "Alerts",
          ),

          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: "Recipes",
          ),

        ],
      ),
    );
  }
}