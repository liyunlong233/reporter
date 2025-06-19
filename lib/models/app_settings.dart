class AppSettings {
  int? id;
  String projectName;
  String productionCompany;
  String soundEngineer;
  String boomOperator;
  String equipmentModel;
  String fileFormat;
  double frameRate;
  DateTime projectDate;
  String rollNumber;

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
  );
}