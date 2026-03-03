import 'package:supabase_flutter/supabase_flutter.dart';

class DbRemoteHelper {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Verify if a user exists in the specified role table
  Future<bool> verifyUserRole(String userId, String expectedRole) async {
    String tableName;

    switch (expectedRole) {
      case 'Patient':
        tableName = 'patients';
        break;
      case 'Caregiver':
        tableName = 'caregivers';
        break;
      case 'Medical Practitioner':
        tableName = 'medical_practitioners';
        break;
      default:
        return false;
    }

    try {
      final response = await _supabase
          .from(tableName)
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Shared helper to handle sign up or update existing user metadata
  Future<AuthResponse> _handleSignUp({
    required String email,
    required String password,
    required Map<String, dynamic> data,
  }) async {
    try {
      // 1. First, attempt to sign in to check if the user already exists.
      // Supabase's signUp doesn't throw "already exists" errors when email protection is on.
      final signInRes = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (signInRes.session != null) {
        // User exists and provided correct password. Update their metadata.
        final updateRes = await _supabase.auth.updateUser(
          UserAttributes(data: data),
        );
        return AuthResponse(
          session: signInRes.session,
          user: updateRes.user ?? signInRes.user,
        );
      }
    } on AuthException {
      // Sign in failed (user doesn't exist, unconfirmed email, or wrong password).
      // We safely fall through to signUp.
    }

    // 2. Proceed with normal sign up
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  // Sign up a patient
  Future<AuthResponse> signUpPatient({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phone,
    String? dob, // Expected yyyy-MM-dd
    String? gender, // 'Male' or 'Female'
    String? bloodGroup, // e.g., 'A+'
    String? genotype, // e.g., 'AA'
    double? weightKg,
    double? heightCm,
    List<String>? allergies,
  }) async {
    return await _handleSignUp(
      email: email,
      password: password,
      data: {
        'role': 'patient',
        // Patient Specific Meta Data
        'firstname': firstName,
        'lastname': lastName,
        'phone_number': phone,
        'date_of_birth': dob != null
            ? '${dob}T00:00:00Z'
            : null, // Convert to timestamptz format
        'gender': gender,
        'blood_group': bloodGroup,
        'genotype': genotype,
        'weight_kg': weightKg,
        'height_cm': heightCm,
        'allergies': allergies,

        // Explicitly set caregiver and doctor fields to null
        'relationship': null,
        'can_edit_medications': null,
        'title': null,
        'specialization': null,
        'license_number': null,
        'organization_id': null,
      },
    );
  }

  // Sign up a caregiver
  Future<AuthResponse> signUpCaregiver({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    return await _handleSignUp(
      email: email,
      password: password,
      data: {
        'role': 'caregiver',
        // Caregiver Meta Data (using common fields where they overlap conceptually or simply storing in metadata)
        'firstname': firstName,
        'lastname': lastName,
        'phone_number': phone,

        // Depending on your trigger, caregiver name might just be extracted.

        // Explicitly nullify patient/doctor fields
        'date_of_birth': null,
        'gender': null,
        'blood_group': null,
        'genotype': null,
        'weight_kg': null,
        'height_cm': null,
        'allergies': null,
        'title': null,
        'specialization': null,
        'license_number': null,
        'organization_id': null,
      },
    );
  }

  // Sign up a doctor (medical practitioner)
  Future<AuthResponse> signUpDoctor({
    required String email,
    required String password,
    String? title,
    String? firstName,
    String? lastName,
    String? specialization,
    String? licenseNumber,
    String? organizationId,
  }) async {
    return await _handleSignUp(
      email: email,
      password: password,
      data: {
        'role': 'medical_practitioner',
        // Doctor Meta Data
        'title': title,
        'firstname': firstName,
        'lastname': lastName,
        'specialization': specialization,
        'license_number': licenseNumber,
        'organization_id': organizationId,

        // Explicitly nullify patient/caregiver fields
        'phone_number': null,
        'date_of_birth': null,
        'gender': null,
        'blood_group': null,
        'genotype': null,
        'weight_kg': null,
        'height_cm': null,
        'allergies': null,
        'relationship': null,
        'can_edit_medications': null,
      },
    );
  }

  // Sign out the current user
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
