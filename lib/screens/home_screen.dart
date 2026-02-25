import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import 'camera_screen.dart';
import 'map_view_screen.dart';
import 'gallery_screen.dart';
import 'settings_screen.dart';
import '../services/ad_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final AdService _adService = AdService();

  final List<Widget> _screens = [
    const CameraScreen(),
    const MapViewScreen(),
    const GalleryScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 3 && _currentIndex != 3) {
            _adService.showInterstitialAd();
          }
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
