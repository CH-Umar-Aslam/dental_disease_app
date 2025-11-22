// import 'package:dental_disease_app/screens/auth/%20signup_screen.dart';
// import 'package:dental_disease_app/screens/dashboard/home_screen.dart';
// import 'package:flutter/material.dart';
// import './screens/auth/login_screen.dart';

// import './screens/dashboard/dashboard_screen.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Denta Vision',
//       debugShowCheckedModeBanner: false,
//       initialRoute: "/login",
//       routes: {
//         "/login": (context) => LoginScreen(),
//         "/signup": (context) => SignUpScreen(),
//         "/dashboard": (context) => DashboardScreen(),
//         "/home": (context) =>  const HomeScreen(),
//       },
//     );
//   }
// }

import 'package:dental_disease_app/screens/Reports/dentist_diagnosis.dart';
import 'package:dental_disease_app/screens/Reports/dentist_shared_diagnosis.dart';
import 'package:dental_disease_app/screens/Reports/patient_diagnosis.dart';
import 'package:dental_disease_app/screens/auth/%20signup_screen.dart';
import 'package:dental_disease_app/screens/dashboard/home_screen.dart';
import 'package:dental_disease_app/screens/diagnose/diagnose_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'services/api_client.dart';
import 'screens/auth/login_screen.dart';
// import 'package:flutter_web_plugins/flutter_web_plugins.dart';

// import your other screens...

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // setUrlStrategy(PathUrlStrategy()); // <--- ADD THIS

  await ApiClient.init();
  runApp(const MyApp());
}

final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/diagnosis',
      builder: (context, state) => const DiagnosisScreen(),
    ),
    GoRoute(
      path: '/patient-detections',
      builder: (context, state) => const PatientDiagnosisScreen(),
    ),
    GoRoute(
      path: '/dentist-detections',
      builder: (context, state) => const DentistSelfDiagnosisScreen(),
    ),
    GoRoute(
      path: '/dentist-shared-detections',
      builder: (context, state) => const DentistDiagnosisScreen(),
    ),
   
  ],
  redirect: (context, state) async {
    final token = await ApiClient.storage.read(key: 'access_token');
    final role = await ApiClient.storage.read(key: 'role');

    final isAuth = token != null;
    final isLoggingIn = state.uri.path == '/login';
    final isSignUp = state.uri.path == '/signup';

    // 1️⃣ Not authenticated → allow only login/signup
    if (!isAuth) {
      if (isLoggingIn || isSignUp) return null;
      return '/login';
    }

    // 2️⃣ Authenticated → block login/signup & redirect based on role
    if (isAuth && (isLoggingIn || isSignUp)) {
      if (role == 'patient') return '/home';
      if (role == 'dentist') return '/home';
      if (role == 'admin') return '/home';
      return '/login'; // fallback
    }

    // 3️⃣ Allow default behavior
    return null;
  },
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
        theme: ThemeData(
        primarySwatch: Colors.cyan,
        fontFamily: 'Roboto',
      ),
    );
  }
}

//
// import 'package:dental_disease_app/screens/dashboard/home_screen.dart';
// import 'package:flutter/material.dart';
// // import 'screens/home_screen.dart';
//
// void main() {
//   runApp( DentalApp());
// }
//
// class DentalApp extends StatelessWidget {
//   const DentalApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Denta Vision',
//       theme: ThemeData(
//         primarySwatch: Colors.cyan,
//         fontFamily: 'Roboto',
//       ),
//       home:  HomeScreen(),
//     );
//   }
// }
