class RecordingEntry {
  final int? id;
  final String fileName;
  final String startTC;
  final String scene;
  final String take;
  final String slate;
  final bool isDiscarded;
  final String notes;
  final DateTime createdAt;
  final String? track1;
  final String? track2;
  final String? track3;
  final String? track4;
  final String? track5;
  final String? track6;
  final String? track7;
  final String? track8;

  RecordingEntry({
    this.id,
    required this.fileName,
    required this.startTC,
    required this.scene,
    required this.take,
    required this.slate,
    required this.isDiscarded,
    required this.notes,
    required this.createdAt,
    this.track1,
    this.track2,
    this.track3,
    this.track4,
    this.track5,
    this.track6,
    this.track7,
    this.track8,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fileName': fileName,
      'startTC': startTC,
      'scene': scene,
      'take': take,
      'slate': slate,
      'isDiscarded': isDiscarded ? 1 : 0,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'track1': track1,
      'track2': track2,
      'track3': track3,
      'track4': track4,
      'track5': track5,
      'track6': track6,
      'track7': track7,
      'track8': track8,
    };
  }

  factory RecordingEntry.fromMap(Map<String, dynamic> map) {
    return RecordingEntry(
      id: map['id'] as int?,
      fileName: map['fileName'] as String,
      startTC: map['startTC'] as String,
      scene: map['scene'] as String,
      take: map['take'] as String,
      slate: map['slate'] as String,
      isDiscarded: (map['isDiscarded'] as int) == 1,
      notes: map['notes'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      track1: map['track1'] as String?,
      track2: map['track2'] as String?,
      track3: map['track3'] as String?,
      track4: map['track4'] as String?,
      track5: map['track5'] as String?,
      track6: map['track6'] as String?,
      track7: map['track7'] as String?,
      track8: map['track8'] as String?,
    );
  }

  RecordingEntry copyWith({
    int? id,
    String? fileName,
    String? startTC,
    String? scene,
    String? take,
    String? slate,
    bool? isDiscarded,
    String? notes,
    DateTime? createdAt,
    String? track1,
    String? track2,
    String? track3,
    String? track4,
    String? track5,
    String? track6,
    String? track7,
    String? track8,
  }) {
    return RecordingEntry(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      startTC: startTC ?? this.startTC,
      scene: scene ?? this.scene,
      take: take ?? this.take,
      slate: slate ?? this.slate,
      isDiscarded: isDiscarded ?? this.isDiscarded,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      track1: track1 ?? this.track1,
      track2: track2 ?? this.track2,
      track3: track3 ?? this.track3,
      track4: track4 ?? this.track4,
      track5: track5 ?? this.track5,
      track6: track6 ?? this.track6,
      track7: track7 ?? this.track7,
      track8: track8 ?? this.track8,
    );
  }
}