import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Redacteur {
  int? id;
  String nom;
  String prenom;
  String email;

  Redacteur({required this.id, required this.nom, required this.prenom, required this.email});

  Redacteur.withoutId({required this.nom, required this.prenom, required this.email});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
    };
  }

  @override
  String toString() {
    return 'Redacteur{id: $id, nom: $nom, prenom: $prenom, email: $email}';
  }
}


class DatabaseManager {
  static final DatabaseManager _instance = DatabaseManager._internal();
  late Database _database;
  bool _isInitialized = false;

  DatabaseManager._internal();

  factory DatabaseManager() {
    return _instance;
  }

  Future<void> initialize() async {
    if (!_isInitialized) {
      _database = await openDatabase(
        join(await getDatabasesPath(), 'redacteurs_database.db'),
        onCreate: (db, version) {
          return db.execute(
            "CREATE TABLE redacteurs(id INTEGER PRIMARY KEY AUTOINCREMENT, nom TEXT, prenom TEXT, email TEXT)",
          );
        },
        version: 1,
      );
      _isInitialized = true;
    }
  }

  Future<void> insertRedacteur(Redacteur redacteur) async {
    await _ensureDatabaseInitialized();
    await _database.insert(
      'redacteurs',
      redacteur.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, //Ecrase la valeur deja presente
    );
  }

  Future<List<Redacteur>> getAllRedacteurs() async {
    await _ensureDatabaseInitialized();
    final List<Map<String, dynamic>> maps = await _database.query('redacteurs');
    return List.generate(maps.length, (i) {
      return Redacteur(
        id: maps[i]['id'],
        nom: maps[i]['nom'],
        prenom: maps[i]['prenom'],
        email: maps[i]['email'],
      );
    });
  }

  Future<void> updateRedacteur(Redacteur redacteur) async {
    await _ensureDatabaseInitialized();
    await _database.update(
      'redacteurs',
      redacteur.toMap(),
      where: 'id = ?',
      whereArgs: [redacteur.id],
    );
  }

  Future<void> deleteRedacteur(int id) async {
    await _ensureDatabaseInitialized();
    await _database.delete(
      'redacteurs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> _ensureDatabaseInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
}

