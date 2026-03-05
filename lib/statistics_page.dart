import 'package:flutter/material.dart';
import 'models.dart';

const _kMonths = [
  'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
  'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
];

const _kMonthsShort = [
  'янв', 'фев', 'мар', 'апр', 'май', 'июн',
  'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
];

class _CatTotal {
  final String name;
  final int iconCode;
  final String fontFamily;
  final int color;
  double amount;

  _CatTotal({
    required this.name,
    required this.iconCode,
    required this.fontFamily,
    required this.color,
    required this.amount,
  });
}

class StatisticsPage extends StatefulWidget {
  final List<Transaction> transactions;

  const StatisticsPage({super.key, required this.transactions});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  static const _bg = Color(0xFF0E1018);
  static const _surface = Color(0xFF181B27);
  static const _divider = Color(0xFF252840);

  final _periods = const ['День', 'Неделя', 'Месяц', 'Год', 'Период'];
  String _period = 'Месяц';
  late DateTime _ref;

  @override
  void initState() {
    super.initState();
    _ref = DateTime.now();
  }

  void _shift(int dir) => setState(() {
        _ref = switch (_period) {
          'День' => _ref.add(Duration(days: dir)),
          'Неделя' => _ref.add(Duration(days: 7 * dir)),
          'Месяц' => DateTime(_ref.year, _ref.month + dir),
          'Год' => DateTime(_ref.year + dir),
          _ => _ref,
        };
      });

  String get _navLabel => switch (_period) {
        'День' =>
          '${_ref.day} ${_kMonths[_ref.month - 1]} ${_ref.year}',
        'Неделя' => _weekLabel(),
        'Месяц' => '${_kMonths[_ref.month - 1]} ${_ref.year}',
        'Год' => '${_ref.year}',
        _ => 'Весь период',
      };

  String _weekLabel() {
    final s = _ref.subtract(Duration(days: _ref.weekday - 1));
    final e = s.add(const Duration(days: 6));
    if (s.month == e.month) {
      return '${s.day}–${e.day} ${_kMonthsShort[s.month - 1]} ${s.year}';
    }
    return '${s.day} ${_kMonthsShort[s.month - 1]} – ${e.day} ${_kMonthsShort[e.month - 1]}';
  }

  DateTime? _parseDate(String d) {
    final now = DateTime.now();
    if (d == 'Сегодня') return now;
    if (d == 'Вчера') return now.subtract(const Duration(days: 1));
    if (d == 'Последняя') return now;
    final p = d.split('.');
    if (p.length == 3) {
      try {
        return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
      } catch (_) {}
    }
    return null;
  }

  bool _inPeriod(DateTime d) {
    switch (_period) {
      case 'День':
        return d.year == _ref.year &&
            d.month == _ref.month &&
            d.day == _ref.day;
      case 'Неделя':
        final ws = _ref.subtract(Duration(days: _ref.weekday - 1));
        final start = DateTime(ws.year, ws.month, ws.day);
        final end = start.add(const Duration(days: 6, hours: 23, minutes: 59));
        return !d.isBefore(start) && !d.isAfter(end);
      case 'Месяц':
        return d.year == _ref.year && d.month == _ref.month;
      case 'Год':
        return d.year == _ref.year;
      default:
        return true;
    }
  }

  List<_CatTotal> get _totals {
    final map = <String, _CatTotal>{};
    for (final t in widget.transactions) {
      if (t.isIncome) continue;
      final d = _parseDate(t.date);
      if (d == null || !_inPeriod(d)) continue;
      map.update(
        t.categoryName,
        (c) => c..amount += t.amount,
        ifAbsent: () => _CatTotal(
          name: t.categoryName,
          iconCode: t.categoryIconCode,
          fontFamily: t.categoryFontFamily,
          color: t.categoryColor,
          amount: t.amount,
        ),
      );
    }
    return map.values.toList()..sort((a, b) => b.amount.compareTo(a.amount));
  }

  String _fmt(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('\u202F');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final totals = _totals;
    final total = totals.fold(0.0, (s, t) => s + t.amount);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _PeriodTabs(
              periods: _periods,
              selected: _period,
              surface: _surface,
              onSelect: (p) => setState(() => _period = p),
            ),
            _NavRow(
              label: _navLabel,
              showArrows: _period != 'Период',
              onPrev: () => _shift(-1),
              onNext: () => _shift(1),
            ),
            Container(height: 1, color: _divider),
            Expanded(
              child: totals.isEmpty
                  ? const Center(
                      child: Text(
                        'Нет данных',
                        style: TextStyle(color: Color(0xFF4B5068), fontSize: 16),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                      children: [
                        _ColorBar(totals: totals, total: total),
                        const SizedBox(height: 8),
                        _TotalRow(total: total, fmt: _fmt),
                        const SizedBox(height: 20),
                        ...totals.map(
                          (t) => _CategoryRow(
                            cat: t,
                            total: total,
                            fmt: _fmt,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  final List<String> periods;
  final String selected;
  final Color surface;
  final void Function(String) onSelect;

  const _PeriodTabs({
    required this.periods,
    required this.selected,
    required this.surface,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: surface,
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: periods.map((p) {
          final sel = p == selected;
          return GestureDetector(
            onTap: () => onSelect(p),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  p,
                  style: TextStyle(
                    color: sel ? Colors.white : const Color(0xFF4B5068),
                    fontSize: 13,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 2,
                  width: sel ? 30 : 0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final String label;
  final bool showArrows;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _NavRow({
    required this.label,
    required this.showArrows,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: showArrows ? onPrev : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Icon(
                Icons.chevron_left,
                color: showArrows ? Colors.white : Colors.transparent,
                size: 28,
              ),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          GestureDetector(
            onTap: showArrows ? onNext : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Icon(
                Icons.chevron_right,
                color: showArrows ? Colors.white : Colors.transparent,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorBar extends StatelessWidget {
  final List<_CatTotal> totals;
  final double total;

  const _ColorBar({required this.totals, required this.total});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 22,
        child: Row(
          children: totals
              .map(
                (t) => Expanded(
                  flex: ((t.amount / total) * 1000).round().clamp(1, 1000),
                  child: Container(color: Color(t.color)),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final double total;
  final String Function(double) fmt;

  const _TotalRow({required this.total, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Расходы',
            style: TextStyle(color: Color(0xFF4B5068), fontSize: 13),
          ),
          Text(
            '${fmt(total)} ₽',
            style: const TextStyle(
              color: Color(0xFF4B5068),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final _CatTotal cat;
  final double total;
  final String Function(double) fmt;

  const _CategoryRow({
    required this.cat,
    required this.total,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? cat.amount / total * 100 : 0.0;
    final icon = IconData(cat.iconCode, fontFamily: cat.fontFamily);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(cat.color),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cat.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: total > 0 ? cat.amount / total : 0,
                    backgroundColor: const Color(0xFF252840),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(cat.color)),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 44,
            child: Text(
              '${pct.toStringAsFixed(1)}%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${fmt(cat.amount)} ₽',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
