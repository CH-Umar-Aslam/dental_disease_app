import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_client.dart';

class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({super.key});

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  // State variables matching React logic
  String? selectedImageType; // 'intraoral' or 'xray'
  XFile? selectedFile;
  String? fileName;
  String? resultImage;
  Map<String, dynamic>? diagnosisResults; // Stores the report_card data
  bool isLoading = false;
  String? error;
  String? userRole;

  final ImagePicker _picker = ImagePicker();

  // Mapping endpoints logic
  final Map<String, String> apiEndpoints = {
    'intraoral': "/ai/predict-intraoral",
    'xray': "/ai/predict-xray",
  };

  // --- Logic Methods ---

  void handleImageSelect(String type) {
    setState(() {
      selectedImageType = type;
      // Reset file-related states when type changes
      selectedFile = null;
      fileName = null;
      resultImage = null;
      diagnosisResults = null;
      error = null;
    });
  }

  Future<void> pickImage(ImageSource source) async {
    if (selectedImageType == null) {
      setState(() => error = "Please select an image type first (Step 1).");
      return;
    }

    final XFile? file = await _picker.pickImage(source: source);
    if (file != null) {
      setState(() {
        selectedFile = file;
        fileName = file.name;
        error = null;
      });
    }
  }

  void reset() {
    setState(() {
      selectedImageType = null;
      selectedFile = null;
      fileName = null;
      resultImage = null;
      diagnosisResults = null;
      error = null;
      isLoading = false;

    });
  }

  Future<void> analyze() async {
    if (selectedImageType == null) {
      setState(() => error = "Please select an image type first.");
      return;
    }
    if (selectedFile == null) {
      setState(() => error = "Please upload a file first.");
      return;
    }

    setState(() {
      isLoading = true;
      error = null;
      resultImage = null;
      diagnosisResults = null;
    });

    try {
      // Get User ID
      final userFullString = await ApiClient.storage.read(key: 'user');
      String? patientId;
      if (userFullString != null) {
        final userMap = jsonDecode(userFullString);
        patientId = userMap["id"]?.toString();
        setState(() {
          userRole = userMap["role"]; 
        });
      }



      final file = File(selectedFile!.path);
      
      // Determine Endpoint based on selection
      final String endpoint = apiEndpoints[selectedImageType]!;

      final formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          file.path,
          filename: fileName ?? "image.jpg",
        ),
        "patient_id": patientId ?? "anonymous",
      });

      final res = await ApiClient.dio.post(endpoint, data: formData);

      // Handle Response
      if (res.data["annotated_image"] != null) {
        setState(() {
          resultImage = res.data["annotated_image"];
          // Capture the report card data matching React structure
          diagnosisResults = res.data["report_card"]; 
        });
      } else {
        setState(() => error = "No annotated image received from server.");
      }
    } catch (e) {
      print("Analysis error: $e");
      setState(() => error = "Failed to analyze image. Please try again.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // --- UI Builder Methods ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Matches React bg-gradient logic
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/home'),
        ),
        title: const Text(
          "Diagnose Disease",
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.w600, fontSize: 20),
        ),
        actions: [
          TextButton(
            onPressed: reset,
            child: const Text("Reset All",
                style: TextStyle(
                    color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Error Banner
            if (error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  border: Border.all(color: const Color(0xFFFECACA)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(error!,
                          style: const TextStyle(
                              color: Colors.red, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),

            // Step 1: Selection
         // Step 1: Selection
            _buildSectionHeader("Step 1: Select Image Type"),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSelectionCard(
                    "intraoral", 
                    "Intraoral", 
                    "assets/select_intraoral_images.jpg" // <--- Your Asset Path
                  )
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSelectionCard(
                    "xray", 
                    "X-Ray", 
                    "assets/xray_select_image.jpg" // <--- Your Asset Path
                  )
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Step 2: Upload (Only visual if type selected)
            _buildSectionHeader("Step 2: Upload & Analyze"),
            const SizedBox(height: 12),
            Opacity(
              opacity: selectedImageType == null ? 0.5 : 1.0,
              child: IgnorePointer(
                ignoring: selectedImageType == null,
                child: _buildUploadSection(),
              ),
            ),
            const SizedBox(height: 24),

            // Step 3: Results
            _buildSectionHeader("Step 3: Results"),
            const SizedBox(height: 12),
            _buildResultSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1F2937),
      ),
    );
  }

  // --- Step 1 Widgets ---
  Widget _buildSelectionCard(String type, String title, String imagePath) {
    final isSelected = selectedImageType == type;
    return GestureDetector(
      onTap: () => handleImageSelect(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            width: isSelected ? 3 : 1,
            color: isSelected ? Colors.cyan : Colors.grey.shade200,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: Colors.cyan.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Column(
          children: [
            // Image Container
            Container(
              height: 100, // Adjusted height for better visibility
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.hardEdge, // Ensures image doesn't bleed out
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover, // Behaves like object-cover in React
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.image_not_supported,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isSelected
                    ? Colors.cyan
                    : const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              type == 'intraoral'
                  ? "Clinical photograph"
                  : "Radiographic image",
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }

  // --- Step 2 Widgets ---
  Widget _buildUploadSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Dashed Box Appearance
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.cyan, style: BorderStyle.solid), // Simulating dashed with solid light blue
              ),
              child: Column(
                children: [
                   const Icon(Icons.cloud_upload, size: 40, color: Colors.cyan),
                   const SizedBox(height: 8),
                   Text(
                     selectedFile != null ? "Change Image" : "Upload $selectedImageType",
                     style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF374151)),
                   ),
                   const SizedBox(height: 12),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       ElevatedButton.icon(
                         onPressed: () => pickImage(ImageSource.camera),
                         icon: const Icon(Icons.camera_alt, size: 16),
                         label: const Text("Camera"),
                         style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                       ),
                       const SizedBox(width: 8),
                       ElevatedButton.icon(
                         onPressed: () => pickImage(ImageSource.gallery),
                         icon: const Icon(Icons.photo_library, size: 16),
                         label: const Text("Gallery"),
                         style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                       ),
                     ],
                   )
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // File Preview & Analyze Button
            if (selectedFile != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text("Selected: $fileName", 
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : analyze,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("Analyze Image", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Step 3 Widgets (The Advanced React Report Card) ---
  Widget _buildResultSection() {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Column(
          children: const [
            CircularProgressIndicator(color: Color(0xFF2563EB)),
            SizedBox(height: 16),
            Text("Processing your image...", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (resultImage == null || diagnosisResults == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: const [
            Icon(Icons.description_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text("Results will appear here after analysis", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // Parse Data safely
    final String status = diagnosisResults?['status'] ?? "Unknown";
    final String severity = diagnosisResults?['severity'] ?? "None";
    final int issuesCount = diagnosisResults?['total_issues'] ?? 0;
    final String diagnosisId = diagnosisResults?['diagnosis_id'] ?? "PENDING";
    final double confidence = diagnosisResults?['average_confidence'] ?? 0.0;
    final List<dynamic> recommendations = diagnosisResults?['recommendations'] ?? [];

    // --- Build The Main Report Card ---
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 1. Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("📋 AI Diagnosis Report", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text("ID: ${diagnosisId.length > 8 ? diagnosisId.substring(0, 8) : diagnosisId}",
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const Divider(height: 1),

          // 2. Image Display (with Confidence Badge Overlay)
          Container(
            color: Colors.black, // React uses bg-gray-900
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 300),
            child: Stack(
              alignment: Alignment.center,
              children: [
                resultImage!.startsWith("http")
                  ? Image.network(resultImage!, fit: BoxFit.contain)
                  : Image.memory(base64Decode(resultImage!.split(",").last), fit: BoxFit.contain),
                
                // Confidence Badge
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      "AI Confidence: ${(confidence * 100).round()}%",
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Clinical Data
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grid for Metrics
                Row(
                  children: [
                    Expanded(child: _buildMetricBadge("Status", status, 
                      status.toLowerCase().contains("healthy") ? Colors.green : Colors.amber)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildMetricBadge("Severity", severity,
                      severity == "High" ? Colors.red : (severity == "Medium" ? Colors.orange : Colors.blue))),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Detected Issues", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(text: "$issuesCount ", style: const TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
                            const TextSpan(text: "anomalies found", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 30),

                // 4. Recommendations
               if (userRole != 'dentist') ...[
                   const Text("👨‍⚕️ Dentist Remarks & Recommendations", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF374151))),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (recommendations.isNotEmpty)
                        ...recommendations.map((rec) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 6.0),
                                child: Icon(Icons.circle, size: 6, color: Colors.blue),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(rec.toString(), style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4))),
                            ],
                          ),
                        ))
                      else
                        const Text("No specific remarks generated.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                      
                      const SizedBox(height: 12),
                      const Divider(color: Color(0xFFDBEAFE)),
                      const SizedBox(height: 8),
                      const Text(
                        "* These remarks are AI-generated based on visual analysis. Please verify with clinical examination.",
                        style: TextStyle(fontSize: 11, color: Color(0xFF60A5FA)),
                      )
                    ],
                  ),
                ),
               
                // 5. Action Button (Like React 'Get Remarks')
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.push('/patient-detections'); 
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:Colors.cyan, // slate-800
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Get Dentist Remarks", style: TextStyle(color: Colors.white)),
                  ),
                )
               ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(color: color.withOpacity(1.0), fontWeight: FontWeight.bold, fontSize: 12),
            ),
          )
        ],
      ),
    );
  }
}