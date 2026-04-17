class FileNameValidator {
  /// Windows 文件名非法字符
  static final _illegalChars = RegExp(r'[<>:"/\\|？*]');
  
  /// 验证文件名是否合法
  static bool isValid(String fileName) {
    if (fileName.isEmpty) return false;
    if (fileName.length > 255) return false;
    if (_illegalChars.hasMatch(fileName)) return false;
    if (fileName.startsWith('.') || fileName.endsWith('.')) return false;
    return true;
  }

  /// 清理文件名中的非法字符
  static String sanitize(String fileName) {
    return fileName
        .replaceAll(_illegalChars, '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
  }

  /// 验证文件名格式是否符合录音规范（如 REC_001）
  static bool isValidRecordingFormat(String fileName) {
    return RegExp(r'^[A-Za-z_][A-Za-z0-9_]*\d+$').hasMatch(fileName);
  }

  /// 从文件名提取前缀和数字
  static Map<String, dynamic>? parseFileName(String fileName) {
    final match = RegExp(r'^(.+?)(\d+)$').firstMatch(fileName);
    if (match != null) {
      return {
        'prefix': match.group(1)!,
        'number': int.parse(match.group(2)!),
        'digits': match.group(2)!.length,
      };
    }
    return null;
  }

  /// 生成下一个文件名
  static String generateNextFileName(String currentFileName) {
    final parsed = parseFileName(currentFileName);
    if (parsed != null) {
      final prefix = parsed['prefix'] as String;
      final number = parsed['number'] as int;
      final digits = parsed['digits'] as int;
      return '$prefix${(number + 1).toString().padLeft(digits, '0')}';
    }
    // 如果格式不匹配，返回默认格式
    return 'REC_001';
  }
}
