class AppPreferences {
  final int? id;
  final bool includeDiscardedInPDF;
  final bool addLogoToPDF;
  final List<String> defaultFileFormats;
  final List<String> defaultEquipmentModels;
  final String? selectedFileFormat;
  final String? selectedEquipmentModel;
  final String? customLogoPath;

  AppPreferences({
    this.id,
    this.includeDiscardedInPDF = true,
    this.addLogoToPDF = true,
    this.defaultFileFormats = const [],
    this.defaultEquipmentModels = const [],
    this.selectedFileFormat,
    this.selectedEquipmentModel,
    this.customLogoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'includeDiscardedInPDF': includeDiscardedInPDF ? 1 : 0,
      'addLogoToPDF': addLogoToPDF ? 1 : 0,
      'defaultFileFormats': defaultFileFormats.join('|'),
      'defaultEquipmentModels': defaultEquipmentModels.join('|'),
      'selectedFileFormat': selectedFileFormat,
      'selectedEquipmentModel': selectedEquipmentModel,
      'customLogoPath': customLogoPath,
    };
  }

  factory AppPreferences.fromMap(Map<String, dynamic> map) {
    return AppPreferences(
      id: map['id'] as int?,
      includeDiscardedInPDF: (map['includeDiscardedInPDF'] as int?) == 1,
      addLogoToPDF: (map['addLogoToPDF'] as int?) == 1,
      defaultFileFormats: (map['defaultFileFormats'] as String?)
              ?.split('|')
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
      defaultEquipmentModels: (map['defaultEquipmentModels'] as String?)
              ?.split('|')
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
      selectedFileFormat: map['selectedFileFormat'] as String?,
      selectedEquipmentModel: map['selectedEquipmentModel'] as String?,
      customLogoPath: map['customLogoPath'] as String?,
    );
  }

  AppPreferences copyWith({
    int? id,
    bool? includeDiscardedInPDF,
    bool? addLogoToPDF,
    List<String>? defaultFileFormats,
    List<String>? defaultEquipmentModels,
    String? selectedFileFormat,
    String? selectedEquipmentModel,
    String? customLogoPath,
  }) {
    return AppPreferences(
      id: id ?? this.id,
      includeDiscardedInPDF: includeDiscardedInPDF ?? this.includeDiscardedInPDF,
      addLogoToPDF: addLogoToPDF ?? this.addLogoToPDF,
      defaultFileFormats: defaultFileFormats ?? this.defaultFileFormats,
      defaultEquipmentModels: defaultEquipmentModels ?? this.defaultEquipmentModels,
      selectedFileFormat: selectedFileFormat ?? this.selectedFileFormat,
      selectedEquipmentModel: selectedEquipmentModel ?? this.selectedEquipmentModel,
      customLogoPath: customLogoPath ?? this.customLogoPath,
    );
  }
}
