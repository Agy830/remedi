class Medication {
  final int? id;

  // Core info
  final String name;
  final String dosage;

  /// Stored as "HH:mm;HH:mm" (24h, DB-safe)
  final String time;

  /// Daily taken status (resets daily later)
  final bool isTaken;

  /// When medication starts
  final DateTime startDate;

  /// Optional end date (null = ongoing)
  final DateTime? endDate;

  /// Optional note (e.g. "After meals")
  final String? note;

  Medication({
    this.id,
    required this.name,
    required this.dosage,
    required this.time,
    this.isTaken = false,
    DateTime? startDate,
    this.endDate,
    this.note,
  }) : startDate = startDate ?? DateTime.now();

  /// DB → Model
  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] as int?,
      name: map['name'] as String,
      dosage: map['dosage'] as String,
      time: map['time'] as String,
      isTaken: map['isTaken'] == 1,
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'])
          : DateTime.now(),
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'])
          : null,
      note: map['note'] as String?,
    );
  }

  /// Model → DB
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'time': time,
      'isTaken': isTaken ? 1 : 0,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'note': note,
    };
  }

  Medication copyWith({
    int? id,
    String? name,
    String? dosage,
    String? time,
    bool? isTaken,
    DateTime? startDate,
    DateTime? endDate,
    String? note,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      time: time ?? this.time,
      isTaken: isTaken ?? this.isTaken,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      note: note ?? this.note,
    );
  }

  /// Utility: has this medication expired?
  bool get isExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }
}
