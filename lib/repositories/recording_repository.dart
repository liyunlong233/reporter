import '../models/recording_entry.dart';

abstract class RecordingRepository {
  Future<List<RecordingEntry>> getAllRecordings();
  Future<RecordingEntry?> getRecordingById(int id);
  Future<RecordingEntry?> getLatestRecording();
  Future<int> saveRecording(RecordingEntry entry);
  Future<int> updateRecording(RecordingEntry entry);
  Future<void> deleteRecording(int id);
  Future<List<RecordingEntry>> getActiveRecordings();
  Future<List<RecordingEntry>> getDiscardedRecordings();
  Future<void> deleteAllRecordings();
}
