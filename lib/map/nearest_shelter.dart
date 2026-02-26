// map/nearest_shelter.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/pps_service.dart';
import '../services/infobencana_service.dart';

class ImpactEstimator {
  static int estimatePPSNeeded(int affected, {int avgCapacity = 150}) =>
      (affected / avgCapacity).ceil().clamp(1, 999);
  static bool isOverflowRisk({
    required int predictedAffected,
    required int totalRemainingCapacity,
  }) =>
      predictedAffected > totalRemainingCapacity;
}

class ShelterPage extends StatefulWidget {
  final double latitude;
  final double longitude;
  const ShelterPage({super.key, required this.latitude, required this.longitude});

  @override
  State<ShelterPage> createState() => _ShelterPageState();
}

class _ShelterPageState extends State<ShelterPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _placesService      = PlacesShelterService();
  final _infoBencanaService = InfoBencanaService();

  List<NearbyShelter> _nearby      = [];
  InfoBencanaResult?  _activeResult;
  bool _loadingNearby = true;
  bool _loadingActive = true;
  String  _typeFilter  = 'all';
  String? _stateFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNearby();
    _loadActive();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _loadNearby() async {
    setState(() => _loadingNearby = true);
    final list = await _placesService.fetchNearby(widget.latitude, widget.longitude);
    print('DEBUG nearby result: ${list.length} shelters');
    if (mounted) setState(() { _nearby = list; _loadingNearby = false; });
  }

  Future<void> _loadActive() async {
    setState(() => _loadingActive = true);
    final r = await _infoBencanaService.fetchActivePPS();
    if (mounted) setState(() { _activeResult = r; _loadingActive = false; });
  }

  // ── Derived ───────────────────────────────────────────────────

  List<NearbyShelter> get _filteredNearby {
    if (_typeFilter == 'all') return _nearby;
    return _nearby.where((s) => s.shelterType.filterKey == _typeFilter).toList();
  }

  List<ActivePPS> get _filteredPPS {
    final all = _activeResult?.ppsList ?? [];
    if (_stateFilter == null) return all;
    return all.where((p) => p.state == _stateFilter).toList();
  }

  List<String> get _activeStateNames {
    final r = _activeResult;
    if (r == null) return [];
    if (r.states.isNotEmpty) {
      return (r.states.map((s) => s.state).toSet().toList()..sort());
    }
    return (r.ppsList.map((p) => p.state).toSet().toList()..sort());
  }

  // ── Occupancy helper ──────────────────────────────────────────
  // Derives % from evacuees / effectiveCapacity for consistency.
  // Falls back to API kapasiti only if effectiveCapacity is 0.

  double _occupancyPct(ActivePPS p) {
    if (p.effectiveCapacity > 0) {
      return (p.mangsa / p.effectiveCapacity * 100).clamp(0.0, 999.0);
    }
    return p.kapasiti.toDouble();
  }

  // ── URL helpers ───────────────────────────────────────────────

  Future<void> _openDirections(double lat, double lon, String name) async {
    final app = Uri.parse('comgooglemaps://?daddr=$lat,$lon&directionsmode=driving');
    final web = Uri.parse(_placesService.directionsUrl(lat, lon, name));
    if (await canLaunchUrl(app)) await launchUrl(app);
    else await launchUrl(web, mode: LaunchMode.externalApplication);
  }

  Future<void> _searchMaps(String query) async {
    await launchUrl(Uri.parse(_placesService.searchUrl(query)),
        mode: LaunchMode.externalApplication);
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _stateFilter == null,
      onPopInvoked: (didPop) {
        if (!didPop && _stateFilter != null) setState(() => _stateFilter = null);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _appBar(),
        body: Column(children: [
          _tabBar(),
          Expanded(child: TabBarView(
            controller: _tabController,
            children: [_nearbyTab(), _activeTab()],
          )),
        ]),
      ),
    );
  }

  AppBar _appBar() => AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3748)),
      onPressed: () {
        if (_stateFilter != null) setState(() => _stateFilter = null);
        else Navigator.pop(context);
      },
    ),
    title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Evacuation Centers',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
              color: Color(0xFF2D3748))),
      Text(
        _stateFilter != null ? 'Filtering: $_stateFilter'
            : 'Pusat Pemindahan Sementara (PPS)',
        style: TextStyle(fontSize: 10,
            color: _stateFilter != null
                ? const Color(0xFF4285F4) : const Color(0xFF6B7280),
            fontStyle: FontStyle.italic,
            fontWeight: _stateFilter != null ? FontWeight.w600 : FontWeight.normal),
      ),
    ]),
    actions: [
      IconButton(
        icon: const Icon(Icons.refresh, color: Color(0xFF4285F4)),
        onPressed: () { _loadNearby(); _loadActive(); },
      ),
    ],
  );

  Widget _tabBar() {
    final badge = _activeResult?.totalPPS ?? 0;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12)),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(color: const Color(0xFF4285F4),
              borderRadius: BorderRadius.circular(10)),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF6B7280),
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: [
            const Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.location_on, size: 15), SizedBox(width: 5),
              Text('Nearby Shelters'),
            ])),
            Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.emergency, size: 15),
              const SizedBox(width: 5),
              const Text('Active PPS'),
              if (badge > 0) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: Colors.red,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text('$badge', style: const TextStyle(fontSize: 10,
                      fontWeight: FontWeight.w700, color: Colors.white))),
              ],
            ])),
          ],
        ),
      ),
    );
  }

  // ══ TAB 1: NEARBY ════════════════════════════════════════════

  Widget _nearbyTab() => Column(children: [
    _filterBar(),
    Expanded(child: _loadingNearby
        ? const Center(child: CircularProgressIndicator())
        : _filteredNearby.isEmpty
            ? _emptyState('No shelters found nearby', Icons.search_off)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredNearby.length,
                itemBuilder: (_, i) => _shelterCard(_filteredNearby[i]))),
  ]);

  Widget _filterBar() {
    const chips = [
      ('all','All',Icons.filter_list), ('school','School',Icons.school),
      ('mosque','Mosque',Icons.mosque), ('church','Church',Icons.church),
      ('stadium','Stadium',Icons.stadium), ('hall','Hall',Icons.home_work),
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: SizedBox(height: 34, child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (value, label, icon) = chips[i];
          final sel = _typeFilter == value;
          return GestureDetector(
            onTap: () => setState(() => _typeFilter = value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFF4285F4) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(17)),
              child: Row(children: [
                Icon(icon, size: 13,
                    color: sel ? Colors.white : const Color(0xFF6B7280)),
                const SizedBox(width: 4),
                Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : const Color(0xFF6B7280))),
              ]),
            ),
          );
        },
      )),
    );
  }

  Widget _shelterCard(NearbyShelter s) {
    final dist  = s.distanceTo(widget.latitude, widget.longitude);
    final color = s.shelterType.color;
    return Card(
      margin: const EdgeInsets.only(bottom: 10), elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.grey.shade200)),
      color: Colors.white,
      child: InkWell(onTap: () => _showShelterSheet(s),
        borderRadius: BorderRadius.circular(14),
        child: Padding(padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(s.shelterType.icon, color: color, size: 22)),
            const SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(s.name, style: const TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 5),
              Row(children: [
                _pill(s.shelterType.label, color), const SizedBox(width: 8),
                Icon(Icons.location_on, size: 11, color: Colors.grey.shade500),
                Text('${dist.toStringAsFixed(1)} km',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ]),
              const SizedBox(height: 4),
              Text(s.address, style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 5),
              Row(children: [
                Icon(Icons.people_outline, size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 3),
                Text('Est. capacity: ~${s.estimatedCapacity} people',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ]),
            ])),
            Column(children: [
              IconButton(
                onPressed: () => _openDirections(s.latitude, s.longitude, s.name),
                icon: const Icon(Icons.directions, color: Color(0xFF4285F4), size: 22),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF4285F4).withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.all(8)),
                tooltip: 'Get Directions'),
              if (s.rating != null) ...[
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.star, size: 11, color: Color(0xFFFBBC05)),
                  Text(s.rating!.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 10)),
                ]),
              ],
            ]),
          ]),
        ),
      ),
    );
  }

  // ══ TAB 2: ACTIVE PPS ════════════════════════════════════════

  Widget _activeTab() {
    if (_loadingActive) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
          children: [
        CircularProgressIndicator(), SizedBox(height: 14),
        Text('Fetching live data from InfoBencana JKM...',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
      ]));
    }
    final r = _activeResult;
    if (r == null || !r.hasActiveDisasters) return _noActiveDisasters();

    final ppsList = _filteredPPS;

    return ListView(padding: const EdgeInsets.all(16), children: [
      _activeHeader(r),
      const SizedBox(height: 12),
      _summaryRow(r),
      const SizedBox(height: 12),
      _impactCard(r),
      const SizedBox(height: 16),
      _stateFilterBar(r),
      const SizedBox(height: 12),
      Text(
        _stateFilter != null
            ? 'Active PPS — $_stateFilter (${ppsList.length})'
            : 'Active Evacuation Centers (${ppsList.length})',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
            color: Color(0xFF2D3748))),
      const SizedBox(height: 8),
      ...ppsList.isEmpty
          ? [_emptyState('No active PPS in ${_stateFilter ?? "this area"}',
              Icons.search_off)]
          : ppsList.map(_ppsCard),
      const SizedBox(height: 10),
      _footer(r),
    ]);
  }

  Widget _activeHeader(InfoBencanaResult r) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade300, width: 1.5)),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.red.shade700,
              borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.warning_rounded, color: Colors.white, size: 20)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ACTIVE DISASTER IN MALAYSIA',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                color: Colors.red.shade900)),
        const SizedBox(height: 2),
        Text(r.isLiveData ? 'Live data · InfoBencana JKM'
            : 'Cached data · InfoBencana JKM',
            style: TextStyle(fontSize: 11, color: Colors.red.shade700)),
      ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
            color: r.isLiveData ? Colors.green.shade700 : Colors.orange.shade700,
            borderRadius: BorderRadius.circular(6)),
        child: Text(r.isLiveData ? 'LIVE' : 'CACHED',
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                color: Colors.white, letterSpacing: 0.5))),
    ]),
  );

  Widget _summaryRow(InfoBencanaResult r) => Row(children: [
    _statChip('${r.totalPPS}',      'PPS OPEN',  Icons.home_work,       Colors.red),
    const SizedBox(width: 8),
    _statChip('${r.totalNegeri}',   'STATES',    Icons.map,             Colors.orange),
    const SizedBox(width: 8),
    _statChip('${r.totalKeluarga}', 'FAMILIES',  Icons.family_restroom, Colors.blue),
    const SizedBox(width: 8),
    _statChip('${r.totalMangsa}',   'EVACUEES',  Icons.people,          Colors.purple),
  ]);

  Widget _statChip(String value, String label, IconData icon, Color color) =>
      Expanded(child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(color: color.withOpacity(0.09),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.25))),
        child: Column(children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 17,
              fontWeight: FontWeight.w700, color: color)),
          Text(label, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280), letterSpacing: 0.3),
              textAlign: TextAlign.center),
        ]),
      ));

  Widget _impactCard(InfoBencanaResult r) {
    final affected  = r.totalMangsa > 0 ? r.totalMangsa : 500;
    final ppsNeeded = ImpactEstimator.estimatePPSNeeded(affected);
    final totalCap  = r.ppsList.fold<int>(0, (s, p) => s + p.effectiveCapacity);
    final remaining = (totalCap - r.totalMangsa).clamp(0, totalCap);
    final overflow  = ImpactEstimator.isOverflowRisk(
        predictedAffected: affected, totalRemainingCapacity: remaining);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: overflow
            ? [Colors.red.shade50, Colors.red.shade100]
            : [Colors.purple.shade50, Colors.purple.shade100]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: overflow ? Colors.red.shade300 : Colors.purple.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.analytics,
              color: overflow ? Colors.red.shade700 : Colors.purple.shade700, size: 18),
          const SizedBox(width: 8),
          const Text('Human Impact Estimation', style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2D3748))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _impactMetric('👥 Total Evacuees', _fmt(affected), 'people')),
          const SizedBox(width: 10),
          Expanded(child: _impactMetric('🏫 Min PPS Required', '$ppsNeeded', 'centers')),
        ]),
        if (overflow) ...[
          const SizedBox(height: 10),
          Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(8)),
            child: const Row(children: [
              Icon(Icons.warning_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text('OVERFLOW RISK: Demand may exceed capacity.',
                  style: TextStyle(fontSize: 11, color: Colors.white,
                      fontWeight: FontWeight.w600))),
            ])),
        ] else ...[
          const SizedBox(height: 6),
          Text('Est. remaining capacity: $remaining seats',
              style: TextStyle(fontSize: 11, color: Colors.purple.shade700)),
        ],
        const SizedBox(height: 4),
        Text('Capacity estimated from InfoBencana occupancy %',
            style: TextStyle(fontSize: 9, color: Colors.grey.shade600,
                fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _impactMetric(String label, String value, String unit) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
      const SizedBox(height: 4),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(value, style: const TextStyle(fontSize: 22,
            fontWeight: FontWeight.w700, color: Color(0xFF2D3748))),
        const SizedBox(width: 4),
        Padding(padding: const EdgeInsets.only(bottom: 3),
            child: Text(unit, style: const TextStyle(fontSize: 11,
                color: Color(0xFF6B7280)))),
      ]),
    ]),
  );

  // ── State filter bar ──────────────────────────────────────────

  Widget _stateFilterBar(InfoBencanaResult r) {
    final stateNames = _activeStateNames;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.filter_list, size: 14, color: Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Text('Active States (${stateNames.length})',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280))),
        const Spacer(),
        if (_stateFilter != null)
          GestureDetector(
            onTap: () => setState(() => _stateFilter = null),
            child: const Text('Clear', style: TextStyle(fontSize: 11,
                color: Color(0xFF4285F4), fontWeight: FontWeight.w600))),
      ]),
      const SizedBox(height: 8),
      SizedBox(height: 36, child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _stateChip(
            label: 'All', count: r.totalPPS,
            selected: _stateFilter == null,
            onTap: () => setState(() => _stateFilter = null)),
          const SizedBox(width: 8),
          ...stateNames.map((stateName) {
            final count = r.ppsList.where((p) => p.state == stateName).length;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _stateChip(
                label: stateName,
                count: count,
                selected: _stateFilter == stateName,
                onTap: () => setState(() => _stateFilter = stateName)));
          }),
        ],
      )),
    ]);
  }

  Widget _stateChip({
    required String label, required int count,
    required bool selected, required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE5E7EB) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD1D5DB))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: selected ? const Color(0xFF111827) : const Color(0xFF374151))),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFD1D5DB) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10)),
                child: Text('$count', style: TextStyle(fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? const Color(0xFF111827) : const Color(0xFF6B7280)))),
            ],
          ]),
        ),
      );

  // ── Individual PPS card ───────────────────────────────────────

  Widget _ppsCard(ActivePPS p) {
    final statusColor  = p.statusColor;
    final occupancyPct = _occupancyPct(p);
    final occupancyStr = '${occupancyPct.toStringAsFixed(1)}%';

    return Card(
      margin: const EdgeInsets.only(bottom: 10), elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: statusColor.withOpacity(0.4), width: 1.5)),
      color: Colors.white,
      child: InkWell(
        onTap: () => _showPPSSheet(p),
        borderRadius: BorderRadius.circular(14),
        child: Padding(padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 4, height: 48,
                  decoration: BoxDecoration(color: statusColor,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(p.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                        color: Color(0xFF2D3748)),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${p.district}  ·  ${p.state}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                _pill(p.statusLabel, statusColor),
                const SizedBox(height: 4),
                _pill(p.disasterType, p.disasterType == 'Flood'
                    ? const Color(0xFF4285F4) : Colors.orange),
              ]),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _distStat(Icons.people,          '${p.mangsa}',   'Evacuees'),
              const SizedBox(width: 16),
              _distStat(Icons.family_restroom, '${p.keluarga}', 'Families'),
              const SizedBox(width: 16),
              _distStat(Icons.home_work,
                  p.effectiveCapacity > 0 ? '~${p.effectiveCapacity}' : 'N/A',
                  'Capacity'),
              const Spacer(),
              IconButton(
                onPressed: () {
                  if (p.lat != null) {
                    _openDirections(p.lat!, p.lng!, p.name);
                  } else {
                    _searchMaps('${p.name} ${p.state} Malaysia');
                  }
                },
                icon: const Icon(Icons.directions, color: Color(0xFF4285F4), size: 20),
                style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF4285F4).withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.all(7)),
                tooltip: 'Get Directions'),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (occupancyPct / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(statusColor))),
            const SizedBox(height: 3),
            Text(
              '$occupancyStr occupied  '
              '(${p.mangsa} / ${p.effectiveCapacity} people)  ·  '
              'Opened ${p.formattedDate}',
              style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
          ]),
        ),
      ),
    );
  }

  // ── Individual PPS detail sheet ───────────────────────────────

  void _showPPSSheet(ActivePPS p) {
    final occupancyPct    = _occupancyPct(p);
    final hasDemographics = p.lelakiDewasa > 0 || p.perempuanDewasa > 0 ||
        p.kanakLelaki > 0 || p.kanakPerempuan > 0;

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _sheet(
        height: hasDemographics ? 0.72 : 0.62,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _handle(), const SizedBox(height: 14),
            Row(children: [
              _pill(p.statusLabel, p.statusColor),
              const SizedBox(width: 8),
              _pill(p.disasterType, p.disasterType == 'Flood'
                  ? const Color(0xFF4285F4) : Colors.orange),
            ]),
            const SizedBox(height: 10),
            Text(p.name, style: const TextStyle(fontSize: 18,
                fontWeight: FontWeight.w700, color: Color(0xFF2D3748))),
            const SizedBox(height: 14),
            _row(Icons.location_city,   'District',  p.district),
            _row(Icons.map,             'State',     p.state),
            if (p.mukim.isNotEmpty)
              _row(Icons.place,         'Mukim',     p.mukim),
            _row(Icons.warning_amber,   'Disaster',  p.disasterType),
            _row(Icons.people,          'Evacuees',  '${p.mangsa} people'),
            _row(Icons.family_restroom, 'Families',  '${p.keluarga} families'),
            _row(Icons.home_work,       'Capacity',
                p.effectiveCapacity > 0
                    ? '~${p.effectiveCapacity} people  '
                      '(${occupancyPct.toStringAsFixed(1)}% occupied)'
                    : '${occupancyPct.toStringAsFixed(1)}% occupied'),
            _row(Icons.calendar_today,  'Opened',    p.formattedDate),
            if (hasDemographics) ...[
              const SizedBox(height: 4),
              const Divider(height: 20),
              const Text('Demographics',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: Color(0xFF2D3748))),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _demoStat('👨', '${p.lelakiDewasa}',    'Adult M')),
                Expanded(child: _demoStat('👩', '${p.perempuanDewasa}', 'Adult F')),
                Expanded(child: _demoStat('👦', '${p.kanakLelaki}',     'Boy')),
                Expanded(child: _demoStat('👧', '${p.kanakPerempuan}',  'Girl')),
                Expanded(child: _demoStat('👶',
                    '${p.bayiLelaki + p.bayiPerempuan}', 'Infant')),
              ]),
            ],
            const SizedBox(height: 20),
            SizedBox(width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  if (p.lat != null) {
                    _openDirections(p.lat!, p.lng!, p.name);
                  } else {
                    _searchMaps('${p.name} ${p.state} Malaysia');
                  }
                },
                icon: const Icon(Icons.directions),
                label: const Text('Get Directions'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4285F4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))))),
          ]),
        ),
      ),
    );
  }

  Widget _demoStat(String emoji, String value, String label) => Column(children: [
    Text(emoji, style: const TextStyle(fontSize: 18)),
    const SizedBox(height: 2),
    Text(value, style: const TextStyle(fontSize: 13,
        fontWeight: FontWeight.w700, color: Color(0xFF2D3748))),
    Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
  ]);

  Widget _footer(InfoBencanaResult r) {
    final t = r.lastUpdated;
    final updated =
        '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}/${t.year} '
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Icon(Icons.info_outline, size: 13, color: Colors.grey.shade600),
        const SizedBox(width: 7),
        Expanded(child: Text(
          'Source: InfoBencana JKM · ${r.isLiveData ? "Live" : "Cached"} · Updated: $updated',
          style: TextStyle(fontSize: 9, color: Colors.grey.shade600,
              fontStyle: FontStyle.italic))),
      ]),
    );
  }

  Widget _noActiveDisasters() => Center(
    child: Padding(padding: const EdgeInsets.all(40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.green.shade50,
                shape: BoxShape.circle),
            child: Icon(Icons.check_circle, size: 60, color: Colors.green.shade600)),
        const SizedBox(height: 18),
        const Text('No Active Disasters', style: TextStyle(fontSize: 20,
            fontWeight: FontWeight.w700, color: Color(0xFF2D3748))),
        const SizedBox(height: 6),
        Text('No PPS currently active.\nAll centers on standby.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(height: 20),
        OutlinedButton.icon(onPressed: _loadActive,
            icon: const Icon(Icons.refresh), label: const Text('Refresh'),
            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF4285F4),
                side: const BorderSide(color: Color(0xFF4285F4)))),
      ]),
    ),
  );

  void _showShelterSheet(NearbyShelter s) {
    final dist = s.distanceTo(widget.latitude, widget.longitude);
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _sheet(height: 0.55, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        _handle(), const SizedBox(height: 18),
        Row(children: [
          Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: s.shelterType.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(s.shelterType.icon, color: s.shelterType.color, size: 26)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.name, style: const TextStyle(fontSize: 17,
                fontWeight: FontWeight.w700, color: Color(0xFF2D3748))),
            const SizedBox(height: 4),
            _pill(s.shelterType.label, s.shelterType.color),
          ])),
        ]),
        const SizedBox(height: 18), const Divider(height: 1), const SizedBox(height: 14),
        _row(Icons.location_on,   'Address',       s.address),
        _row(Icons.straighten,    'Distance',      '${dist.toStringAsFixed(2)} km away'),
        _row(Icons.people,        'Est. Capacity', '~${s.estimatedCapacity} people'),
        if (s.rating != null)
          _row(Icons.star, 'Google Rating', '${s.rating!.toStringAsFixed(1)} / 5.0'),
        _row(Icons.info_outline,  'PPS Status',    'Designated shelter – standby'),
        const Spacer(),
        SizedBox(width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _openDirections(s.latitude, s.longitude, s.name),
            icon: const Icon(Icons.directions), label: const Text('Get Directions'),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4285F4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))))),
      ])));
  }

  // ── Shared ────────────────────────────────────────────────────

  Widget _sheet({required double height, required Widget child}) => Container(
    height: MediaQuery.of(context).size.height * height,
    decoration: const BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    padding: const EdgeInsets.all(22), child: child);

  Widget _handle() => Center(child: Container(width: 38, height: 4,
      decoration: BoxDecoration(color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2))));

  Widget _pill(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(5)),
    child: Text(text, style: TextStyle(fontSize: 10,
        fontWeight: FontWeight.w700, color: color)));

  Widget _row(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 17, color: Colors.grey.shade500),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        Text(value, style: const TextStyle(fontSize: 13,
            fontWeight: FontWeight.w600, color: Color(0xFF2D3748))),
      ])),
    ]));

  Widget _distStat(IconData icon, String value, String label) =>
      Column(children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13,
            fontWeight: FontWeight.w700, color: Color(0xFF2D3748))),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
      ]);

  Widget _emptyState(String msg, IconData icon) => Padding(
    padding: const EdgeInsets.all(40),
    child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 56, color: Colors.grey.shade400),
      const SizedBox(height: 14),
      Text(msg, style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          textAlign: TextAlign.center),
    ])));

  String _fmt(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
}