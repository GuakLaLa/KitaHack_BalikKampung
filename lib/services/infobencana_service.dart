import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Models
class ActivePPS {
  final String name;
  final String state;
  final String district;
  final String mukim;
  final String disasterType;
  final int kapasiti;        // occupancy % (0-100)
  final int mangsa;
  final int keluarga;
  final double? lat;
  final double? lng;
  final DateTime openedDate;
  // Demographics
  final int lelakiDewasa;
  final int perempuanDewasa;
  final int kanakLelaki;
  final int kanakPerempuan;
  final int bayiLelaki;
  final int bayiPerempuan;

  const ActivePPS({
    required this.name,
    required this.state,
    required this.district,
    this.mukim = '',
    required this.disasterType,
    required this.kapasiti,
    required this.mangsa,
    required this.keluarga,
    this.lat,
    this.lng,
    required this.openedDate,
    this.lelakiDewasa = 0,
    this.perempuanDewasa = 0,
    this.kanakLelaki = 0,
    this.kanakPerempuan = 0,
    this.bayiLelaki = 0,
    this.bayiPerempuan = 0,
  });

  int get effectiveCapacity {
    final n = name.toLowerCase();
    if (n.contains('stadium'))                                        return 3000;
    if (n.contains('sekolah') || n.contains('sk ') || n.contains('smk')) return 800;
    if (n.contains('masjid')  || n.contains('surau'))                return 600;
    if (n.contains('gereja')  || n.contains('tokong'))               return 400;
    if (n.contains('dewan'))                                          return 350;
    if (n.contains('pusat') || n.contains('balai'))                  return 300;
    return 250;
  }

  double get occupancyRate =>
      effectiveCapacity > 0 ? (mangsa / effectiveCapacity).clamp(0.0, 1.0) : 0.0;

  Color get statusColor {
    final r = kapasiti > 0 ? kapasiti / 100.0 : occupancyRate;
    if (r >= 0.8) return const Color(0xFFB71C1C);
    if (r >= 0.4) return const Color(0xFFFFD600);
    return const Color(0xFF1B5E20);
  }

  String get statusLabel {
    final r = kapasiti > 0 ? kapasiti / 100.0 : occupancyRate;
    if (r >= 0.8) return 'NEARLY FULL';
    if (r >= 0.4) return 'MODERATE';
    return 'AVAILABLE';
  }

  String get formattedDate =>
      '${openedDate.day.toString().padLeft(2, '0')}/'
      '${openedDate.month.toString().padLeft(2, '0')}/'
      '${openedDate.year}';
}

class DisasterDistrict {
  final String disasterType;
  final String state;
  final String district;
  final int    ppsCount;
  final int    keluarga;
  final int    mangsa;
  final double kapasiti;
  final DateTime? openedDate;

  const DisasterDistrict({
    required this.disasterType,
    required this.state,
    required this.district,
    required this.ppsCount,
    required this.keluarga,
    required this.mangsa,
    required this.kapasiti,
    this.openedDate,
  });

  Color get statusColor {
    if (kapasiti >= 80) return const Color(0xFFB71C1C);
    if (kapasiti >= 40) return const Color(0xFFFFD600);
    return const Color(0xFF1B5E20);
  }

  String get statusLabel {
    if (kapasiti >= 80) return 'NEARLY FULL';
    if (kapasiti >= 40) return 'MODERATE';
    return 'AVAILABLE';
  }

  int get estimatedCapacity =>
      kapasiti > 0 ? (mangsa / (kapasiti / 100)).round() : 0;

  String get formattedOpenedDate {
    final d = openedDate;
    if (d == null) return 'N/A';
    return '${d.day.toString().padLeft(2,'0')}/'
        '${d.month.toString().padLeft(2,'0')}/${d.year}';
  }
}

class StateEntry {
  final String   state;
  final DateTime openedDate;
  final int      ppsCount;
  final int      districtsInvolved;
  final int      mangsa;
  final int      keluarga;

  const StateEntry({
    required this.state,
    required this.openedDate,
    required this.ppsCount,
    required this.districtsInvolved,
    required this.mangsa,
    required this.keluarga,
  });
}

class InfoBencanaResult {
  final int totalPPS;
  final int totalNegeri;
  final int totalKeluarga;
  final int totalMangsa;
  final List<DisasterDistrict> districts;
  final List<StateEntry>       states;
  final List<ActivePPS>        ppsList;
  final DateTime lastUpdated;
  final bool isLiveData;
  final MalaysiaState filteredState;

