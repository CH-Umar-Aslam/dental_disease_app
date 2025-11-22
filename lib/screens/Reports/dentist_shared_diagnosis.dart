import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:photo_view/photo_view.dart';
import '../../services/api_client.dart';

// --- MODEL CLASS ---
class DentistSharedReport {
  final String id; // This is the Shared Record ID
  final String status; // 'pending' or 'closed'
  final String createdAt;
  final String? remarks;

  // Nested Objects
  final Map<String, dynamic> diagnosis;
  final Map<String, dynamic> patient;

  DentistSharedReport({
    required this.id,
    required this.status,
    required this.createdAt,
    this.remarks,
    required this.diagnosis,
    required this.patient,
  });

  factory DentistSharedReport.fromJson(Map<String, dynamic> json) {
    return DentistSharedReport(
      id: json['id'].toString(),
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'],
      remarks: json['remarks'],
      diagnosis: json['diagnosis'] ?? {},
      patient: json['patient'] ?? {},
    );
  }

  // Helper to parse the inner diagnosis result JSON
  Map<String, dynamic> get parsedResult {
    final res = diagnosis['result'];
    if (res == null || res.toString().isEmpty) return {};
    try {
      return jsonDecode(res);
    } catch (e) {
      return {};
    }
  }

  // Image URL Helper for Emulator
  String get displayImageUrl {
    final url = diagnosis['image_url'] ?? '';
    if (url.contains('127.0.0.1')) {
      return url.replaceAll('127.0.0.1', '10.0.2.2');
    }
    return url;
  }
}

class DentistDiagnosisScreen extends StatefulWidget {
  const DentistDiagnosisScreen({super.key});

  @override
  State<DentistDiagnosisScreen> createState() => _DentistDiagnosisScreenState();
}

class _DentistDiagnosisScreenState extends State<DentistDiagnosisScreen> {
  List<DentistSharedReport> reports = [];
  bool isLoading = true;
  String statusFilter = "all";
  String? currentDentistId;

