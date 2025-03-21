import 'package:ardi/animation/onboardingview.dart';
import 'package:ardi/screens/accueil.dart';
import 'package:ardi/screens/admin/admin.dart';
import 'package:ardi/screens/docteurs/docta.dart';
import 'package:ardi/utils/auth.dart';
import 'package:ardi/utils/navigation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplaschScrennPage extends StatefulWidget {
  const SplaschScrennPage({super.key});

  @override
  State<SplaschScrennPage> createState() => _SplaschScrennPageState();
}

class _SplaschScrennPageState extends State<SplaschScrennPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<Color?> _backgroundColorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    _backgroundColorAnimation = ColorTween(
      begin: Colors.black,
      end: Colors.white,
    ).animate(_animationController);

    _animationController.forward().whenComplete(() async {
      await _checkSessionAndRedirect();
    });
  }

  Future<void> _checkSessionAndRedirect() async {
    User? user = FirebaseAuth.instance.currentUser;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (user != null) {
      // Utilisateur connecté, vérifier son rôle
      String? role = await AuthService().getUserRole();
      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
        );
      } else if (role == 'docta') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DoctorDashboardPage()),
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const NavigationPage()),
          (Route<dynamic> route) => false,
        );
      }
    } else {
      if (hasSeenOnboarding) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const NavigationPage()),
          (Route<dynamic> route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const OnBoardingView()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _backgroundColorAnimation,
      builder: (context, child) {
        return Scaffold(
          body: Stack(
            children: [
              Container(
                color: _backgroundColorAnimation.value,
                child: Center(
                  child: Image.asset(
                    'assets/images/path33.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
