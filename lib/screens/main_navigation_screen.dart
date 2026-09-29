import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mesh_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import 'chat_screen.dart';
import 'neighbors_screen.dart';
import 'status_screen.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MeshProvider>();
    final currentTab = provider.currentTab;

    return Scaffold(
      body: IndexedStack(
        index: currentTab,
        children: const [
          ChatScreen(),
          NeighborsScreen(),
          StatusScreen(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        activeIndex: currentTab,
        onTabSelected: (index) => provider.setTab(index),
      ),
    );
  }
}
