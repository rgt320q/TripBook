
import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:tripbook/models/travel_location.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('travel_log.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _onUpgradeDB);
  }

  Future _onUpgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // We didn't have a proper TEXT type for groupId in v1
      // This is a simple migration, for complex ones, a full schema migration is needed.
      // As we are just changing the type, and sqlite is flexible, we might not even need to do anything.
      // But for future-proofing, this is the place.
      
      // Example: await db.execute("ALTER TABLE locations ADD COLUMN new_column TEXT;");
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const doubleType = 'REAL NOT NULL';
    const intType = 'INTEGER';

    await db.execute('''
CREATE TABLE locations ( 
  id $idType, 
  name $textType,
  description $textType,
  latitude $doubleType,
  longitude $doubleType,
  groupId TEXT,
  notes TEXT,
  needsList TEXT,
  estimatedDuration $intType
  )
''');
  }

  Future<TravelLocation> create(TravelLocation location) async {
    final db = await instance.database;
    final id = await db.insert('locations', {
      'name': location.name,
      'description': location.description,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'groupId': location.groupId,
      'notes': location.notes,
      'needsList': location.needsList != null ? jsonEncode(location.needsList) : null,
      'estimatedDuration': location.estimatedDuration,
    });
    return location.copyWith(id: id);
  }

  Future<List<TravelLocation>> readAllLocations() async {
    final db = await instance.database;
    final result = await db.query('locations');
    return result.map((json) {
      final needsListString = json['needsList'] as String?;
      List<Map<String, dynamic>>? needsList;
      if (needsListString != null && needsListString.isNotEmpty) {
        try {
          // First, try to decode as JSON (new format)
          final decoded = jsonDecode(needsListString);
          if (decoded is List) {
            needsList = List<Map<String, dynamic>>.from(
                decoded.map((item) => Map<String, dynamic>.from(item as Map)));
          }
        } catch (e) {
          // If decoding fails, assume it's the old comma-separated format
          needsList = needsListString
              .split(',')
              .where((name) => name.isNotEmpty)
              .map((name) => {'name': name, 'checked': false})
              .toList();
        }
      }

      return TravelLocation(
        id: json['id'] as int,
        name: json['name'] as String,
        geoName: json['name'] as String, // Legacy support
        description: json['description'] as String,
        latitude: json['latitude'] as double,
        longitude: json['longitude'] as double,
        groupId: json['groupId'] as String?,
        notes: json['notes'] as String?,
        needsList: needsList,
        estimatedDuration: json['estimatedDuration'] as int?,
      );
    }).toList();
  }

  Future<int> update(TravelLocation location) async {
    final db = await instance.database;
    return db.update(
      'locations',
      {
        'name': location.name,
        'description': location.description,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'groupId': location.groupId,
        'notes': location.notes,
        'needsList': location.needsList != null ? jsonEncode(location.needsList) : null,
        'estimatedDuration': location.estimatedDuration,
      },
      where: 'id = ?',
      whereArgs: [location.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'locations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

// Add copyWith to TravelLocation to make state management easier
extension TravelLocationCopyWith on TravelLocation {
  TravelLocation copyWith({
    int? id,
    String? firestoreId,
    String? name,
    String? geoName,
    String? description,
    double? latitude,
    double? longitude,
    String? groupId,
    String? notes,
    List<Map<String, dynamic>>? needsList,
    int? estimatedDuration,
    DateTime? createdAt,
  }) {
    return TravelLocation(
      id: id ?? this.id,
      firestoreId: firestoreId ?? this.firestoreId,
      name: name ?? this.name,
      geoName: geoName ?? this.geoName,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      groupId: groupId ?? this.groupId,
      notes: notes ?? this.notes,
      needsList: needsList ?? this.needsList,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
