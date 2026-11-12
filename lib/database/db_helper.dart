import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notams.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Força o reset absoluto no IndexedDB da Web para carregar os novos dados
    try {
      await deleteDatabase(path);
    } catch (_) {}

    return await openDatabase(
      path,
      version: 8,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 8) {
          await db.execute('DROP TABLE IF EXISTS q_assuntos');
          await db.execute('DROP TABLE IF EXISTS q_condicoes');
          await db.execute('DROP TABLE IF EXISTS dicionario_abreviaturas');
          await db.execute('DROP TABLE IF EXISTS notams_salvos');
          await _createDB(db, newVersion);
        }
      },
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE q_assuntos (
        codigo TEXT PRIMARY KEY,
        categoria TEXT,
        descricao_pt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE q_condicoes (
        codigo TEXT PRIMARY KEY,
        descricao_pt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE dicionario_abreviaturas (
        sigla TEXT PRIMARY KEY,
        significado_pt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE notams_salvos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        numero_notam TEXT UNIQUE,
        tipo TEXT,
        fir TEXT,
        linha_q TEXT,
        texto_item_e TEXT,
        validade_inicio TEXT,
        validade_fim TEXT,
        ativo INTEGER DEFAULT 1,
        data_atualizacao TEXT
      )
    ''');

    // Inserção de Assuntos
    await db.insert('q_assuntos', {'codigo': 'OB', 'categoria': 'Obstáculos', 'descricao_pt': 'Obstáculo à Navegação'});
    await db.insert('q_assuntos', {'codigo': 'MR', 'categoria': 'Pista', 'descricao_pt': 'Pista de Pouso e Decolagem'});
    await db.insert('q_assuntos', {'codigo': 'MX', 'categoria': 'Taxiway/Manobra', 'descricao_pt': 'Área de Movimento e Taxiamento'});
    await db.insert('q_assuntos', {'codigo': 'FA', 'categoria': 'Aeródromo', 'descricao_pt': 'Instalações de Aeródromo'});
    await db.insert('q_assuntos', {'codigo': 'FF', 'categoria': 'Serviço de Incêndio', 'descricao_pt': 'Combate a Incêndio e Salvamento'});
    await db.insert('q_assuntos', {'codigo': 'FL', 'categoria': 'Auxílios visuais', 'descricao_pt': 'Iluminação de Aeródromo / Faróis'});
    await db.insert('q_assuntos', {'codigo': 'MW', 'categoria': 'Obras', 'descricao_pt': 'Obras / Construção'});
    await db.insert('q_assuntos', {'codigo': 'RD', 'categoria': 'Espaço Aéreo', 'descricao_pt': 'Área Perigosa (Danger Area)'});
    await db.insert('q_assuntos', {'codigo': 'RA', 'categoria': 'Espaço Aéreo', 'descricao_pt': 'Área Restrita (Restricted Area)'});
    await db.insert('q_assuntos', {'codigo': 'RP', 'categoria': 'Espaço Aéreo', 'descricao_pt': 'Área Proibida (Prohibited Area)'});
    await db.insert('q_assuntos', {'codigo': 'PX', 'categoria': 'Auxílios rádio', 'descricao_pt': 'Auxílios à Navegação (VOR/NDB/ILS)'});
    await db.insert('q_assuntos', {'codigo': 'TT', 'categoria': 'Telecomunicações', 'descricao_pt': 'Serviços de Telecomunicação / ATIS'});

    // Inserção de Condições
    await db.insert('q_condicoes', {'codigo': 'CE', 'descricao_pt': 'Erguido / Montado (Ex: Guindaste)'});
    await db.insert('q_condicoes', {'codigo': 'LC', 'descricao_pt': 'Fechada (Closed)'});
    await db.insert('q_condicoes', {'codigo': 'CS', 'descricao_pt': 'Fechado para Serviços'});
    await db.insert('q_condicoes', {'codigo': 'AH', 'descricao_pt': 'Horário de Serviço (Hours of Service)'});
    await db.insert('q_condicoes', {'codigo': 'AC', 'descricao_pt': 'Em Operação / Disponível'});
    await db.insert('q_condicoes', {'codigo': 'AD', 'descricao_pt': 'Disponível para Operação'});
    await db.insert('q_condicoes', {'codigo': 'CA', 'descricao_pt': 'Ativado / Em Operação'});
    await db.insert('q_condicoes', {'codigo': 'CL', 'descricao_pt': 'Cancelado / Desativado'});
    await db.insert('q_condicoes', {'codigo': 'U',  'descricao_pt': 'Fora de Operação / In unserviceable'});
    await db.insert('q_condicoes', {'codigo': 'W',  'descricao_pt': 'Trabalhos em Andamento (Withdrawn / Works)'});
    await db.insert('q_condicoes', {'codigo': 'TT', 'descricao_pt': 'Trabalhos / Operações (Works/Test)'});

    // Inserção de Abreviações
    await db.insert('dicionario_abreviaturas', {'sigla': 'LGTD', 'significado_pt': 'Iluminado (Lighted)'});
    await db.insert('dicionario_abreviaturas', {'sigla': 'HGT', 'significado_pt': 'Altura (Height)'});
    await db.insert('dicionario_abreviaturas', {'sigla': 'TWY', 'significado_pt': 'Taxiway (Pista de Táxi)'});
    await db.insert('dicionario_abreviaturas', {'sigla': 'INSTL', 'significado_pt': 'Instalado / Instalação'});
    await db.insert('dicionario_abreviaturas', {'sigla': 'HR', 'significado_pt': 'Horário (Hours)'});
    await db.insert('dicionario_abreviaturas', {'sigla': 'SER', 'significado_pt': 'Serviço / Servido (Service)'});
    await db.insert('dicionario_abreviaturas', {'sigla': 'O/T', 'significado_pt': 'Sob Solicitação / Outros Tempos'});
    await db.insert('dicionario_abreviaturas', {'sigla': 'U/S', 'significado_pt': 'Inoperante / Fora de Serviço'});
    await db.insert('dicionario_abreviaturas', {'sigla': 'H24', 'significado_pt': 'Contínuo 24 Horas'});
    await db.insert('dicionario_abreviaturas', {'sigla': 'HJ', 'significado_pt': 'Do Nascer ao Pôr do Sol'});
    await db.insert('dicionario_abreviaturas', {'sigla': 'HN', 'significado_pt': 'Do Pôr ao Nascer do Sol'});
  }
}