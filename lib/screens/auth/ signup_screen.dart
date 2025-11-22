import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
// Adjust these imports to match your project structure
import '../../services/auth_service.dart';
import '../../utils/toast.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  
  // State to handle visibility
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;
  
  // State to track selected role for conditional rendering
  String? _selectedRole;

  Future<void> _onSubmit() async {
    // 1. Validate Form
    if (!_formKey.currentState!.saveAndValidate()) {
      showToast("Please fix the errors in red", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Get Data
      // FormBuilder gives us a Map<String, dynamic>
      final formData = Map<String, dynamic>.from(_formKey.currentState!.value);
      
      // 3. Data Transformation (if specific types are needed by backend)
      // Example: Convert years_of_experience to int if it's a string
      if (formData['years_of_experience'] != null) {
        formData['years_of_experience'] = int.parse(formData['years_of_experience'].toString());
      }

      // 4. API Call
      // Assuming you add a signup method to your AuthService
      await AuthService.signup(formData);

      showToast("Account created successfully!", isError: false);

      // 5. Navigate to Login
      if (mounted) {
        context.go('/login');
      }

    } catch (e) {
      print('meror $e');
      // Handle API errors (e.g., "Email already exists")
      showToast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: screenWidth > 800
          ? Row(
              children: [
                // Left Side Image
                Expanded(
                  child: Image.asset(
                    "assets/login-img.jpg", // Ensure you have this asset
                    fit: BoxFit.cover,
                    height: double.infinity,
                  ),
                ),
                // Right Side Form
                Expanded(child: _buildForm()),
              ],
            )
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 500, // Slightly wider for signup form
          child: FormBuilder(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              
              children: [
                const SizedBox(height: 30),
                // Header
              
                    SvgPicture.asset(
                    "assets/LOGO.svg",
                    height: 30,
                  ),
              
                const SizedBox(height: 5),
                Text(
                  "Welcome to Denta Vision!",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 14),

                // --- Name ---
                _buildLabel("Name"),
                FormBuilderTextField(
                  name: 'name',
                  decoration: _inputDecoration("Enter your name"),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.minLength(2, errorText: "Name must be at least 2 characters"),
                  ]),
                ),
                const SizedBox(height: 16),

                // --- Email ---
                _buildLabel("Email"),
                FormBuilderTextField(
                  name: 'email',
                  decoration: _inputDecoration("Enter your Email"),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.email(errorText: "Invalid email address"),
                  ]),
                ),
                const SizedBox(height: 16),

                // --- Phone Number ---
                _buildLabel("Phone Number"),
                FormBuilderTextField(
                  name: 'phone_number',
                  decoration: _inputDecoration("03XXXXXXXXX"),
                  keyboardType: TextInputType.phone,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.match(
                      r'^03[0-9]{9}$', 
                      errorText: "Please enter a valid Pakistani mobile number (03XXXXXXXXX)"
                    ),
                  ]),
                ),
                const SizedBox(height: 16),

                // --- Role (Triggers Conditional Logic) ---
                _buildLabel("Role"),
                FormBuilderDropdown<String>(
                  name: 'role',
                  decoration: _inputDecoration("Select Role"),
                  validator: FormBuilderValidators.required(),
                  items: const [
                    DropdownMenuItem(value: 'patient', child: Text('Patient')),
                    DropdownMenuItem(value: 'dentist', child: Text('Dentist')),
                  ],
                  onChanged: (value) {
                    // Update state to trigger rebuild for conditional fields
                    setState(() {
                      _selectedRole = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // --- DENTIST ONLY FIELDS ---
                if (_selectedRole == 'dentist') ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // City
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             _buildLabel("City"),
                            FormBuilderDropdown<String>(
                              name: 'city',
                              decoration: _inputDecoration("Select City"),
                              validator: FormBuilderValidators.required(),
                              items: ['Karachi', 'Lahore', 'Islamabad', 'Rawalpindi', 'Faisalabad', 'Multan', 'Peshawar', 'Quetta', 'Other']
                                  .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Experience
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             _buildLabel("Experience (Years)"),
                            FormBuilderTextField(
                              name: 'years_of_experience',
                              decoration: _inputDecoration("Years"),
                              keyboardType: TextInputType.number,
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(),
                                FormBuilderValidators.numeric(),
                                FormBuilderValidators.min(0),
                                FormBuilderValidators.max(50),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Specialization
                  _buildLabel("Specialization"),
                  FormBuilderDropdown<String>(
                    name: 'specialization',
                    decoration: _inputDecoration("Select Specialization"),
                    validator: FormBuilderValidators.required(),
                    items: [
                      'General Dentistry', 'Orthodontics', 'Periodontics', 'Endodontics', 
                      'Oral Surgery', 'Prosthodontics', 'Pediatric Dentistry', 
                      'Oral Pathology', 'Cosmetic Dentistry', 'Implantology'
                    ].map((spec) => DropdownMenuItem(value: spec, child: Text(spec))).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // --- Password ---
                _buildLabel("Password"),
                FormBuilderTextField(
                  name: 'password',
                  obscureText: !_showPassword,
                  decoration: _inputDecoration("Enter password").copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.minLength(8),
                    // Regex for: Upper, Lower, Number
                    FormBuilderValidators.match(
                      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)', 
                      errorText: "Must contain uppercase, lowercase and number"
                    ),
                  ]),
                ),
                const SizedBox(height: 16),

                // --- Confirm Password ---
                _buildLabel("Confirm Password"),
                FormBuilderTextField(
                  name: 'confirm_password',
                  obscureText: !_showConfirmPassword,
                  decoration: _inputDecoration("Re-Enter password").copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_showConfirmPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please confirm your password';
                    // Access the password field value using the form key
                    final password = _formKey.currentState?.fields['password']?.value;
                    if (value != password) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // --- Submit Button ---
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isLoading ? null : _onSubmit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text("Sign up", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),

                // --- Login Link ---
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text.rich(
                      TextSpan(
                        text: "Already have an account? ",
                        style: TextStyle(color: Colors.black87),
                        children: [
                          TextSpan(
                            text: "Sign in",
                            style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper for Label Text
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  // Helper for Input Decoration
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade200,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      errorMaxLines: 3, // Allow error text to wrap
    );
  }
}
