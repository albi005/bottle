import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

Database? _db;

Future<Database> get database async {
  if (_db != null) return _db!;
  final dir = await getApplicationDocumentsDirectory();
  final path = join(dir.path, 'bottle.db');
  _db = await openDatabase(path, version: 1, onCreate: _onCreate);
  return _db!;
}

Future<void> _onCreate(Database db, int version) async {
  await db.execute('''
    CREATE TABLE tof_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bottle_name TEXT NOT NULL,
      timestamp INTEGER NOT NULL,
      trigger_type INTEGER NOT NULL,
      distance_mm INTEGER NOT NULL,
      kcps INTEGER NOT NULL,
      uv_led_temp_ohm REAL NOT NULL,
      UNIQUE(bottle_name, timestamp)
    )
  ''');
  await db.execute('''
    CREATE TABLE activation_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bottle_name TEXT NOT NULL,
      timestamp INTEGER NOT NULL,
      mode INTEGER NOT NULL,
      battery_soc_percentage INTEGER NOT NULL,
      UNIQUE(bottle_name, timestamp)
    )
  ''');
  await db.execute('''
    CREATE TABLE fault_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bottle_name TEXT NOT NULL,
      timestamp INTEGER NOT NULL,
      type INTEGER NOT NULL,
      UNIQUE(bottle_name, timestamp)
    )
  ''');
  await db.execute('''
    CREATE TABLE state_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bottle_name TEXT NOT NULL,
      timestamp INTEGER NOT NULL,
      hall INTEGER NOT NULL,
      bottle_detection INTEGER NOT NULL,
      ambient_light INTEGER NOT NULL,
      sip_detection INTEGER NOT NULL,
      bottle_detection_cap_value REAL NOT NULL,
      ambient_light_sensor_value REAL NOT NULL,
      sip_detection_cap_sensor_value REAL NOT NULL,
      UNIQUE(bottle_name, timestamp)
    )
  ''');
  await db.execute('''
    CREATE TABLE activation_adc_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bottle_name TEXT NOT NULL,
      timestamp INTEGER NOT NULL,
      battery_volt REAL NOT NULL,
      battery_temp_ohm REAL NOT NULL,
      uv_led_volt REAL NOT NULL,
      uv_led_current_ma REAL NOT NULL,
      uv_led_temp_ohm REAL NOT NULL,
      c_pcb_temp_ohm REAL NOT NULL,
      UNIQUE(bottle_name, timestamp)
    )
  ''');
  await db.execute('''
    CREATE TABLE charging_adc_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bottle_name TEXT NOT NULL,
      timestamp INTEGER NOT NULL,
      battery_volt REAL NOT NULL,
      battery_temp_ohm REAL NOT NULL,
      uv_led_volt REAL NOT NULL,
      uv_led_current_ma REAL NOT NULL,
      uv_led_temp_ohm REAL NOT NULL,
      c_pcb_temp_ohm REAL NOT NULL,
      UNIQUE(bottle_name, timestamp)
    )
  ''');
}
