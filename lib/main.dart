import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'notam_parser.dart';

void main() {
  runApp(const NotamDecoderApp());
}

class NotamDecoderApp extends StatelessWidget {
  const NotamDecoderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DECEA NOTAM Decoder (EFB)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.blueAccent,
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          surface: Color(0xFF1E1E1E),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Colors.white12, width: 1),
          ),
        ),
      ),
      home: const NotamHomeScreeen(),
    );
  }
}

class NotamHomeScreeen extends StatefulWidget {
  const NotamHomeScreeen({super.key});

  @override
  State<NotamHomeScreeen> createState() => _NotamHomeScreeenState();
}

class _NotamHomeScreeenState extends State<NotamHomeScreeen> {
  final TextEditingController _notamController = TextEditingController();
  Map<String, String>? _traducao;
  bool _processado = false;

  Future<void> _processarNotam() async {
    String textoInput = _notamController.text.trim();
    if (textoInput.isEmpty) return;

    Map<String, String> resultado = await NotamParser.decodificar(textoInput);

    setState(() {
      _traducao = resultado;
      _processado = true;
    });
  }

  String _gerarTextoCopia() {
    if (_traducao == null) return '';
    return '''
Número: ${_traducao!['numero']}
----------------------------------
A) Localidade/FIR : ${_traducao!['campo_a']}
B) Início Vigência: ${_traducao!['campo_b']}
C) Término/Validade: ${_traducao!['campo_c']}
D) Período Ativação: ${_traducao!['campo_d']}
----------------------------------
Assunto Traduzido : ${_traducao!['assunto']}
Condição          : ${_traducao!['condicao']}
----------------------------------
E) Descrição/Coord:
${_traducao!['campo_e']}
----------------------------------
F) Limite Inferior: ${_traducao!['campo_f']}
G) Limite Superior: ${_traducao!['campo_g']}
''';
  }

  void _copiarParaClipboard() {
    if (!_processado) return;
    Clipboard.setData(ClipboardData(text: _gerarTextoCopia()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tradução copiada para a área de transferência!'),
        backgroundColor: Colors.blueGrey,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _enviarPorEmail() {
    if (!_processado) return;
    _copiarParaClipboard();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Texto copiado! Pronto para colar no e-mail.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DECEA NOTAM Decoder (EFB)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
           TextField(
  controller: _notamController,
  maxLines: 4,
  style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.white),
  decoration: InputDecoration(
    filled: true,
    fillColor: const Color(0xFF2C2C2C), // <--- Tom mais claro para destaque
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.white30),
    ),
    labelText: 'Cole o texto cru do NOTAM aqui',
    hintText: 'Ex: F6524/26 N ...',
    labelStyle: const TextStyle(color: Colors.white70),
  ),
),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _processarNotam,
              icon: const Icon(Icons.bolt, color: Colors.amber),
              label: const Text('DECODIFICAR NOTAM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Painel de Análise Tática:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white70),
                ),
                if (_processado)
                  Row(
                    children: [
                      IconButton.outlined(
                        icon: const Icon(Icons.copy, color: Colors.blueAccent, size: 20),
                        tooltip: 'Copiar Texto',
                        onPressed: _copiarParaClipboard,
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        icon: const Icon(Icons.email, color: Colors.greenAccent, size: 20),
                        tooltip: 'Copiar para E-mail',
                        onPressed: _enviarPorEmail,
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: !_processado
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.flight_takeoff, size: 48, color: Colors.white24),
                          SizedBox(height: 12),
                          Text(
                            'Aguardando inserção de NOTAM...',
                            style: TextStyle(color: Colors.white38, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      children: [
                        _buildCardInfo(
                          titulo: 'Identificação & Localidade',
                          icone: Icons.radar,
                          corBorda: Colors.blueAccent,
                          conteudo: [
                            _linhaDetalhe('Número:', _traducao!['numero']!, isDestacado: true),
                            _linhaDetalhe('A) Localidade/FIR:', _traducao!['campo_a']!),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildCardInfo(
                          titulo: 'Vigência & Validade',
                          icone: Icons.schedule,
                          corBorda: Colors.orangeAccent,
                          conteudo: [
                            _linhaDetalhe('B) Início:', _traducao!['campo_b']!),
                            _linhaDetalhe('C) Término:', _traducao!['campo_c']!),
                            _linhaDetalhe('D) Ativação:', _traducao!['campo_d']!),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildCardInfo(
                          titulo: 'Tradução Aeronáutica (DECEA)',
                          icone: Icons.translate,
                          corBorda: Colors.greenAccent,
                          conteudo: [
                            _linhaDetalhe('Assunto:', _traducao!['assunto']!, isDestacado: true),
                            _linhaDetalhe('Condição:', _traducao!['condicao']!, isDestacado: true),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildCardInfo(
                          titulo: 'E) Descrição / Mensagem Principal',
                          icone: Icons.description,
                          corBorda: Colors.purpleAccent,
                          conteudo: [
                            Text(
                              _traducao!['campo_e']!,
                              style: const TextStyle(fontSize: 13, height: 1.4, fontFamily: 'monospace', color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildCardInfo(
                          titulo: 'Limites Verticais',
                          icone: Icons.height,
                          corBorda: Colors.tealAccent,
                          conteudo: [
                            _linhaDetalhe('F) Limite Inferior:', _traducao!['campo_f']!),
                            _linhaDetalhe('G) Limite Superior:', _traducao!['campo_g']!),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardInfo({required String titulo, required IconData icone, required Color corBorda, required List<Widget> conteudo}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, size: 18, color: corBorda),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: corBorda),
                ),
              ],
            ),
            const Divider(height: 16, color: Colors.white10),
            ...conteudo,
          ],
        ),
      ),
    );
  }

  Widget _linhaDetalhe(String rotulo, String valor, {bool isDestacado = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              rotulo,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: isDestacado ? FontWeight.bold : FontWeight.normal,
                fontFamily: isDestacado ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}