  const InfoBencanaResult({
    required this.totalPPS,
    required this.totalNegeri,
    required this.totalKeluarga,
    required this.totalMangsa,
    required this.districts,
    required this.states,
    required this.ppsList,
    required this.lastUpdated,
    this.isLiveData    = false,
    this.filteredState = MalaysiaState.all,
  });

  bool get hasActiveDisasters => totalPPS > 0;
}

// State Enum
enum MalaysiaState {
  all(0,            'All States'),
  johor(1,          'Johor'),
  kedah(2,          'Kedah'),
  kelantan(3,       'Kelantan'),
  melaka(4,         'Melaka'),
  negeriSembilan(5, 'Negeri Sembilan'),
  pahang(6,         'Pahang'),
  penang(7,         'Penang'),
  perak(8,          'Perak'),
  perlis(9,         'Perlis'),
  selangor(10,      'Selangor'),
  terengganu(11,    'Terengganu'),
  sabah(12,         'Sabah'),
  sarawak(13,       'Sarawak'),
  kl(14,            'Kuala Lumpur'),
  labuan(15,        'Labuan'),
  putrajaya(16,     'Putrajaya');

  const MalaysiaState(this.id, this.label);
  final int id;
  final String label;
}

// Service
class InfoBencanaService {
  static const _base = 'https://infobencanajkmv2.jkm.gov.my';
  static const _htmlHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/121.0.0.0 Mobile Safari/537.36',
    'Accept':          'text/html,application/xhtml+xml,*/*',
    'Accept-Language': 'en-US,en;q=0.9,ms;q=0.8',
    'Cache-Control':   'no-cache',
  };
  static const _jsonHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/121.0.0.0 Mobile Safari/537.36',
    'Accept':             'application/json, text/plain, */*',
    'Accept-Language':    'en-US,en;q=0.9,ms;q=0.8',
    'X-Requested-With':   'XMLHttpRequest',
    'Referer':            '$_base/landing/',
    'Cache-Control':      'no-cache',
  };

  Future<InfoBencanaResult> fetchActivePPS({
    MalaysiaState state = MalaysiaState.all,
  }) async {
    // STEP 1: Fetch HTML
    String? html;
    for (final url in [
      '$_base/landing/index.php?b=0&a=${state.id}',
      '$_base/bencana/index.php?b=0&a=${state.id}',
    ]) {
      try {
        print('HTML of infobencana: $url');
        final res = await http.get(Uri.parse(url), headers: _htmlHeaders)
            .timeout(const Duration(seconds: 18));
        print('${res.statusCode}  ${res.body.length}b');
        if (res.statusCode == 200 && res.body.length > 500) {
          html = _decode(res); break;
        }
      } catch (e) { print('$e'); }
    }

    if (html == null) {
      print('HTML fetch failed');
      return _fallback(state);
    }

    // Parse HTML
    final base = _parseHtml(html, state);
    if (base == null || !base.hasActiveDisasters) {
      print('No active disasters');
      return _fallback(state);
    }

    // STEP 2: Fetch PPS names from API
    final seasonId = _extractSeasonId(html);
    final ppsList = await _fetchPPSList(seasonId, base.districts, base.states);

    // print('${base.totalPPS} PPS, ${base.totalMangsa} evacuees, '
    //     '${ppsList.length} named');

    return InfoBencanaResult(
      totalPPS:      base.totalPPS,
      totalNegeri:   base.totalNegeri,
      totalKeluarga: base.totalKeluarga,
      totalMangsa:   base.totalMangsa,
      districts:     base.districts,
      states:        base.states,
      ppsList:       ppsList,
      lastUpdated:   base.lastUpdated,
      isLiveData:    true,
      filteredState: state,
    );
  }

  // ── Extract seasonmain_id ─────────────────────────────────────────

  String? _extractSeasonId(String html) {
    for (final re in [
      RegExp(r"""data-bs-seasonmain-id=['"](\d+)['"]"""),
      RegExp(r"""seasonmain_id[=:\s'"]+(\d+)""", caseSensitive: false),
    ]) {
      final m = re.firstMatch(html);
      if (m != null) return m.group(1);
    }
    return null;
  }

  // Fetch PPS list: endpoint is found from F12-network-fetch/XHR
  Future<List<ActivePPS>> _fetchPPSList(
    String? seasonId,
    List<DisasterDistrict> districts,
    List<StateEntry> states,
  ) async {
    if (seasonId == null) {
      print('No seasonmain_id');
      return _synthesisePPS(districts, states);
    }

    final urls = [
      // CORRECT endpoint
      '$_base/api/data-dashboard-table-pps.php?a=0&b=0&seasonmain_id=$seasonId&seasonnegeri_id=',
      // Backups
      '$_base/data-api-info-bencana-negeri.php?data=0&negeri=0',
    ];

    for (final url in urls) {
      try {
        final res = await http.get(Uri.parse(url), headers: _jsonHeaders)
            .timeout(const Duration(seconds: 12));
        final body = res.body.trim();
        print('${res.statusCode} ${body.length}b');

        if (res.statusCode != 200) continue;
        if (!body.startsWith('[') && !body.startsWith('{')) {
          print('Not JSON: ${body.substring(0, 50)}');
          continue;
        }

        dynamic parsed = jsonDecode(body);
        // API returns {"ppsbuka": [...]} 
        final List raw = parsed is List ? parsed
            : (parsed['ppsbuka'] ?? parsed['data'] ?? parsed['pps'] ?? []) as List;

        if (raw.isEmpty) {
          print('Empty array');
          continue;
        }

        print('${raw.length} rows');
        if (raw.isNotEmpty) {
          print('Keys: ${(raw[0] as Map).keys.take(10).toList()}');
        }

        final result = raw.map<ActivePPS>((r) {
          final name     = _s(r, ['nama','nama_pps']) ?? 'Unknown';
          final stateRaw = _s(r, ['negeri']) ?? '';
          final district = _s(r, ['daerah']) ?? '';
          final mukim    = _s(r, ['mukim']) ?? '';
          final buka     = _s(r, ['buka','tarikh_buka']);
          
          // API returns kapasiti as "64.8%" string, parse it
          final kapStr   = _s(r, ['kapasiti']) ?? '0%';
          final kap      = double.tryParse(kapStr.replaceAll('%', ''))?.round() ?? 0;
          
          final mangsa   = _i(r, ['mangsa']) ?? 0;
          final keluarga = _i(r, ['keluarga']) ?? 0;
          final lat      = _d(r, ['lat','latitude']);
          final lng      = _d(r, ['lng','longitude']);

          // Demographics
          final lelakiDewasa     = _i(r, ['lelaki_dewasa']) ?? 0;
          final perempuanDewasa  = _i(r, ['perempuan_dewasa']) ?? 0;
          final kanakLelaki      = _i(r, ['kanak_lelaki']) ?? 0;
          final kanakPerempuan   = _i(r, ['kanak_perempuan']) ?? 0;
          final bayiLelaki       = _i(r, ['bayi_lelaki']) ?? 0;
          final bayiPerempuan    = _i(r, ['bayi_perempuan']) ?? 0;

          // Opened date: API returns "09 Feb" or "12 Feb" format
          final openedDate = _parseBukaDate(buka);
          
          // Infer disaster type from API data or match with district
          final matchingDistrict = districts.where(
              (d) => d.district == district && d.state == _translateState(stateRaw)
          ).firstOrNull;
          final disaster = matchingDistrict?.disasterType ?? 'Flood';

          return ActivePPS(
            name:         name,
            state:        _translateState(stateRaw),
            district:     district,
            mukim:        mukim,
            disasterType: disaster,
            kapasiti:     kap,
            mangsa:       mangsa,
            keluarga:     keluarga,
            lat:          lat,
            lng:          lng,
            openedDate:   openedDate,
            lelakiDewasa: lelakiDewasa,
            perempuanDewasa: perempuanDewasa,
            kanakLelaki: kanakLelaki,
            kanakPerempuan: kanakPerempuan,
            bayiLelaki: bayiLelaki,
            bayiPerempuan: bayiPerempuan,
          );
        }).toList();

        return result;
      } catch (e, st) {
        print('$e');
        print(st.toString().split('\n').take(2).join('\n'));
      }
    }

    return _synthesisePPS(districts, states);
  }

  List<ActivePPS> _synthesisePPS(
      List<DisasterDistrict> districts, List<StateEntry> states) {
    return districts.map((d) {
      final stateEntry = states.where((s) => s.state == d.state).firstOrNull;
      final openedDate = d.openedDate ?? stateEntry?.openedDate ?? DateTime.now();
      return ActivePPS(
        name:         d.district,
        state:        d.state,
        district:     d.district,
        disasterType: d.disasterType,
        kapasiti:     d.kapasiti.round(),
        mangsa:       d.mangsa,
        keluarga:     d.keluarga,
        openedDate:   openedDate,
      );
    }).toList();
  }

  // HTML Parsing

  String _decode(http.Response res) {
    try { return utf8.decode(res.bodyBytes); } catch (_) { return res.body; }
  }

  InfoBencanaResult? _parseHtml(String html, MalaysiaState filterState) {
    try {
      final updatedTime = _parseUpdatedTime(html);
      final stats       = _parseSummaryStats(html);
      if (stats.length < 4) return null;
      final states    = _parseStateSidebar(html);
      final districts = _parseDistrictTable(html, states);
      return InfoBencanaResult(
        totalPPS:      stats[0], totalNegeri: stats[1],
        totalKeluarga: stats[2], totalMangsa: stats[3],
        districts:     districts, states:    states,
        ppsList:       [],
        lastUpdated:   updatedTime,
        isLiveData:    true, filteredState: filterState,
      );
    } catch (e) { print('$e'); return null; }
  }

  DateTime _parseUpdatedTime(String html) {
    final re = RegExp(
        r'Dikemaskini pada\s+(\d{1,2})\s+(\w+)\s+(\d{4}),?\s+(\d{1,2}):(\d{2})\s*(AM|PM)',
        caseSensitive: false);
    final m = re.firstMatch(html);
    if (m == null) return DateTime.now();
    final day  = int.parse(m.group(1)!);
    final mon  = _monthToInt(m.group(2)!);
    final yr   = int.parse(m.group(3)!);
    var   hr   = int.parse(m.group(4)!);
    final min  = int.parse(m.group(5)!);
    final ap   = m.group(6)!.toUpperCase();
    if (ap == 'PM' && hr != 12) hr += 12;
    if (ap == 'AM' && hr == 12) hr  = 0;
    return DateTime(yr, mon, day, hr, min);
  }

  List<int> _parseSummaryStats(String html) {
    final s = html.indexOf('audience-chart-header');
    final e = html.indexOf('statBukaTab', s);
    if (s == -1 || e == -1) return [];
    final block = html.substring(s, e);
    final re = RegExp(r'<h5[^>]*class="text-black[^"]*"[^>]*>(\d+)</h5>');
    return re.allMatches(block).map((m) => int.parse(m.group(1)!)).toList();
  }

  List<StateEntry> _parseStateSidebar(String html) {
    final start     = html.indexOf('id="listBukaMap"');
    if (start == -1) return [];
    final bodyStart = html.indexOf('card-body', start);
    if (bodyStart == -1) return [];
    final bodyEnd   = html.indexOf('col-lg-3 col-xl-3', bodyStart + 100);
    final block     = bodyEnd > bodyStart
        ? html.substring(bodyStart, bodyEnd)
        : html.substring(bodyStart, bodyStart + 8000);

    final result = <StateEntry>[];
    for (final entry in block.split('btn-reveal-trigger').skip(1)) {
      try {
        final nameMatch = RegExp(r'<a[^>]*>\s*([^<]+?)\s*</a>').firstMatch(entry);
        if (nameMatch == null) continue;
        final state = _translateState(nameMatch.group(1)!.trim());
        if (state.isEmpty) continue;

        final dateMatch = RegExp(r'Mula Buka:\s*(\d{1,2}/\d{1,2}/\d{4})')
            .firstMatch(entry);
        final date = dateMatch != null
            ? (_parseDate(dateMatch.group(1)) ?? DateTime.now()) : DateTime.now();

        final spans = RegExp(r'<span[^>]*class="fs-0"[^>]*>(\d+)</span>')
            .allMatches(entry).map((m) => int.parse(m.group(1)!)).toList();
        if (spans.length < 4) continue;

        result.add(StateEntry(
          state: state, openedDate: date,
          ppsCount: spans[0], districtsInvolved: spans[1],
          mangsa: spans[2], keluarga: spans[3],
        ));
      } catch (_) {}
    }
    return result;
  }

  List<DisasterDistrict> _parseDistrictTable(String html, List<StateEntry> states) {
    final tbodyStart = html.indexOf('table-group-divider');
    final tbodyEnd   = html.indexOf('</tbody>', tbodyStart);
    if (tbodyStart == -1 || tbodyEnd == -1) return [];
    final tbody  = html.substring(tbodyStart, tbodyEnd);
    final result = <DisasterDistrict>[];

    for (final row in tbody.split('<tr class="border-bottom border-200">').skip(1)) {
      try {
        final h6re  = RegExp(r'<h6 class="mb-0 ps-2">(.*?)</h6>', dotAll: true);
        final h6s   = h6re.allMatches(row)
            .map((m) => _stripTags(m.group(1)!))
            .where((t) => t.isNotEmpty)
            .toList();
        if (h6s.isEmpty) continue;

        final disaster = _translateDisaster(h6s[0]);
        final state    = h6s.length > 1 ? _translateState(h6s[1]) : '';
        final district = h6s.length > 2 ? h6s[2] : '';

        final h5re  = RegExp(r'<h5 class="mb-0 ps-2">(\d+)</h5>');
        final nums  = h5re.allMatches(row)
            .map((m) => int.parse(m.group(1)!)).toList();
        if (nums.length < 3) continue;

        final kapMatch = RegExp(r'([\d.]+)%</h5>').firstMatch(row);
        final kapasiti = kapMatch != null
            ? double.tryParse(kapMatch.group(1)!) ?? 0.0 : 0.0;

        final stateEntry = states.where((s) => s.state == state).firstOrNull;

        result.add(DisasterDistrict(
          disasterType: disaster,
          state:        state,
          district:     district,
          ppsCount:     nums[0],
          keluarga:     nums[1],
          mangsa:       nums[2],
          kapasiti:     kapasiti,
          openedDate:   stateEntry?.openedDate,
        ));
      } catch (_) {}
    }
    return result;
  }

  // Helpers

  String _stripTags(String s) =>
      s.replaceAll(RegExp(r'<[^>]+>'), ' ')
       .replaceAll(RegExp(r'\s+'), ' ').trim();

  String? _s(dynamic r, List<String> keys) {
    for (final k in keys) {
      final v = r[k];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    return null;
  }

  int? _i(dynamic r, List<String> keys) {
    for (final k in keys) {
      final v = r[k];
      if (v != null) return int.tryParse(v.toString());
    }
    return null;
  }

  double? _d(dynamic r, List<String> keys) {
    for (final k in keys) {
      final v = r[k];
      if (v != null) {
        final d = double.tryParse(v.toString());
        if (d != null && d != 0.0) return d;
      }
    }
    return null;
  }

  DateTime? _parseDate(String? v) {
    if (v == null || v.isEmpty) return null;
    try {
      if (v.contains('/')) {
        final p = v.split('/');
        if (p.length == 3) {
          return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
        }
      }
      return DateTime.tryParse(v);
    } catch (_) { return null; }
  }

  /// Parse "09 Feb" or "12 Feb" format from API
  DateTime _parseBukaDate(String? v) {
    if (v == null || v.isEmpty) return DateTime.now();
    try {
      // Format: "09 Feb" or "12 Feb"
      final parts = v.trim().split(' ');
      if (parts.length >= 2) {
        final day = int.parse(parts[0]);
        final mon = _monthToInt(parts[1]);
        final year = DateTime.now().year; // Current year
        return DateTime(year, mon, day);
      }
    } catch (_) {}
    return DateTime.now();
  }

  int _monthToInt(String m) {
    const months = {'jan':1,'feb':2,'mar':3,'apr':4,'may':5,'jun':6,
        'jul':7,'aug':8,'sep':9,'oct':10,'nov':11,'dec':12};
    return months[m.toLowerCase().substring(0, 3)] ?? 1;
  }

  String _translateState(String s) {
    const m = {
      'johor':'Johor','kedah':'Kedah','kelantan':'Kelantan',
      'melaka':'Melaka','negeri sembilan':'Negeri Sembilan',
      'pahang':'Pahang','pulau pinang':'Penang','perak':'Perak',
      'perlis':'Perlis','selangor':'Selangor','terengganu':'Terengganu',
      'sabah':'Sabah','sarawak':'Sarawak','kuala lumpur':'Kuala Lumpur',
      'labuan':'Labuan','putrajaya':'Putrajaya',
    };
    return m[s.toLowerCase().trim()] ?? s.trim();
  }

  String _translateDisaster(String s) {
    final l = s.toLowerCase();
    if (l.contains('banjir'))                         return 'Flood';
    if (l.contains('kebakaran'))                      return 'Fire';
    if (l.contains('tanah') || l.contains('runtuh'))  return 'Landslide';
    return s.isEmpty ? 'Disaster' : s;
  }

  // Fallback data
  InfoBencanaResult _fallback(MalaysiaState filterState) {
    final allDistricts = [
      DisasterDistrict(disasterType:'Flood', state:'Kelantan',     district:'Kuala Krai',  ppsCount:1, keluarga:0,   mangsa:0,   kapasiti:0.0,  openedDate:DateTime(2026,2,9)),
      DisasterDistrict(disasterType:'Flood', state:'Sabah',        district:'Beaufort',    ppsCount:1, keluarga:227, mangsa:483, kapasiti:48.3, openedDate:DateTime(2026,2,12)),
      DisasterDistrict(disasterType:'Fire',  state:'Johor',        district:'Johor Bahru', ppsCount:1, keluarga:39,  mangsa:141, kapasiti:94.0, openedDate:DateTime(2026,2,12)),
      DisasterDistrict(disasterType:'Fire',  state:'Sarawak',      district:'Miri',        ppsCount:1, keluarga:1,   mangsa:13,  kapasiti:2.6,  openedDate:DateTime(2026,1,13)),
      DisasterDistrict(disasterType:'Fire',  state:'Kuala Lumpur', district:'Sentul',      ppsCount:1, keluarga:1,   mangsa:1,   kapasiti:2.0,  openedDate:DateTime(2026,2,9)),
    ];
    final allStates = [
      StateEntry(state:'Sabah',        openedDate:DateTime(2026,2,12), ppsCount:1, districtsInvolved:1, mangsa:483, keluarga:227),
      StateEntry(state:'Johor',        openedDate:DateTime(2026,2,12), ppsCount:1, districtsInvolved:1, mangsa:141, keluarga:39),
      StateEntry(state:'Sarawak',      openedDate:DateTime(2026,1,13), ppsCount:1, districtsInvolved:1, mangsa:13,  keluarga:1),
      StateEntry(state:'Kuala Lumpur', openedDate:DateTime(2026,2,9),  ppsCount:1, districtsInvolved:1, mangsa:1,   keluarga:1),
      StateEntry(state:'Kelantan',     openedDate:DateTime(2026,2,9),  ppsCount:1, districtsInvolved:1, mangsa:0,   keluarga:0),
    ];
    final allPPS = [
      ActivePPS(name:'Pusat Pendaftaran Mangsa JPBD Kuala Krai', state:'Kelantan',     district:'Kuala Krai',  mukim:'Bandar Kuala Krai', disasterType:'Flood', kapasiti:0,  mangsa:0,   keluarga:0,  openedDate:DateTime(2026,2,9)),
      ActivePPS(name:'Pusat Pemindahan Kekal Selagon, Beaufort Sabah', state:'Sabah',  district:'Beaufort',    mukim:'N.32 Klias',        disasterType:'Flood', kapasiti:48, mangsa:483, keluarga:227,openedDate:DateTime(2026,2,12)),
      ActivePPS(name:'Dewan Muafakat Taman Megah Ria',           state:'Johor',        district:'Johor Bahru', mukim:'Plentong',          disasterType:'Fire',  kapasiti:94, mangsa:141, keluarga:39, openedDate:DateTime(2026,2,12)),
      ActivePPS(name:'KPG Sukan Petronas',                       state:'Sarawak',      district:'Miri',        mukim:'Miri/Piasau',       disasterType:'Fire',  kapasiti:3,  mangsa:13,  keluarga:1,  openedDate:DateTime(2026,1,13)),
      ActivePPS(name:'Dewan Komuniti Sentul Perdana',            state:'Kuala Lumpur', district:'Sentul',      mukim:'Batu',              disasterType:'Fire',  kapasiti:2,  mangsa:1,   keluarga:1,  openedDate:DateTime(2026,2,9)),
    ];
    return InfoBencanaResult(
      totalPPS:5, totalNegeri:5, totalKeluarga:268, totalMangsa:638,
      districts:allDistricts, states:allStates, ppsList:allPPS,
      lastUpdated:DateTime(2026,2,14,11,42), isLiveData:false,
      filteredState:filterState,
    );
  }
}