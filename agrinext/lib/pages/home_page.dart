import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'news_feed_page.dart';
import 'farm_finder_page.dart';
import 'marketplace_page.dart';
import 'job_board_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String? _avatarUrl;

  static const Color primaryColor = Color(0xFF4CAF50);
  static const Color backgroundColor = Color(0xFFF1F8E9);

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _initializeScreens();
    _loadUserProfile();
  }

  void _initializeScreens() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    _screens.addAll([
      const NewsFeedPage(),
      const FarmFinderPage(),
      const MarketplacePage(),
      const JobBoardPage(),
      ProfilePage(userId: currentUserId), // ✅ FIXED: pass userId here
    ]);
  }

  Future<void> _loadUserProfile() async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user != null) {
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('avatar_url')
        .eq('id', user.id)
        .single();

    final avatarPath = profile['avatar_url'];
    if (mounted) {
      setState(() {
        _avatarUrl = avatarPath != null && avatarPath.isNotEmpty
            ? Supabase.instance.client.storage.from('avatars').getPublicUrl(avatarPath)
            : null;
      });
    }
  }
}


  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        height: 70,
        backgroundColor: Colors.white,
        indicatorColor: primaryColor.withOpacity(0.1),
        animationDuration: const Duration(milliseconds: 300),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.feed_outlined),
            selectedIcon: Icon(Icons.feed, color: primaryColor),
            label: 'News Feed',
          ),
          const NavigationDestination(
            icon: Icon(Icons.agriculture_outlined),
            selectedIcon: Icon(Icons.agriculture, color: primaryColor),
            label: 'Farms',
          ),
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront, color: primaryColor),
            label: 'Market',
          ),
          const NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work, color: primaryColor),
            label: 'Jobs',
          ),
          NavigationDestination(
            icon: _avatarUrl != null
                ? CircleAvatar(radius: 12, backgroundImage: NetworkImage(_avatarUrl!))
                : const Icon(Icons.person_outline),
            selectedIcon: _avatarUrl != null
                ? CircleAvatar(radius: 14, backgroundImage: NetworkImage(_avatarUrl!))
                : const Icon(Icons.person, color: primaryColor),
            label: 'You',
          ),
        ],
      ),
    );
  }
}

