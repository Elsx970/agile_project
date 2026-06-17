import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/aspiration_provider.dart';
import '../aspiration/aspiration_list_screen.dart';
import '../aspiration/aspiration_create_screen.dart';
import '../profile/profile_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Fetch aspirations once user logs in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      Provider.of<AspirationProvider>(context, listen: false)
          .fetchAspirations(auth.currentUser?.token);
    });
  }

  // Define screens based on role
  List<Widget> _getScreens(bool isAdmin) {
    return [
      const AspirationListScreen(),
      isAdmin ? const AdminDashboardScreen() : const AspirationCreateScreen(),
      const ProfileScreen(),
    ];
  }

  List<BottomNavigationBarItem> _getNavItems(bool isAdmin) {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.campaign_outlined),
        activeIcon: Icon(Icons.campaign),
        label: 'Aspirasi',
      ),
      BottomNavigationBarItem(
        icon: isAdmin ? const Icon(Icons.dashboard_customize_outlined) : const Icon(Icons.add_circle_outline),
        activeIcon: isAdmin ? const Icon(Icons.dashboard_customize) : const Icon(Icons.add_circle),
        label: isAdmin ? 'Dashboard' : 'Kirim',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profil',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isAdmin = auth.isAdmin;
    final screens = _getScreens(isAdmin);
    final navItems = _getNavItems(isAdmin);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: navItems,
              selectedItemColor: AppTheme.primaryColor,
              unselectedItemColor: Colors.grey.shade400,
              backgroundColor: Colors.white,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }
}
