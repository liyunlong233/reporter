class TrackConfig {
  int? id;
  String track1;
  String track2;
  String track3;
  String track4;
  String track5;
  String track6;
  String track7;
  String track8;
  
  TrackConfig({
    this.id,
    required this.track1,
    required this.track2,
    required this.track3,
    required this.track4,
    required this.track5,
    required this.track6,
    required this.track7,
    required this.track8,
  });

  factory TrackConfig.fromMap(Map<String, dynamic> map) => TrackConfig(
    id: map['id'],
    track1: map['track1'],
    track2: map['track2'],
    track3: map['track3'],
    track4: map['track4'],
    track5: map['track5'],
    track6: map['track6'],
    track7: map['track7'],
    track8: map['track8'],
  );
  
  Map<String, dynamic> toMap() => {
    'id': id,
    'track1': track1,
    'track2': track2,
    'track3': track3,
    'track4': track4,
    'track5': track5,
    'track6': track6,
    'track7': track7,
    'track8': track8,
  };
  
  List<String> get trackNames => [track1, track2, track3, track4, track5, track6, track7, track8];
}