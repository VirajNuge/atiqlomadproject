import 'package:flutter/material.dart';
import 'getStarted.dart';

class FrontPage extends StatelessWidget {
  const FrontPage({super.key});

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
            child: Align(
              alignment: Alignment.centerRight, // Aligns button to the right
              child: SizedBox(
                width: 100,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GetStarted(),
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
                      borderRadius: BorderRadius.circular(25), // Rounded button
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                    ), // Adjust padding
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(
                      fontFamily: 'Poppins', // Ensure font consistency
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const Spacer(), // Push button to bottom
        ],
      ),
    );
  }
}
