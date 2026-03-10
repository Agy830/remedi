import 'package:flutter/material.dart';
import '../../database/db_remote_helper.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/auth_dropdown.dart';
import '../../widgets/auth_button.dart';
import 'package:intl/intl.dart';

class PatientSignupScreen extends StatefulWidget {
  const PatientSignupScreen({super.key});

  @override
  State<PatientSignupScreen> createState() => _PatientSignupScreenState();
}

class _PatientSignupScreenState extends State<PatientSignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _allergiesController = TextEditingController();

  String? _selectedGender;
  String? _selectedBloodGroup;
  String? _selectedGenotype;
  bool _isLoading = false;

  final List<String> _genders = ['Male', 'Female'];
  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];
  final List<String> _genotypes = ['AA', 'AS', 'SS', 'AC', 'SC'];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: Colors.teal,
                    onPrimary: Colors.white,
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Colors.teal,
                    onPrimary: Colors.white,
                    onSurface: Colors.black,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final allergiesList = _allergiesController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        await DbRemoteHelper().signUpPatient(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phone: _phoneController.text.trim(),
          dob: _dobController.text,
          gender: _selectedGender,
          bloodGroup: _selectedBloodGroup,
          genotype: _selectedGenotype,
          weightKg: double.tryParse(_weightController.text.trim()),
          heightCm: double.tryParse(_heightController.text.trim()),
          allergies: allergiesList.isNotEmpty ? allergiesList : null,
        );

        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification link sent to email')),
          );
          Navigator.pop(context); // Go back to entry or login
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
      appBar: AppBar(title: const Text('Patient Registration'), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create your account',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join Remedi to manage your health effortlessly.',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),

                // Name Fields
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
                  label: 'Phone Number',
                  controller: _phoneController,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),

                AuthTextField(
                  label: 'Date of Birth',
                  controller: _dobController,
                  prefixIcon: Icons.calendar_today,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),

                AuthDropdown<String>(
                  label: 'Gender',
                  value: _selectedGender,
                  prefixIcon: Icons.people_outline,
                  items: _genders
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedGender = val),
                  validator: (val) => val == null ? 'Required' : null,
                ),

                Row(
                  children: [
                    Expanded(
                      child: AuthDropdown<String>(
                        label: 'Blood Group',
                        value: _selectedBloodGroup,
                        items: _bloodGroups
                            .map(
                              (g) => DropdownMenuItem(value: g, child: Text(g)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedBloodGroup = val),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AuthDropdown<String>(
                        label: 'Genotype',
                        value: _selectedGenotype,
                        items: _genotypes
                            .map(
                              (g) => DropdownMenuItem(value: g, child: Text(g)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedGenotype = val),
                      ),
                    ),
                  ],
                ),

                Row(
                  children: [
                    Expanded(
                      child: AuthTextField(
                        label: 'Weight (kg)',
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AuthTextField(
                        label: 'Height (cm)',
                        controller: _heightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),

                AuthTextField(
                  label: 'Allergies (Comma separated)',
                  controller: _allergiesController,
                  prefixIcon: Icons.warning_amber_rounded,
                ),

                const SizedBox(height: 24),

                AuthButton(
                  text: 'Sign Up as Patient',
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
