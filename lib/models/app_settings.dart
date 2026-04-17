class AppSettings {
  final int? id;
  final String projectName;
  final String productionCompany;
  final String soundEngineer;
  final String boomOperator;
  final String equipmentModel;
  final String fileFormat;
  final double frameRate;
  final DateTime projectDate;
  final String rollNumber;
  final int channelCount;

  AppSettings({
    this.id,
    required this.projectName,
    required this.productionCompany,
    required this.soundEngineer,
    required this.boomOperator,
    required this.equipmentModel,
    required this.fileFormat,
    required this.frameRate,
    required this.projectDate,
    required this.rollNumber,
    this.channelCount = 8,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'projectName': projectName,
    'productionCompany': productionCompany,
    'soundEngineer': soundEngineer,
    'boomOperator': boomOperator,
    'equipmentModel': equipmentModel,
    'fileFormat': fileFormat,
    'frameRate': frameRate,
    'projectDate': projectDate.toIso8601String(),
    'rollNumber': rollNumber,
    'channelCount': channelCount,
  };

  factory AppSettings.fromMap(Map<String, dynamic> map) => AppSettings(
    id: map['id'] as int?,
    projectName: map['projectName'],
    productionCompany: map['productionCompany'],
    soundEngineer: map['soundEngineer'],
    boomOperator: map['boomOperator'],
    equipmentModel: map['equipmentModel'],
    fileFormat: map['fileFormat'],
    frameRate: map['frameRate'],
    projectDate: DateTime.parse(map['projectDate']),
    rollNumber: map['rollNumber'],
    channelCount: map['channelCount'] as int? ?? 8,
  );
}