import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../utils/toast.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _showPassword = false;

  bool _isLoading = false;

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.saveAndValidate()) return;

    final data = _formKey.currentState!.value;
    final email = data['email'] as String;
    final password = data['password'] as String;

    print('data $data email $email password $password');

    setState(() => _isLoading = true);

    try {
      // 1. Login → get token + basic user
      final user = await AuthService.login(email, password);

      // 2. Fetch full user from /me
      // final me = await AuthService.getMe();

      // SAFELY extract role
      // final role = (user!['role'] != null)
      //     ? user['role'].toString()
      //     : (user['role'] != null)
      //         ? user['role'].toString()
      //         : 'patient';

      showToast("Login successful!", isError: false);

      // 3. Navigate based on role
      final router = GoRouter.of(context);
      router.go('/home');

      // if (role == 'patient') {
      //   router.go('/patient/diagnosis');
      // } else if (role == 'dentist') {
      //   router.go('/dentist/dashboard');
      // } else if (role == 'admin') {
      //   router.go('/admin/blogs');
      // } else {
      //   router.go('/');
      // }
    } catch (e) {
      showToast(e.toString(), isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: screenWidth > 800
          ? Row(
              children: [
                Expanded(
                  child: Image.asset("assets/login-img.jpg", fit: BoxFit.cover),
                ),
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
          width: 400,
          child: FormBuilder(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                SvgPicture.asset(
                  "assets/LOGO.svg",
                  height: 30,
                ),
                const SizedBox(height: 20),
                Text(
                  "Nice to see you again",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 22),

                // Email
                const Text("Login", style: TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                FormBuilderTextField(
                  name: 'email',
                  decoration: InputDecoration(
                    hintText: "Email or phone number",
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                        errorText: "Email or phone is required"),
                  ]),
                ),
                const SizedBox(height: 16),

                // Password
                const Text("Password", style: TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                FormBuilderTextField(
                  name: 'password',
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    hintText: "Enter password",
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(_showPassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  validator: FormBuilderValidators.required(
                      errorText: "Password is required"),
                ),
                const SizedBox(height: 16),

                // Remember + Forgot
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     TextButton(
                //       onPressed: () {},
                //       child: const Text("Forgot password?",
                //           style: TextStyle(color: Colors.cyan)),
                //     ),
                //   ],
                // ),
                // const SizedBox(height: 16),

                // Submit
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isLoading ? null : _onSubmit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text("Sign in",
                            style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 24),

                // Divider
                const Row(children: [
                  Expanded(child: Divider(color: Colors.grey)),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text("OR")),
                  Expanded(child: Divider(color: Colors.grey)),
                ]),
                const SizedBox(height: 16),

                // Signup
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/signup'),
                    child: const Text(
                      "Don't have an account? Sign up",
                      style: TextStyle(color: Colors.cyan),
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
}
