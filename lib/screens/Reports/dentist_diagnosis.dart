import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:photo_view/photo_view.dart';
import '../../services/api_client.dart';

// --- MODEL CLASS ---
class DiagnosisReport {
  final String id;
  final String? result;
  final String createdAt;
  final String imageUrl;
  final String status;

  DiagnosisReport({
    required this.id,
    this.result,
    required this.createdAt,
    required this.imageUrl,
    required this.status,
  });

  factory DiagnosisReport.fromJson(Map<String, dynamic> json) {
    return DiagnosisReport(
      id: json['id'].toString(),
      result: json['result'],
      createdAt: json['created_at'],
      imageUrl: json['image_url'],
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> get parsedResult {
    if (result == null || result!.isEmpty) return {};
    try {
      return jsonDecode(result!);
    } catch (e) {
      return {};
    }
  }

  // Emulator Fix: Replace localhost with 10.0.2.2 for Android
  String get displayImageUrl {
    if (imageUrl.contains('127.0.0.1')) {
      return imageUrl.replaceAll('127.0.0.1', '10.0.2.2');
    }
    return imageUrl;
  }
}

class DentistSelfDiagnosisScreen extends StatefulWidget {
  const DentistSelfDiagnosisScreen({super.key});

  @override
  State<DentistSelfDiagnosisScreen> createState() => _DentistSelfDiagnosisScreenState();
}

class _DentistSelfDiagnosisScreenState extends State<DentistSelfDiagnosisScreen> {
  List<DiagnosisReport> reports = [];
  bool isLoading = true;
  String statusFilter = "all";
  String? currentUserId;

  final Map<String, String> statusOptions = {
    "all": "All Statuses",
    "pending": "Pending",
    "diagnosed": "Diagnosed",
    "reviewed": "Reviewed",
  };

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // --- API LOGIC ---
  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    try {
      // 1. Get User ID from Storage
      final userFullString = await ApiClient.storage.read(key: 'user');

      if (userFullString != null) {
        final userMap = jsonDecode(userFullString);
        if (userMap["id"] != null) {
          currentUserId = userMap["id"].toString();
        }
      }

      if (currentUserId == null) {
        throw Exception("User not logged in or ID missing");
      }

      // 2. Build URL (Patient Filter API)
      String url = "/ai/filter-patient-diagnosis/?patient_id=$currentUserId";
      if (statusFilter != "all") {
        url += "&status=$statusFilter";
      }

      // 3. Call API
      final res = await ApiClient.dio.get(url);

      if (res.statusCode == 200) {
        List<dynamic> data = res.data;
        setState(() {
          reports = data.map((json) => DiagnosisReport.fromJson(json)).toList();
        });
      }
    } catch (e) {
      print("Error fetching data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Failed to fetch data: $e"),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _openFullScreenImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white)),
          body: PhotoView(
            imageProvider: imageUrl.startsWith("http")
                ? NetworkImage(imageUrl)
                : MemoryImage(
                    base64Decode(imageUrl.split(",").last),
                  ) as ImageProvider,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if we can go back
    final canGoBack = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text("Diagnoses",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold,
            fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        
        // --- CRITICAL FIX START ---
        // Only show the back button if there is history in the stack
        leading: canGoBack 
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            )
          : null, // If null, Flutter automatically hides it or shows a Drawer icon
        // --- CRITICAL FIX END ---

        // actions: [
        //   Padding(
        //     padding: const EdgeInsets.only(right: 16.0),
        //     child: DropdownButtonHideUnderline(
        //       child: DropdownButton<String>(
        //         value: statusFilter,
        //         icon: const Icon(Icons.filter_list, color: Colors.blue),
        //         onChanged: (String? newValue) {
        //           if (newValue != null) {
        //             setState(() => statusFilter = newValue);
        //             _fetchData();
        //           }
        //         },
        //         items: statusOptions.entries.map((entry) {
        //           return DropdownMenuItem<String>(
        //             value: entry.key,
        //             child:
        //                 Text(entry.value, style: const TextStyle(fontSize: 14)),
        //           );
        //         }).toList(),
        //       ),
        //     ),
        //   )
        // ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reports.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      return _buildReportCard(reports[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text("No reports found",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildReportCard(DiagnosisReport report) {
    final parsed = report.parsedResult;
    String dateStr;
    try {
      dateStr =
          DateFormat('dd MMM yyyy').format(DateTime.parse(report.createdAt));
    } catch (e) {
      dateStr = "Unknown Date";
    }

    final statusLower = report.status.toLowerCase();

    Color statusColor;
    switch (statusLower) {
      case 'diagnosed':
        statusColor = Colors.green;
        break;
      case 'reviewed':
        statusColor = Colors.purple;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Date Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dateStr,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    report.status.toUpperCase(),
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10),
                  ),
                )
              ],
            ),
            const Divider(height: 24),
            
            // Image and Details Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _openFullScreenImage(report.displayImageUrl),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(report.displayImageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: const Center(
                        child: Icon(Icons.zoom_in, color: Colors.white70)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Issues Found: ${parsed['total_issues'] ?? 0}",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("Severity: ${parsed['severity'] ?? 'Unknown'}",
                          style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                          "Recs: ${(parsed['recommendations'] as List?)?.take(1).join(', ') ?? 'None'}...",
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade700),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}