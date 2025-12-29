import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:photo_view/photo_view.dart';
import '../../services/api_client.dart';

// --- MODEL CLASS ---
class DiagnosisReport {
  final String id; // <-- CHANGED TO STRING (UUID)
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
      // Just convert to String, do NOT parse as int
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
}

class PatientDiagnosisScreen extends StatefulWidget {
  const PatientDiagnosisScreen({super.key});
  @override
  State<PatientDiagnosisScreen> createState() => _PatientDiagnosisScreenState();
}

class _PatientDiagnosisScreenState extends State<PatientDiagnosisScreen> {
  List<DiagnosisReport> reports = [];
  bool isLoading = true;
  String statusFilter = "all";
  String? currentUserId; // <-- CHANGED TO STRING
  

  final Map<String, String> statusOptions = {
    "all": "All",
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
          // Just use toString() for UUIDs
          currentUserId = userMap["id"].toString();
        }
      }

      if (currentUserId == null)
        throw Exception("User not logged in or ID missing");

      // 2. Build URL
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

  // IDs are now Strings
  Future<void> _shareWithDentist(String diagnosisId, String dentistId) async {
    try {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Sharing..."), duration: Duration(seconds: 1)),
      );

      await ApiClient.dio.post("/ai/share-diagnosis", data: {
        "diagnosis_id": diagnosisId,
        "dentist_id": dentistId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Shared successfully!"),
            backgroundColor: Colors.green),
      );

      _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Failed to share."), backgroundColor: Colors.red),
      );
    }
  }

  // --- DIALOGS ---
  // Pass String ID
  void _openDentistSelectionDialog(String diagnosisId) {
    showDialog(
      context: context,
      builder: (context) => _DentistSelectionDialog(
        onSelect: (dentistId) => _shareWithDentist(diagnosisId, dentistId),
      ),
    );
  }

  void _openRemarksDialog(String diagnosisId) {
    showDialog(
      context: context,
      builder: (context) => _RemarksDialog(diagnosisId: diagnosisId),
    );
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
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text("Diagnosis",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold,fontSize: 14)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
         titleSpacing: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: statusFilter,
                icon: const Icon(Icons.filter_list, color: Colors.blue),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => statusFilter = newValue);
                    _fetchData();
                  }
                },
                items: statusOptions.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child:
                        Text(entry.value, style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
              ),
            ),
          )
        ],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dateStr,
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 12)),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _openFullScreenImage(report.imageUrl),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(report.imageUrl),
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
            const SizedBox(height: 16),
            if (statusLower == 'diagnosed')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text("Share with Dentist"),
                  onPressed: () => _openDentistSelectionDialog(report.id),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.blue),
                ),
              ),
            if (statusLower == 'reviewed')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.medical_services, size: 18),
                  label: const Text("View Remarks"),
                  onPressed: () => _openRemarksDialog(report.id),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- HELPER WIDGET: DENTIST SELECTION ---

class _DentistSelectionDialog extends StatefulWidget {
  final Function(String) onSelect; // ID passed as String
  const _DentistSelectionDialog({required this.onSelect});

  @override
  State<_DentistSelectionDialog> createState() =>
      _DentistSelectionDialogState();
}

