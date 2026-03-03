import 'package:flutter/material.dart';
import '../../database/db_remote_helper.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/auth_button.dart';

class DoctorSignupScreen extends StatefulWidget {
  const DoctorSignupScreen({super.key});

  @override
  State<DoctorSignupScreen> createState() => _DoctorSignupScreenState();
}

class _DoctorSignupScreenState extends State<DoctorSignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _specializationController = TextEditingController();
  final _licenseNumberController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _specializationController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await DbRemoteHelper().signUpDoctor(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          title: _titleController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          specialization: _specializationController.text.trim(),
          licenseNumber: _licenseNumberController.text.trim(),
          // organizationId: _organizationIdController.text.trim(), // Assuming an org ID input might exist later or is null for now
        );

        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification link sent to email')),
          );
          Navigator.pop(context);
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
        title: const Text('Doctor Registration'),
        elevation: 0,
        backgroundColor: Colors.blueGrey,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Join as a Practitioner',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Provide care and monitor patients remotely.',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),

                AuthTextField(
                  label: 'Title (e.g., Dr., Prof.)',
                  controller: _titleController,
                  prefixIcon: Icons.badge_outlined,
                ),

                Row(
                  children: [
                    Expanded(
                      child: AuthTextField(
                        label: 'First Name',
                        controller: _firstNameController,
                        prefixIcon: Icons.person_outline,
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AuthTextField(
                        label: 'Last Name',
                        controller: _lastNameController,
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),

                AuthTextField(
                  label: 'Email',
                  controller: _emailController,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) => val == null || !val.contains('@')
                      ? 'Enter valid email'
                      : null,
                ),

                AuthTextField(
                  label: 'Password',
                  controller: _passwordController,
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  validator: (val) =>
                      val != null && val.length < 6 ? 'Min 6 chars' : null,
                ),

                AuthTextField(
                  label: 'Specialization',
                  controller: _specializationController,
                  prefixIcon: Icons.local_hospital_outlined,
                ),

                AuthTextField(
                  label: 'License Number',
                  controller: _licenseNumberController,
                  prefixIcon: Icons.verified_user_outlined,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),

                const SizedBox(height: 24),

                AuthButton(
                  text: 'Sign Up as Doctor',
                  isLoading: _isLoading,
                  onPressed: _signUp,
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
