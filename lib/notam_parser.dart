typedef NotamMap = Map<String, String>;

class NotamParser {
  // Dicionário estático para tradução imediata e infalível na Web
  static const Map<String, String> _assuntosPt = {
    'OB': 'Obstáculo à Navegação',
    'MR': 'Pista de Pouso e Decolagem',
    'MX': 'Área de Movimento e Taxiamento',
    'FA': 'Instalações de Aeródromo',
    'FF': 'Combate a Incêndio e Salvamento',
    'FL': 'Iluminação de Aeródromo / Faróis',
    'MW': 'Obras / Construção',
    'RD': 'Área Perigosa (Danger Area)',
    'RA': 'Área Restrita (Restricted Area)',
    'RP': 'Área Proibida (Prohibited Area)',
    'PX': 'Auxílios à Navegação (VOR/NDB/ILS)',
    'TT': 'Serviços de Telecomunicação / ATIS',
  };

  static const Map<String, String> _condicoesPt = {
    'CE': 'Erguido / Montado (Ex: Guindaste)',
    'LC': 'Fechada (Closed)',
    'CS': 'Fechado para Serviços',
    'AH': 'Horário de Serviço (Hours of Service)',
    'AC': 'Em Operação / Disponível',
    'AD': 'Disponível para Operação',
    'CA': 'Ativado / Em Operação',
    'CL': 'Cancelado / Desativado',
    'U':  'Fora de Operação / In unserviceable',
    'W':  'Trabalhos em Andamento (Withdrawn / Works)',
    'TT': 'Trabalhos / Operações (Works/Test)',
  };

  static String _obterNomeFir(String firCodigo) {
    switch (firCodigo.toUpperCase()) {
      case 'SBBS':
        return 'Brasília';
      case 'SBCC':
        return 'Curitiba';
      case 'SBCW':
        return 'Curitiba';
      case 'SBRE':
        return 'Recife';
      case 'SBAO':
        return 'Amazônica';
      case 'SBAZ':
        return 'Atlântico';
      case 'SBRE/SBBS':
        return 'Recife / Brasília';
      default:
        return 'Desconhecida';
    }
  }

  static Future<NotamMap> decodificar(String textoCru) async {
    NotamMap resultado = {
      'numero': 'Não identificado',
      'campo_a': 'Não informado',
      'campo_b': 'Não informado',
      'campo_c': 'Não informado',
      'campo_d': 'Não informado',
      'campo_e': 'Não informado',
      'campo_f': 'Não informado',
      'campo_g': 'Não informado',
      'assunto': 'Desconhecido',
      'condicao': 'Desconhecida',
    };

    // 1. Número do NOTAM
    final matchNumero = RegExp(r'([A-Z]\d+/\d{2})').firstMatch(textoCru);
    if (matchNumero != null) {
      resultado['numero'] = matchNumero.group(0)!;
    }

    // 2. Linha Q e tradução via dicionário estático
    final matchLinhaQ = RegExp(r'Q\)\s*([A-Z]{4})/([A-Z0-9]+)').firstMatch(textoCru);
    if (matchLinhaQ != null) {
      String firSigla = matchLinhaQ.group(1) ?? '';
      String nomeFir = _obterNomeFir(firSigla);
      resultado['campo_a'] = '$firSigla ($nomeFir)';
      
      String qCodeBruto = matchLinhaQ.group(2) ?? '';
      String qCodeLimpo = qCodeBruto.startsWith('Q') ? qCodeBruto.substring(1) : qCodeBruto;
      
      if (qCodeLimpo.length >= 4) {
        String assuntoSigla = qCodeLimpo.substring(0, 2).toUpperCase().trim();
        String condicaoSigla = qCodeLimpo.substring(2, 4).toUpperCase().trim();

        resultado['assunto'] = _assuntosPt[assuntoSigla] ?? 'Assunto: $assuntoSigla';
        resultado['condicao'] = _condicoesPt[condicaoSigla] ?? 'Condição: $condicaoSigla';
      }
    }

    // Limites F e G direto da Linha Q
    final matchLimitesQ = RegExp(r'Q\)[^/]+/[^/]+/[^/]+/[^/]+/[^/]+/(\d{3})/(\d{3})').firstMatch(textoCru);
    if (matchLimitesQ != null) {
      String infRaw = matchLimitesQ.group(1) ?? '000';
      String supRaw = matchLimitesQ.group(2) ?? '999';
      resultado['campo_f'] = infRaw == '000' ? 'GND (Solo)' : '$infRaw Pés/FL';
      resultado['campo_g'] = supRaw == '999' ? 'Ilimitado' : '$supRaw Pés/FL';
    }

    // 3. Vigência WEF / TIL ou campos tradicionais
    final matchWefTil = RegExp(r'WEF\s+([0-9A-Z]+)\s+TIL\s+([0-9A-Z]+)', caseSensitive: false).firstMatch(textoCru);
    if (matchWefTil != null) {
      resultado['campo_b'] = matchWefTil.group(1)?.trim() ?? 'Não informado';
      String tilRaw = matchWefTil.group(2)?.trim() ?? '';
      if (tilRaw.length > 7 && RegExp(r'\d{2}[A-Z]{3}\d{2}').hasMatch(tilRaw)) {
        tilRaw = tilRaw.substring(0, 7);
      }
      resultado['campo_c'] = 'Até $tilRaw';
    } else {
      final matchB = RegExp(r'B\)\s*([0-9A-Z/\s:]+)', caseSensitive: false).firstMatch(textoCru);
      if (matchB != null) resultado['campo_b'] = matchB.group(1)?.trim() ?? 'Não informado';

      final matchC = RegExp(r'C\)\s*([0-9A-Z/\s:PERM]+)', caseSensitive: false).firstMatch(textoCru);
      if (matchC != null) {
        resultado['campo_c'] = matchC.group(1)?.trim() ?? 'Não informado';
      } else if (textoCru.toUpperCase().contains('PERM')) {
        resultado['campo_c'] = 'Permanente (PERM)';
      }
    }

    // 4. Período de Ativação (Campo D)
    List<String> linhas = textoCru.split('\n');
    List<String> cronograma = [];
    for (var linha in linhas) {
      if (RegExp(r'\d{4}-\d{4}').hasMatch(linha) || linha.toUpperCase().contains('DAILY')) {
        cronograma.add(linha.trim());
      }
    }
    if (cronograma.isNotEmpty) {
      resultado['campo_d'] = cronograma.join('\n');
    }

    // 5. Descrição / Item E
    final indexQ = textoCru.indexOf('Q)');
    if (indexQ != -1) {
      resultado['campo_e'] = textoCru.substring(indexQ).trim();
    } else {
      resultado['campo_e'] = textoCru;
    }

    return resultado;
  }
}