class _DentistSelectionDialogState extends State<_DentistSelectionDialog> {
  List<Map<String, dynamic>> dentists = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchDentists();
  }

  Future<void> _fetchDentists() async {
    try {
      final res = await ApiClient.dio.get('/verified-dentists');

      // 1. Safely get the list
      List<dynamic> rawDentists = res.data['users'] ?? [];

      // 2. Fetch counts in parallel
      final List<Map<String, dynamic>> dentistsWithCount = await Future.wait(
        rawDentists.map((dentist) async {
          // FORCE CAST the incoming dentist object to Map<String, dynamic>
          final Map<String, dynamic> dentistMap =
              Map<String, dynamic>.from(dentist as Map);

          try {
            final dentistId = dentistMap['id'].toString();

            final diagRes = await ApiClient.dio.get(
              '/ai/dentist-shared-diagnosis/?dentist_id=$dentistId&status=closed',
            );

            final count = (diagRes.data as List).length;

            // Return explicitly as <String, dynamic>
            return <String, dynamic>{
              ...dentistMap,
              'closedCount': count,
            };
          } catch (e) {
            // Return explicitly as <String, dynamic>
            return <String, dynamic>{
              ...dentistMap,
              'closedCount': '-',
            };
          }
        }),
      );

      if (mounted) {
        setState(() {
          // Direct assignment now works because types match
          dentists = dentistsWithCount;
        });
      }
    } catch (e) {
      print("Error fetching dentists: $e");
      if (mounted) {
        setState(() => dentists = []);
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Select Dentist to Share Diagnosis"),
      content: SizedBox(
        width: double.maxFinite,
        height: 400, // Increased height to accommodate more info
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : dentists.isEmpty
                ? const Center(child: Text("No dentists found"))
                : ListView.builder(
                    itemCount: dentists.length,
                    itemBuilder: (context, index) {
                      final dentist = dentists[index];
                      final dentistId = dentist['id'].toString();

                      // Handle potential nulls
                      final name = "${dentist['name'] ?? ''}".trim();
                      final email = dentist['email'] ?? 'No email';
                      final specialization = dentist['specialization'] ?? 'N/A';
                      final experience = dentist['years_of_experience'];
                      final closedCount = dentist['closedCount'];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Left Side: Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name.isEmpty ? 'Unknown Name' : name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    email,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "$specialization — ${experience != null ? '$experience yrs' : 'No info'}",
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                      children: [
                                        const TextSpan(
                                            text: "Closed Diagnoses: "),
                                        TextSpan(
                                          text: "$closedCount",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Right Side: Share Button
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => widget.onSelect(dentistId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF0891B2), // Cyan-600 approx
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                minimumSize: const Size(60, 36),
                              ),
                              child: const Text("Share"),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel")),
      ],
    );
  }
}

// --- HELPER WIDGET: REMARKS DIALOG ---
class _RemarksDialog extends StatefulWidget {
  final String diagnosisId;

  const _RemarksDialog({required this.diagnosisId});

  @override
  State<_RemarksDialog> createState() => _RemarksDialogState();
}

class _RemarksDialogState extends State<_RemarksDialog> {
  bool loading = true;
  String? remarks;
  String? dentistName;
  String? status;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSharedDiagnosisDetails();
  }

  Future<void> _fetchSharedDiagnosisDetails() async {
    try {
      // API Call matching your React code:
      // /ai/get-shared-diagnosis?diagnosis_id=...
      final res = await ApiClient.dio.get(
        '/ai/get-shared-diagnosis',
        queryParameters: {'diagnosis_id': widget.diagnosisId},
      );

      if (res.statusCode == 200) {
        // React logic: const item = res.data?.[0] ?? null;
        List<dynamic> dataList = res.data;

        if (dataList.isNotEmpty) {
          final item = dataList[0];

          // Extract Dentist Name if available in the nested object
          String dName = "Unknown Dentist";
          if (item['dentist'] != null) {
            dName =
                "${item['dentist']['name']}"; 
          }

          if (mounted) {
            setState(() {
              remarks = item['remarks'];
              status = item['status'];
              dentistName = dName;
              loading = false;
            });
          }
        } else {
          _setError("No shared details found.");
        }
      }
    } catch (e) {
      _setError("Failed to load remarks.");
    }
  }

  void _setError(String msg) {
    if (mounted) {
      setState(() {
        errorMessage = msg;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Dentist's Remarks"),
      content: SizedBox(
        width: double.maxFinite,
        child: loading
            ? const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              )
            : errorMessage != null
                ? Text(errorMessage!, style: const TextStyle(color: Colors.red))
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dentist Info Header
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.purple,
                            child: Icon(Icons.medical_services,
                                size: 16, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Text(
                              //   dentistName ?? "Dentist",
                              //   style: const TextStyle(
                              //       fontWeight: FontWeight.bold, fontSize: 14),
                              // ),
                              Text(
                                "Status: ${status ?? 'Unknown'}",
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      const Text(
                        "Professional Remarks:",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),

                      // The Remarks Text
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          (remarks != null && remarks!.isNotEmpty)
                              ? remarks!
                              : "No remarks provided yet.",
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                      ),
                    ],
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        )
      ],
    );
  }
}
