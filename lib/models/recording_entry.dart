class RecordingEntry {
  static const int maxTracks = 8;
  
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

  List<String?> get tracks => [track1, track2, track3, track4, track5, track6, track7, track8];

  Map<String, dynamic> toMap() {
    final map = {
      'id': id,
      'fileName': fileName,
      'startTC': startTC,
      'scene': scene,
      'take': take,
      'slate': slate,
      'isDiscarded': isDiscarded ? 1 : 0,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
    
    for (var i = 1; i <= maxTracks; i++) {
      map['track$i'] = tracks[i - 1];
    }
    
    return map;
  }

  factory RecordingEntry.fromMap(Map<String, dynamic> map) {
    final tracks = List<String?>.generate(
      maxTracks,
      (i) => map['track${i + 1}'] as String?,
    );

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
      track1: tracks[0],
      track2: tracks[1],
      track3: tracks[2],
      track4: tracks[3],
      track5: tracks[4],
      track6: tracks[5],
      track7: tracks[6],
      track8: tracks[7],
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
    List<String?>? tracks,
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
      track1: tracks?[0] ?? track1,
      track2: tracks?[1] ?? track2,
      track3: tracks?[2] ?? track3,
      track4: tracks?[3] ?? track4,
      track5: tracks?[4] ?? track5,
      track6: tracks?[5] ?? track6,
      track7: tracks?[6] ?? track7,
      track8: tracks?[7] ?? track8,
    );
  }
}