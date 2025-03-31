import 'package:flutter/material.dart';
import 'loginPage.dart';
import 'signupPage.dart';

class GetStarted extends StatelessWidget {
  const GetStarted({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const Spacer(), // Push content to center
          // Top Illustration
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Image.asset(
              'assets/frontimage.png', // Ensure this image exists in assets
              width: 500,
              height: 650,
              fit: BoxFit.contain,
            ),
          ),

          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Discover Unique Handmade Creations",
              textAlign: TextAlign.left,
              style: TextStyle(
                fontFamily: 'Poppins', // Corrected font family name
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                height: 1, // Adjust the line height (default is ~1.3)
              ),
            ),
          ),

          // Subtitle
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Support local artisans and find exclusive, handcrafted products, all in one place.",
              textAlign: TextAlign.left,
              style: TextStyle(
                fontFamily: 'Poppins', // Applied Poppins font here
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),

          const SizedBox(height: 0),

          // "Continue" Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween, // Space buttons apart
              children: [
                // Left Button
                SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignupPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 41, 43, 65),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      "Signup",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Right Button
                SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(
                        255,
                        41,
                        43,
                        65,
                      ), // Dark blue button color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(), // Push button to bottom
        ],
      ),
    );
  }
}
