import 'package:flutter/material.dart';
import 'auth/patient_signup_screen.dart';
import 'auth/caregiver_signup_screen.dart';
import 'auth/doctor_signup_screen.dart';
import 'auth/signin_screen.dart';

class AppEntry extends StatelessWidget {
  const AppEntry({super.key});

  void _showSignUpOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Create an Account',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.teal, size: 32),
                title: const Text('Patient'),
                subtitle: const Text('Manage your health effectively'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PatientSignupScreen(),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.favorite,
                  color: Colors.orange,
                  size: 32,
                ),
                title: const Text('Caregiver'),
                subtitle: const Text('Help manage a loved one\'s care'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CaregiverSignupScreen(),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.medical_services,
                  color: Colors.blue,
                  size: 32,
                ),
                title: const Text('Doctor'),
                subtitle: const Text('Provide remote medical care'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DoctorSignupScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            const Icon(Icons.favorite, size: 90, color: Colors.white),
            const SizedBox(height: 16),

            const Text(
              'Remedi',
              style: TextStyle(
                fontSize: 30,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),
            const Text(
              'Never miss your medication again',
              style: TextStyle(color: Colors.white70),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SigninScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.teal,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "Sign In",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: () => _showSignUpOptions(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                    child: const Text(
                      "Create an Account",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
