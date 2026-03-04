import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/auth_dropdown.dart';
import '../../widgets/auth_button.dart';
import '../../database/db_remote_helper.dart';

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

      try {
        final AuthResponse res = await Supabase.instance.client.auth
            .signInWithPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );

        if (mounted) {
          setState(() => _isLoading = false);

          if (res.user != null) {
            final userId = res.user!.id;
            final dbHelper = DbRemoteHelper();

            // Verify the user exists in the correct table based on their selected role
            final isValidRole = await dbHelper.verifyUserRole(
              userId,
              _selectedRole!,
            );

            if (!mounted) return;

            if (isValidRole) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Account type mismatch or user not found. Please select the correct role.',
                  ),
                ),
              );
              await dbHelper.signOut();
            }
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
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
