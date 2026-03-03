import 'package:flutter/material.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/auth_dropdown.dart';
import '../../widgets/auth_button.dart';
import '../patient/patient_shell.dart';
import '../caregiver/caregiver_shell.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedRole;
  bool _isLoading = false;

  final List<String> _roles = ['Patient', 'Caregiver', 'Medical Practitioner'];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Simulate network request
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() => _isLoading = false);

        if (_selectedRole == 'Patient') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PatientShell()),
          );
        } else if (_selectedRole == 'Caregiver') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CaregiverShell()),
          );
        } else if (_selectedRole == 'Medical Practitioner') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Doctor Dashboard not implemented yet'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).iconTheme.color,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.favorite, size: 80, color: Colors.teal),
                  const SizedBox(height: 24),

                  const Text(
                    'Welcome Back',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to your Remedi account',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 48),

                  AuthDropdown<String>(
                    label: 'Login as',
                    value: _selectedRole,
                    prefixIcon: Icons.account_circle_outlined,
                    items: _roles
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedRole = val),
                    validator: (val) =>
                        val == null ? 'Please select a role' : null,
                  ),

                  AuthTextField(
                    label: 'Email / Username',
                    controller: _emailController,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),

                  AuthTextField(
                    label: 'Password',
                    controller: _passwordController,
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),

                  const SizedBox(height: 16),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Forgot Password
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(color: Colors.teal.shade700),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  AuthButton(
                    text: 'Sign In',
                    isLoading: _isLoading,
                    onPressed: _signIn,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