  final Map<String, String> statusOptions = {
    "all": "All",
    "pending": "Pending",
    "closed": "Closed",
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
      // 1. Get User ID
      final userFullString = await ApiClient.storage.read(key: 'user');
      if (userFullString != null) {
        final userMap = jsonDecode(userFullString);
        currentDentistId = userMap["id"].toString();
      }

      if (currentDentistId == null) throw Exception("Dentist ID missing");

      // 2. Build URL
      // Endpoint: /ai/dentist-shared-diagnosis/?dentist_id=...
      String url = "/ai/dentist-shared-diagnosis/?dentist_id=$currentDentistId";
      if (statusFilter != "all") {
        url += "&status=$statusFilter";
      }

      // 3. Call API
      final res = await ApiClient.dio.get(url);

      if (res.statusCode == 200) {
        List<dynamic> data = res.data;
        setState(() {
          reports =
              data.map((json) => DentistSharedReport.fromJson(json)).toList();
        });
      }
    } catch (e) {
      print("Error fetching dentist diagnosis: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // --- ACTIONS ---
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
                : MemoryImage(base64Decode(imageUrl.split(",").last))
                    as ImageProvider,
          ),
        ),
      ),
    );
  }

  // Open Dialog for Adding or Viewing Remarks
  void _openRemarksDialog(String diagnosisId, String action) {
    // Note: We pass the diagnosisId (nested ID) to match React logic,
    // The dialog will fetch the specific shared record.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DentistRemarksDialog(
        diagnosisId: diagnosisId, // Pass inner diagnosis ID
        action: action, // 'add' or 'view'
        onSuccess: _fetchData, // Refresh list after save
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text("Patient Reports",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold,
            fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16,left: 16),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: statusFilter,
                icon: const Icon(Icons.filter_list, color: Colors.cyan),
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
                        Text(entry.value, style: const TextStyle(fontSize: 12)),
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
          Icon(Icons.assignment_ind, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text("No shared reports found",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildReportCard(DentistSharedReport report) {
    final parsed = report.parsedResult;
    String dateStr;
    try {
      dateStr =
          DateFormat('dd MMM yyyy').format(DateTime.parse(report.createdAt));
    } catch (e) {
      dateStr = "Unknown Date";
    }

    final statusLower = report.status.toLowerCase();
    final patientName =
        "${report.patient['first_name'] ?? 'Patient'} ${report.patient['last_name'] ?? ''}";

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Patient Name & Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.cyan,
                      child: Icon(Icons.person, size: 14, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(patientName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                Text(dateStr,
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
            const Divider(height: 24),

            // Content
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Thumbnail
                GestureDetector(
                  onTap: () => _openFullScreenImage(report.displayImageUrl),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade200,
                      image: report.displayImageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(report.displayImageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: report.displayImageUrl.isEmpty
                        ? const Icon(Icons.broken_image, color: Colors.grey)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Issues: ${parsed['total_issues'] ?? 0}",
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text("Severity: ${parsed['severity'] ?? 'N/A'}",
                          style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        "Recs: ${(parsed['recommendations'] as List?)?.take(1).join(', ') ?? 'None'}...",
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action Buttons based on Status
            if (statusLower == 'pending')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: const Text("Add Remarks"),
                  onPressed: () => _openRemarksDialog(
                      report.diagnosis['id'].toString(), 'add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            if (statusLower == 'closed')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text("View Remarks"),
                  onPressed: () => _openRemarksDialog(
                      report.diagnosis['id'].toString(), 'view'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.cyan),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- HELPER: DENTIST REMARKS DIALOG (Read & Write) ---
class _DentistRemarksDialog extends StatefulWidget {
  final String diagnosisId;
  final String action; // 'add' or 'view'
  final VoidCallback onSuccess;

  const _DentistRemarksDialog({
    required this.diagnosisId,
    required this.action,
    required this.onSuccess,
  });

  @override
  State<_DentistRemarksDialog> createState() => _DentistRemarksDialogState();
}

class _DentistRemarksDialogState extends State<_DentistRemarksDialog> {
  bool loading = true;
  bool saving = false;
  String? sharedRecordId; // Needed for PATCH request
  String? existingRemarks;
  String? errorMessage;

  // Controller for input
  final TextEditingController _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  // Fetch the shared record to get ID and existing remarks
  Future<void> _fetchDetails() async {
    try {
      final res = await ApiClient.dio.get(
        '/ai/get-shared-diagnosis',
        queryParameters: {'diagnosis_id': widget.diagnosisId},
      );

      if (res.statusCode == 200 && (res.data as List).isNotEmpty) {
        final item = res.data[0];

        if (mounted) {
          setState(() {
            sharedRecordId = item['id'].toString();
            existingRemarks = item['remarks'];
            _remarksController.text = existingRemarks ?? "";
            loading = false;
          });
        }
      } else {
        _setError("Record not found.");
      }
    } catch (e) {
      _setError("Failed to load details.");
    }
  }

  void _setError(String msg) {
    if (mounted)
      setState(() {
        errorMessage = msg;
        loading = false;
      });
  }

  Future<void> _handleSave() async {
    if (sharedRecordId == null) return;
    if (_remarksController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter remarks before saving.")),
      );
      return;
    }

    setState(() => saving = true);

    try {
      // PATCH /ai/remarks-shared-diagnosis/{id}
      // Payload: { remarks: "...", status: "closed" }
      await ApiClient.dio.patch(
        '/ai/remarks-shared-diagnosis/$sharedRecordId',
        data: {
          "remarks": _remarksController.text.trim(),
          "status": "closed",
        },
      );

      if (mounted) {
        Navigator.pop(context); // Close Dialog
        widget.onSuccess(); // Refresh Parent List
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Remarks saved successfully!"),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print("Save Error: $e");
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Failed to save remarks."),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.action == 'add';

    return AlertDialog(
      title: Text(isEditMode ? "Add Remarks" : "Dentist Remarks"),
      content: SizedBox(
        width: double.maxFinite,
        child: loading
            ? const SizedBox(
                height: 100, child: Center(child: CircularProgressIndicator()))
            : errorMessage != null
                ? Text(errorMessage!, style: const TextStyle(color: Colors.red))
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isEditMode)
                        TextField(
                          controller: _remarksController,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            hintText: "Enter your professional assessment...",
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            existingRemarks ?? "No remarks provided.",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                    ],
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        if (isEditMode && errorMessage == null)
          ElevatedButton(
            onPressed: saving ? null : _handleSave,
            style: ElevatedButton.styleFrom(backgroundColor:Colors.cyan),
            child: saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text("Save & Close Case"),
          ),
      ],
    );
  }
}
