import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/db_remote_helper.dart';
import 'app_entry.dart';
import 'patient/patient_shell.dart';
import 'caregiver/caregiver_shell.dart';
import 'doctor/doctor_shell.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: DbRemoteHelper().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.teal)),
          );
        }

        final session = snapshot.data?.session;

        // If no user is logged in, show AppEntry screen
        if (session == null) {
          return const AppEntry();
        }

        // If logged in, route based on role metadata
        final role = session.user.userMetadata?['role'] as String?;

        if (role == 'patient') {
          return const PatientShell();
        } else if (role == 'caregiver') {
          return const CaregiverShell();
        } else if (role == 'doctor') {
          return const DoctorShell();
        }

        // Default / invalid role fallback
        return const AppEntry();
      },
    );
  }
}
