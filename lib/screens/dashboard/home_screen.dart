import 'package:dental_disease_app/widgets/%20how_it_works.dart';
import 'package:dental_disease_app/widgets/header.dart';
import 'package:dental_disease_app/widgets/hero_section.dart';
import 'package:flutter/material.dart';
// import '../widgets/header.dart';
// import '../widgets/hero_section.dart';
// import '../widgets/how_it_works.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: const SingleChildScrollView(
        child: Column(
          children: [
            Header(),
            HeroSection(),
            HowItWorks(),
          ],
        ),
      ),
    );
  }
}
