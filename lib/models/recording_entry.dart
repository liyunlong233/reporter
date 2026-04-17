class RecordingEntry {
  static const int maxTracks = 24;
  
  final int? id;
  final String fileName;
  final String startTC;
  final String scene;
  final String take;
  final String slate;
  final bool isDiscarded;
  final String notes;
  final DateTime createdAt;
  final List<String?> _tracks;
  final List<bool> _trackChecked;

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
    String? track1,
    String? track2,
    String? track3,
    String? track4,
    String? track5,
    String? track6,
    String? track7,
    String? track8,
    String? track9,
    String? track10,
    String? track11,
    String? track12,
    String? track13,
    String? track14,
    String? track15,
    String? track16,
    String? track17,
    String? track18,
    String? track19,
    String? track20,
    String? track21,
    String? track22,
    String? track23,
    String? track24,
    List<bool>? trackChecked,
  }) : _tracks = [track1, track2, track3, track4, track5, track6, track7, track8, track9, track10, track11, track12, track13, track14, track15, track16, track17, track18, track19, track20, track21, track22, track23, track24],
       _trackChecked = trackChecked ?? List.filled(maxTracks, false);

  RecordingEntry.withTracks({
    this.id,
    required this.fileName,
    required this.startTC,
    required this.scene,
    required this.take,
    required this.slate,
    required this.isDiscarded,
    required this.notes,
    required this.createdAt,
    List<String?>? tracks,
    List<bool>? trackChecked,
  }) : _tracks = tracks != null 
           ? [...tracks, ...List.filled(maxTracks - tracks.length, null)].take(maxTracks).toList()
           : List.filled(maxTracks, null),
       _trackChecked = trackChecked != null 
           ? [...trackChecked, ...List.filled(maxTracks - trackChecked.length, false)].take(maxTracks).toList()
           : List.filled(maxTracks, false);

  List<String?> get tracks => List.unmodifiable(_tracks);
  List<bool> get trackChecked => List.unmodifiable(_trackChecked);

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
    
    for (var i = 1; i <= maxTracks; i++) {
      map['track${i}_checked'] = trackChecked[i - 1] ? 1 : 0;
    }
    
    return map;
  }

  factory RecordingEntry.fromMap(Map<String, dynamic> map) {
    final tracks = List<String?>.generate(
      maxTracks,
      (i) => map['track${i + 1}'] as String?,
    );

    final trackChecked = List<bool>.generate(
      maxTracks,
      (i) => (map['track${i + 1}_checked'] as int?) == 1,
    );

    return RecordingEntry.withTracks(
      id: map['id'] as int?,
      fileName: map['fileName'] as String,
      startTC: map['startTC'] as String,
      scene: map['scene'] as String,
      take: map['take'] as String,
      slate: map['slate'] as String,
      isDiscarded: (map['isDiscarded'] as int) == 1,
      notes: map['notes'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      tracks: tracks,
      trackChecked: trackChecked,
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
    List<bool>? trackChecked,
  }) {
    final newTracks = tracks ?? List<String?>.from(_tracks);
    final newTrackChecked = trackChecked ?? List<bool>.from(_trackChecked);
    return RecordingEntry.withTracks(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      startTC: startTC ?? this.startTC,
      scene: scene ?? this.scene,
      take: take ?? this.take,
      slate: slate ?? this.slate,
      isDiscarded: isDiscarded ?? this.isDiscarded,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      tracks: newTracks,
      trackChecked: newTrackChecked,
    );
  }
}