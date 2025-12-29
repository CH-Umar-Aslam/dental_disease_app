import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
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

  // 1. The Logic to open the browser
  Future<void> _launchWebDashboard() async {
    // REPLACE WITH YOUR ACTUAL WEB URL
    final Uri url =
        Uri.parse('https://dental-disease-diagnosis.vercel.app');

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      debugPrint("Error launching URL: $e");
    }
  }

  // 2. The "Cool" Bottom Sheet UI
  void _showWebRedirect(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Decorative Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Icon with decorative background
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.cyan.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.laptop_mac_rounded,
                  size: 48, color: Colors.cyan),
            ),
            const SizedBox(height: 20),

            // Text Content
            const Text(
              "Visit Web Dashboard",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Access advanced analytics, detailed reports, and full administrative features via our secure web portal.",
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 30),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close sheet
                  _launchWebDashboard(); // Open Browser
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A), // Dark Slate
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Launch Web Portal",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.open_in_new, size: 18),
                  ],
                ),
              ),
            ),

            // Cancel Button
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Maybe Later",
                style:
                    TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await ApiClient.storage.delete(key: 'access_token');
    await ApiClient.storage.delete(key: 'role');
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: ApiClient.storage.read(key: 'role'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final role = snapshot.data;

        return PopupMenuButton<String>(
          icon: const Icon(Icons.account_circle, size: 30, color: Colors.cyan),
          tooltip: 'Account',
          offset: const Offset(0, 50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            if (value == 'logout') {
              _handleLogout(context);
            } else if (value == 'dashboard') {
              // --- TRIGGER THE COOL SHEET HERE ---
              _showWebRedirect(context);
            } else if (value == 'my-diagnosis') {
              if (role == 'patient') {
                context.push('/patient-detections');
              } else {
                context.push('/dentist-detections');
              }
            } else if (value == 'diagnose') {
              context.push('/diagnose');
            } else if (value == 'patient-diagnosis') {
              context.push('/dentist-shared-detections');
            }
          },
          itemBuilder: (BuildContext context) {
            List<PopupMenuEntry<String>> menuItems = [];

            // --- COMMON ITEMS ---
            menuItems.add(const PopupMenuItem(
              value: 'dashboard',
              child: Row(children: [
                // Added a small visual cue that this is external
                Icon(Icons.dashboard_customize_outlined, color: Colors.black54),
                SizedBox(width: 10),
                Text('Web Dashboard'),
                Spacer(),
                Icon(Icons.open_in_new, size: 14, color: Colors.grey)
              ]),
            ));

            // --- DENTIST ONLY ITEMS ---
            if (role != 'patient') {
              menuItems.add(const PopupMenuDivider());
              menuItems.add(const PopupMenuItem(
                value: 'patient-diagnosis',
                child: Row(children: [
                  Icon(Icons.people_alt_outlined, color: Colors.black54),
                  SizedBox(width: 10),
                  Text('Patient Diagnosis')
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
                    Icon(Icons.folder_shared_outlined, color: Colors.black54),
                    SizedBox(width: 10),
                    Text('My Diagnosis'),
                  ],
                ),
              ),
            );

            // --- LOGOUT ---
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
