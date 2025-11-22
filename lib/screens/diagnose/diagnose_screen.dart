import 'dart:convert';
import 'dart:io'; // <-- yeh rakhna zaroori hai mobile ke liye

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // web check ke liye
import '../../services/api_client.dart';
import 'package:go_router/go_router.dart';

class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({super.key});

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  XFile? selectedFile;
  String? fileName;
  String? resultImage;
  bool isLoading = false;
  String? error;

  final ImagePicker _picker = ImagePicker();

  Future<void> pickFromGallery() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        selectedFile = file;
        fileName = file.name;
        error = null;
      });
    }
  }

  Future<void> pickFromCamera() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.camera);
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
      selectedFile = null;
      fileName = null;
      resultImage = null;
      error = null;
      isLoading = false;
    });
  }

  Future<void> analyze() async {
    if (selectedFile == null) {
      setState(() => error = "Please upload an image first");
      return;
    }

    setState(() {
      isLoading = true;
      error = null;
      resultImage = null;
    });

    try {
      // User ID extract karo
      final userFullString = await ApiClient.storage.read(key: 'user');
      String? patientId;
      if (userFullString != null) {
        final userMap = jsonDecode(userFullString);
        patientId = userMap["id"]?.toString();
      }

      // Mobile pe sirf File path se MultipartFile banega
      final file = File(selectedFile!.path);

      final formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          file.path,
          filename: fileName ?? "image.jpg",
        ),
        "patient_id": patientId,
      });

      final res = await ApiClient.dio.post("/ai/predict-xray", data: formData);

      if (res.data["annotated_image"] != null) {
        setState(() => resultImage = res.data["annotated_image"]);
      } else {
        setState(() => error = "No result image from server");
      }
    } catch (e) {
      print("Upload error: $e");
      setState(() => error = "Failed to connect to server");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/home'), // navigate explicitly
        ),
        title: const Text(
          "Diagnose Disease",
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.w600, fontSize: 20),
        ),
        actions: [
          TextButton(
            onPressed: reset,
            child: const Text("Reset",
                style: TextStyle(
                    color: Color(0xFF2563EB), fontWeight: FontWeight.w500)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Upload Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Upload Image",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("Capture from Camera"),
                        onPressed: pickFromCamera,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        label: const Text("Choose from Gallery"),
                        onPressed: pickFromGallery,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: selectedFile != null
                          ? Column(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Color(0xFF16A34A), size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  "Selected: $fileName",
                                  style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : analyze,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB),
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: Colors.grey,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text("Analyze Now",
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                Icon(Icons.image_not_supported,
                                    color: Colors.grey.shade400, size: 60),
                                const SizedBox(height: 12),
                                Text(
                                  "No image selected",
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Error Card
            if (error != null)
              Card(
                elevation: 1,
                color: const Color(0xFFFEE2E2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFDC2626), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          error!,
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Result Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Results",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: isLoading
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF2563EB)),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Processing your image...",
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14),
                                ),
                              ],
                            )
                          : resultImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: resultImage!.startsWith("http")
                                      ? Image.network(resultImage!,
                                          fit: BoxFit.cover)
                                      : Image.memory(
                                          base64Decode(
                                              resultImage!.split(",").last),
                                          fit: BoxFit.cover,
                                        ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image_not_supported,
                                        color: Colors.grey.shade400, size: 48),
                                    const SizedBox(height: 12),
                                    Text(
                                      "Results will appear here\nafter analysis",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 14),
                                    ),
                                  ],
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
