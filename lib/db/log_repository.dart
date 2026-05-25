import 'package:sqflite/sqflite.dart';
import 'package:bottle/db/database.dart';
import 'package:bottle/protos/cap.pb.dart';

class LogRepository {
  final Database _db;
  LogRepository(this._db);

  static LogRepository? _instance;

  static Future<LogRepository> get instance async {
    if (_instance != null) return _instance!;
    _instance = LogRepository(await database);
    return _instance!;
  }

  Future<int> getLatestTimestamp(String table, String bottleName) async {
    final result = await _db.rawQuery(
      'SELECT MAX(timestamp) FROM $table WHERE bottle_name = ?',
      [bottleName],
    );
    final max = result.first.values.first;
    return max != null ? (max as int) + 1 : 0;
  }

  Future<List<Map<String, dynamic>>> getLogs(
    String table,
    String bottleName, {
    int limit = 30,
    int offset = 0,
  }) async {
    return _db.query(table,
      where: 'bottle_name = ?',
      whereArgs: [bottleName],
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
  }

  Future<int> getLogCount(String table, String bottleName) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as cnt FROM $table WHERE bottle_name = ?',
      [bottleName],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> insertTofLogs(String bottleName, List<CapTofLog> entries) async {
    final batch = _db.batch();
    for (final e in entries) {
      batch.insert('tof_logs', {
        'bottle_name': bottleName,
        'timestamp': e.timestamp.toInt(),
        'trigger_type': e.triggerType.value,
        'distance_mm': e.distanceInMillimeter,
        'kcps': e.kcps,
        'uv_led_temp_ohm': e.uvLedTempInOhm,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
    return entries.length;
  }

  Future<int> insertActivationLogs(
      String bottleName, List<CapActivationLog> entries) async {
    final batch = _db.batch();
    for (final e in entries) {
      batch.insert('activation_logs', {
        'bottle_name': bottleName,
        'timestamp': e.timestamp.toInt(),
        'mode': e.mode.value,
        'battery_soc_percentage': e.batterySocInPercentage,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
    return entries.length;
  }

  Future<int> insertFaultLogs(
      String bottleName, List<CapFaultLog> entries) async {
    final batch = _db.batch();
    for (final e in entries) {
      batch.insert('fault_logs', {
        'bottle_name': bottleName,
        'timestamp': e.timestamp.toInt(),
        'type': e.type.value,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
    return entries.length;
  }

  Future<int> insertStateLogs(
      String bottleName, List<CapStateLog> entries) async {
    final batch = _db.batch();
    for (final e in entries) {
      batch.insert('state_logs', {
        'bottle_name': bottleName,
        'timestamp': e.timestamp.toInt(),
        'hall': e.hall ? 1 : 0,
        'bottle_detection': e.bottleDetection ? 1 : 0,
        'ambient_light': e.ambientLight ? 1 : 0,
        'sip_detection': e.sipDetection ? 1 : 0,
        'bottle_detection_cap_value': e.bottleDetectionCapacitorValue,
        'ambient_light_sensor_value': e.ambientLightSensorValue,
        'sip_detection_cap_sensor_value': e.sipDetectionCapacitorSensorValue,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
    return entries.length;
  }

  Future<int> insertActivationAdcLogs(
      String bottleName, List<CapAdcLog> entries) async {
    final batch = _db.batch();
    for (final e in entries) {
      batch.insert('activation_adc_logs', {
        'bottle_name': bottleName,
        'timestamp': e.timestamp.toInt(),
        'battery_volt': e.batteryInVolt,
        'battery_temp_ohm': e.batteryTempInOhm,
        'uv_led_volt': e.uvLedInVolt,
        'uv_led_current_ma': e.uvLedCurrentInMilliamps,
        'uv_led_temp_ohm': e.uvLedTempInOhm,
        'c_pcb_temp_ohm': e.cPcbTempInOhm,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
    return entries.length;
  }

  Future<int> insertChargingAdcLogs(
      String bottleName, List<CapAdcLog> entries) async {
    final batch = _db.batch();
    for (final e in entries) {
      batch.insert('charging_adc_logs', {
        'bottle_name': bottleName,
        'timestamp': e.timestamp.toInt(),
        'battery_volt': e.batteryInVolt,
        'battery_temp_ohm': e.batteryTempInOhm,
        'uv_led_volt': e.uvLedInVolt,
        'uv_led_current_ma': e.uvLedCurrentInMilliamps,
        'uv_led_temp_ohm': e.uvLedTempInOhm,
        'c_pcb_temp_ohm': e.cPcbTempInOhm,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
    return entries.length;
  }

  Future<int> getHealthSyncTimestamp(String bottleName) async {
    final result = await _db.rawQuery(
      'SELECT last_tof_timestamp FROM health_sync WHERE bottle_name = ?',
      [bottleName],
    );
    if (result.isEmpty) return -1;
    return result.first.values.first as int;
  }

  Future<void> setHealthSyncTimestamp(String bottleName, int timestamp) async {
    await _db.insert(
      'health_sync',
      {'bottle_name': bottleName, 'last_tof_timestamp': timestamp},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getTofLogsSince(
    String bottleName,
    int fromTimestamp, {
    int limit = 100,
  }) async {
    return _db.query(
      'tof_logs',
      where: 'bottle_name = ? AND timestamp > ?',
      whereArgs: [bottleName, fromTimestamp],
      orderBy: 'timestamp ASC',
      limit: limit,
    );
  }
}
