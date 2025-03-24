class RecordingEntry {
  String fileName;
  String startTC;
  String scene;
  String take;
  String slate;
  bool isDiscarded;
  String notes;
  int trackConfigId;
  int? id;

  RecordingEntry({
    this.id,
    required this.fileName,
    required this.startTC,
    required this.scene,
    required this.take,
    required this.slate,
    required this.isDiscarded,
    required this.notes,
    required this.trackConfigId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'fileName': fileName,
    'startTC': startTC,
    'scene': scene,
    'take': take,
    'slate': slate,
    'isDiscarded': isDiscarded ? 1 : 0,
    'notes': notes,
    'trackConfigId': trackConfigId,
  };

  factory RecordingEntry.fromMap(Map<String, dynamic> map) => RecordingEntry(
    id: map['id'],
    fileName: map['fileName'],
    startTC: map['startTC'],
    scene: map['scene'],
    take: map['take'],
    slate: map['slate'],
    isDiscarded: map['isDiscarded'] == 1,
    notes: map['notes'],
    trackConfigId: map['trackConfigId'],
  );
}