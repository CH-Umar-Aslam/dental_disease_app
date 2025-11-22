import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api_client.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // For smaller screens
          if (constraints.maxWidth < 600) {
            return const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo
                Flexible(child: _LogoWidget(fontSize: 20)),

                // Profile Menu (Popup)
                _ProfileMenu(),
              ],
            );
          }

          // For larger screens
          return const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo
              const Flexible(child: _LogoWidget(fontSize: 24)),

              // Navigation
              Flexible(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _NavItem(title: "How it Works"),
                    const SizedBox(width: 16),
                    _NavItem(title: "Contact Us"),
                  ],
                ),
              ),

              // Profile Menu (Popup)
              const Flexible(child: _ProfileMenu()),
            ],
          );
        },
      ),
    );
  }
}

// --- Helper Widgets below ---

class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu();

  Future<void> _handleLogout(BuildContext context) async {
    await ApiClient.storage.delete(key: 'access_token');
    await ApiClient.storage.delete(key: 'role');
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    // 1. Use FutureBuilder to wait for the role
    return FutureBuilder<String?>(
      future: ApiClient.storage.read(key: 'role'),
      builder: (context, snapshot) {
        // If loading, show a simple icon or spinner
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final role = snapshot.data; // e.g., 'patient', 'dentist', 'admin'

        return PopupMenuButton<String>(
          icon: const Icon(Icons.account_circle, size: 30, color: Colors.cyan),
          tooltip: 'Account',
          offset: const Offset(0, 50),

          // 2. Handle Navigation Logic based on Role
          onSelected: (value) {
            if (value == 'logout') {
              _handleLogout(context);
            } else if (value == 'dashboard') {
              // Example: Send patients to one screen, dentists to another
              if (role == 'patient') {
                context.push('/patient-dashboard');
              } else {
                context.push('/dentist-dashboard');
              }
            }
            else if (value == 'my-diagnosis') {
              // Example: Send patients to one screen, dentists to another
              if (role == 'patient') {
                context.push('/patient-detections');
              } else {
                print("hit");
                context.push('/dentist-detections');
              }
            }
             else if (value == 'diagnose') {
              context.push('/diagnose');
            } else if (value == 'patient-diagnosis') {
              context.push('/dentist-shared-detections');
            }
          },

          // 3. Dynamically build the list based on the role
          itemBuilder: (BuildContext context) {
            List<PopupMenuEntry<String>> menuItems = [];

            // --- COMMON ITEMS (Everyone sees these) ---
            menuItems.add(const PopupMenuItem(
              value: 'dashboard',
              child: Row(children: [
                Icon(Icons.dashboard, color: Colors.black54),
                SizedBox(width: 10),
                Text('Dashboard')
              ]),
            ));

            // --- DENTIST ONLY ITEMS ---
            if (role != 'patient') {
              menuItems.add(const PopupMenuDivider());
              menuItems.add(const PopupMenuItem(
                value: 'patient-diagnosis',
                child: Row(children: [
                  Icon(Icons.people, color: Colors.black54),
                  SizedBox(width: 10),
                  Text('Patient Diagnosis') // Only Dentist sees this
                ]),
              ));
            }

            // --- PATIENT/COMMON ITEMS ---
            menuItems.add(const PopupMenuDivider());
            menuItems.add(
              const PopupMenuItem(
                value: 'my-diagnosis', 
                child: Row(
                  children: [
                    Icon(Icons.file_copy, color: Colors.black54),
                    SizedBox(width: 10),
                    Text('My Reports'),
                  ],
                ),
              ),
            );

            // --- LOGOUT (Always at the bottom) ---
            menuItems.add(const PopupMenuDivider());
            menuItems.add(const PopupMenuItem(
              value: 'logout',
              child: Row(children: [
                Icon(Icons.logout, color: Colors.redAccent),
                SizedBox(width: 10),
                Text('Logout', style: TextStyle(color: Colors.redAccent))
              ]),
            ));

            return menuItems;
          },
        );
      },
    );
  }
}

class _LogoWidget extends StatelessWidget {
  final double fontSize;
  const _LogoWidget({required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: "Denta",
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.cyan,
        ),
        children: const [
          TextSpan(
            text: "Vision",
            style: TextStyle(color: Color(0xFF0F172A)),
          )
        ],
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _NavItem extends StatelessWidget {
  final String title;
  const _NavItem({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF0F172A),
        fontWeight: FontWeight.w500,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}
