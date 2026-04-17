class AppPreferences {
  final int? id;
  final bool includeDiscardedInPDF;
  final List<String> defaultFileFormats;
  final List<String> defaultEquipmentModels;
  final String? selectedFileFormat;
  final String? selectedEquipmentModel;

  AppPreferences({
    this.id,
    this.includeDiscardedInPDF = true,
    this.defaultFileFormats = const [],
    this.defaultEquipmentModels = const [],
    this.selectedFileFormat,
    this.selectedEquipmentModel,
  });

  Map<String, dynamic> toMap() {
    return {
      'includeDiscardedInPDF': includeDiscardedInPDF ? 1 : 0,
      'defaultFileFormats': defaultFileFormats.join('|'),
      'defaultEquipmentModels': defaultEquipmentModels.join('|'),
      'selectedFileFormat': selectedFileFormat,
      'selectedEquipmentModel': selectedEquipmentModel,
    };
  }

  factory AppPreferences.fromMap(Map<String, dynamic> map) {
    return AppPreferences(
      id: map['id'] as int?,
      includeDiscardedInPDF: (map['includeDiscardedInPDF'] as int?) == 1,
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
    );
  }

  AppPreferences copyWith({
    int? id,
    bool? includeDiscardedInPDF,
    List<String>? defaultFileFormats,
    List<String>? defaultEquipmentModels,
    String? selectedFileFormat,
    String? selectedEquipmentModel,
  }) {
    return AppPreferences(
      id: id ?? this.id,
      includeDiscardedInPDF: includeDiscardedInPDF ?? this.includeDiscardedInPDF,
      defaultFileFormats: defaultFileFormats ?? this.defaultFileFormats,
      defaultEquipmentModels: defaultEquipmentModels ?? this.defaultEquipmentModels,
      selectedFileFormat: selectedFileFormat ?? this.selectedFileFormat,
      selectedEquipmentModel: selectedEquipmentModel ?? this.selectedEquipmentModel,
    );
  }
}
