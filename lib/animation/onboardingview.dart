import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:ardi/animation/onboardingitems.dart';
import 'package:ardi/utils/navigation.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnBoardingView extends StatefulWidget {
  const OnBoardingView({super.key});

  @override
  State<OnBoardingView> createState() => _OnBoardingViewState();
}

class _OnBoardingViewState extends State<OnBoardingView> {
  final controller = Onboardingitems();
  final pageController = PageController();
  bool isLastPage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: const BoxDecoration(
          color: Colors.white, // Couleur blanche pour la simplicité
          border: Border(
            top: BorderSide(color: Color.fromRGBO(204, 20, 205, 100), width: 0.5), // Bordure subtile
          ),
        ),
        child: isLastPage
            ? _commencerButton()
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Bouton Sauter
                  TextButton(
                    onPressed: () =>
                        pageController.jumpToPage(controller.items.length - 1),
                    child: const Text(
                      "Sauter",
                      style: TextStyle(
                        color: Color.fromRGBO(204, 20, 205, 100),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  // Indicateur de page
                  SmoothPageIndicator(
                    controller: pageController,
                    count: controller.items.length,
                    effect: const ExpandingDotsEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      activeDotColor: Color.fromRGBO(204, 20, 205, 100),
                      dotColor: Colors.grey,
                    ),
                  ),

                  // Bouton Suivant
                  TextButton(
                    onPressed: () => pageController.nextPage(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOut,
                    ),
                    child: const Text(
                      "Suivant",
                      style: TextStyle(
                        color: Color.fromRGBO(204, 20, 205, 100),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
      ),
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: PageView.builder(
          onPageChanged: (index) => setState(() {
            isLastPage = controller.items.length - 1 == index;
          }),
          itemCount: controller.items.length,
          controller: pageController,
          itemBuilder: (context, index) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animation Lottie
                SizedBox(
                  height: 250, // Taille réduite pour un design plus minimaliste
                  child: Lottie.asset(controller.items[index].image,
                      fit: BoxFit.contain),
                ),
                const SizedBox(height: 40),
                // Titre avec un design minimaliste et pro
                Text(
                  controller.items[index].titre,
                  style: const TextStyle(
                    fontSize:
                        24, // Taille de police réduite pour plus d'élégance
                    fontWeight: FontWeight.bold,
                    color: Colors.black87, // Couleur subtile pour un look pro
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                // Description avec une meilleure lisibilité
                Text(
                  controller.items[index].descriptions,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors
                        .black54, // Texte légèrement foncé pour un ton doux
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _commencerButton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(204, 20, 205, 100),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      width: double.infinity,
      height: 55,
      child: TextButton(
        onPressed: () async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool(
              'hasSeenOnboarding', true); // Enregistrez la session

          Navigator.pushReplacement(
            // ignore: use_build_context_synchronously
            context,
            MaterialPageRoute(builder: (context) => const NavigationPage()),
          );
        },
        child: const Text(
          "Commencer",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
