import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../repositories/medication_repository.dart';
import '../database/db_helper.dart';
import '../models/medication.dart';

part 'providers.g.dart';

// --- Dependencies ---

@riverpod
DBHelper dbHelper(DbHelperRef ref) {
  return DBHelper();
}

@riverpod
MedicationRepository medicationRepository(MedicationRepositoryRef ref) {
  final db = ref.watch(dbHelperProvider);
  return SqliteMedicationRepository(db);
}

// --- Data Streams ---

@riverpod
Future<List<Medication>> activeMedications(ActiveMedicationsRef ref) async {
  final repository = ref.watch(medicationRepositoryProvider);
  return repository.getAllMedications();
}

// --- Controllers / Actions ---

@riverpod
class MedicationController extends _$MedicationController {
  @override
  FutureOr<void> build() {}

  Future<void> addMedication(Medication medication) async {
    final repository = ref.read(medicationRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.insertMedication(medication);
      // Invalidate the list provider so it refetches
      ref.invalidate(activeMedicationsProvider);
    });
  }

  Future<void> markTaken(int id, bool isTaken) async {
    final repository = ref.read(medicationRepositoryProvider);
    // Optimistic update could go here, but for now simple invalidation:
    await repository.updateTakenStatus(id, isTaken);
    ref.invalidate(activeMedicationsProvider);
  }
}
