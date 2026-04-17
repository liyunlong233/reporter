class TimeCodeValidator {
  /// 验证时码格式是否为 HH:MM:SS:FF
  static bool isValid(String tc) {
    if (tc.isEmpty) return false;
    return RegExp(r'^\d{2}:\d{2}:\d{2}:\d{2}$').hasMatch(tc);
  }

  /// 验证时码的各个部分是否在合理范围内
  static bool isInRange(String tc, {double frameRate = 25.0}) {
    if (!isValid(tc)) return false;
    
    final parts = tc.split(':');
    if (parts.length != 4) return false;
    
    try {
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final seconds = int.parse(parts[2]);
      final frames = int.parse(parts[3]);
      
      if (hours < 0 || hours > 23) return false;
      if (minutes < 0 || minutes > 59) return false;
      if (seconds < 0 || seconds > 59) return false;
      if (frames < 0 || frames >= frameRate.round()) return false;
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 格式化时码，确保格式正确
  static String? formatTimeCode(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d:]'), '');
    final parts = cleaned.split(':');
    
    if (parts.length != 4) return null;
    
    try {
      final hours = int.parse(parts[0]).toString().padLeft(2, '0');
      final minutes = int.parse(parts[1]).toString().padLeft(2, '0');
      final seconds = int.parse(parts[2]).toString().padLeft(2, '0');
      final frames = int.parse(parts[3]).toString().padLeft(2, '0');
      
      return '$hours:$minutes:$seconds:$frames';
    } catch (e) {
      return null;
    }
  }

  /// 生成当前时间的时码
  static String generateCurrentTimeCode({int frameRate = 25}) {
    final now = DateTime.now();
    final frame = ((now.millisecond / 1000) * frameRate).round() % frameRate;
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}:${frame.toString().padLeft(2, '0')}';
  }
}
