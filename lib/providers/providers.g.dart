// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dbHelperHash() => r'9f342fc8d1f0ba9932d83e80dc742fe116c2c8c8';

/// See also [dbHelper].
@ProviderFor(dbHelper)
final dbHelperProvider = AutoDisposeProvider<DBHelper>.internal(
  dbHelper,
  name: r'dbHelperProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dbHelperHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DbHelperRef = AutoDisposeProviderRef<DBHelper>;
String _$medicationRepositoryHash() =>
    r'4f3e5f0682e173985dd2c1db6819629f1080d39c';

/// See also [medicationRepository].
@ProviderFor(medicationRepository)
final medicationRepositoryProvider =
    AutoDisposeProvider<MedicationRepository>.internal(
      medicationRepository,
      name: r'medicationRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$medicationRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MedicationRepositoryRef = AutoDisposeProviderRef<MedicationRepository>;
String _$activeMedicationsHash() => r'ff3dcee0391aabb59992a9831e2c5d5d0caf5f05';

/// See also [activeMedications].
@ProviderFor(activeMedications)
final activeMedicationsProvider =
    AutoDisposeFutureProvider<List<Medication>>.internal(
      activeMedications,
      name: r'activeMedicationsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$activeMedicationsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveMedicationsRef = AutoDisposeFutureProviderRef<List<Medication>>;
String _$medicationControllerHash() =>
    r'5ed42120982688c3c065b7b153e8a83de3ec4018';

/// See also [MedicationController].
@ProviderFor(MedicationController)
final medicationControllerProvider =
    AutoDisposeAsyncNotifierProvider<MedicationController, void>.internal(
      MedicationController.new,
      name: r'medicationControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$medicationControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MedicationController = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
