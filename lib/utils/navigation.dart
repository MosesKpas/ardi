import 'package:ardi/screens/accueil.dart';
import 'package:ardi/screens/contact.dart';
import 'package:ardi/screens/message.dart';
import 'package:ardi/screens/profile.dart';
import 'package:ardi/screens/rdv.dart';
import 'package:flutter/material.dart';

class NavigationPage extends StatefulWidget {
  final int initialIndex;

  const NavigationPage({super.key, this.initialIndex = 0});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  List<Widget> _buildPages() {
    return [
      const AccueilPage(),
      const RendezVousPage(),
      const DossierPage(),
      const MessagesPage(),
      const ProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _buildPages(),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: const Color.fromRGBO(204, 20, 205, 100),
          indicatorColor: Colors.pink.shade900,
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
          ),
          iconTheme: WidgetStateProperty.all(
            const IconThemeData(color: Colors.white),
          ),
        ),
        child: NavigationBar(
          height: 80,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          selectedIndex: _currentIndex,
          onDestinationSelected: _onItemTapped,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              label: 'Accueil',
              selectedIcon: Icon(Icons.home),
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              label: 'Rdv',
              selectedIcon: Icon(Icons.calendar_month),
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_open_outlined),
              label: 'Dossier',
              selectedIcon: Icon(Icons.folder_open),
            ),
            NavigationDestination(
              icon: Icon(Icons.message_outlined),
              label: 'Message',
              selectedIcon: Icon(Icons.message),
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: 'Profil',
              selectedIcon: Icon(Icons.person),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
