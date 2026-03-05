import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'models.dart';

const _kPrimary = Color(0xFF6C5DD3);
const _kPrimaryLight = Color(0xFFC1B9F9);
const _kBg = Color(0xFFF8F9FE);
const _kCard = Color(0xFFFFFFFF);
const _kText = Color(0xFF1A1D2E);
const _kTextSub = Color(0xFF9BA3AF);
const _kDivider = Color(0xFFEEEEF5);

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
  static const _bg = _kBg;
  static const _surface = _kCard;
  static const _divider = _kDivider;

  final _periods = const ['День', 'Неделя', 'Месяц', 'Год', 'Период'];
  String _period = 'Месяц';
  bool _isIncome = false;
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
        'День' => '${_ref.day} ${_kMonths[_ref.month - 1]} ${_ref.year}',
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
      if (t.isIncome != _isIncome) continue;
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
            _TypeToggle(
              isIncome: _isIncome,
              surface: _surface,
              onToggle: (v) => setState(() => _isIncome = v),
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
                        style: TextStyle(color: _kTextSub, fontSize: 16),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                      children: [
                        Center(
                          child: _DonutChart(
                            totals: totals,
                            total: total,
                            fmt: _fmt,
                            isIncome: _isIncome,
                          ),
                        ),
                        const SizedBox(height: 28),
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

class _TypeToggle extends StatelessWidget {
  final bool isIncome;
  final Color surface;
  final void Function(bool) onToggle;

  const _TypeToggle({
    required this.isIncome,
    required this.surface,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    const expenseColor = Color(0xFFEF5350);
    const incomeColor = Color(0xFF26C17B);

    return Container(
      color: surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _ToggleBtn(
              label: 'Расходы',
              selected: !isIncome,
              activeColor: expenseColor,
              onTap: () => onToggle(false),
            ),
            _ToggleBtn(
              label: 'Доходы',
              selected: isIncome,
              activeColor: incomeColor,
              onTap: () => onToggle(true),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? activeColor.withOpacity(0.13)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: selected
                ? Border.all(
                    color: activeColor.withOpacity(0.40), width: 1)
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? activeColor : _kTextSub,
            ),
          ),
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
                    color: sel ? _kPrimary : _kTextSub,
                    fontSize: 13,
                    fontWeight:
                        sel ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 2,
                  width: sel ? 30 : 0,
                  decoration: BoxDecoration(
                    gradient: sel
                        ? const LinearGradient(
                            colors: [_kPrimary, _kPrimaryLight])
                        : null,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(height: 10),
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
                color: showArrows ? _kPrimary : Colors.transparent,
                size: 28,
              ),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: _kText,
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
                color: showArrows ? _kPrimary : Colors.transparent,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutChart extends StatelessWidget {
  final List<_CatTotal> totals;
  final double total;
  final String Function(double) fmt;
  final bool isIncome;

  const _DonutChart({
    required this.totals,
    required this.total,
    required this.fmt,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(220, 220),
            painter: _DonutPainter(totals: totals, total: total),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isIncome ? 'Доходы' : 'Расходы',
                style: const TextStyle(
                  fontSize: 12,
                  color: _kTextSub,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${fmt(total)} ₽',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _kText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<_CatTotal> totals;
  final double total;

  _DonutPainter({required this.totals, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 6;
    final strokeWidth = outerRadius * 0.34;
    final r = outerRadius - strokeWidth / 2;

    double startAngle = -math.pi / 2;

    for (final t in totals) {
      final sweep = (t.amount / total) * 2 * math.pi;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt
        ..color = Color(t.color);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        startAngle + 0.025,
        sweep - 0.05,
        false,
        paint,
      );
      startAngle += sweep;
    }

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = _kBg;

    if (totals.length == 1) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        -math.pi / 2,
        2 * math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = Color(totals.first.color),
      );
    }
    bgPaint.color = Colors.transparent;
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.totals != totals || old.total != total;
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
    final catColor = Color(cat.color);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: catColor.withOpacity(0.14),
            ),
            child: Icon(icon, color: catColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        cat.name,
                        style: const TextStyle(
                          color: _kText,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${pct.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: _kTextSub,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0 ? cat.amount / total : 0,
                    backgroundColor: _kBg,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(catColor),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '${fmt(cat.amount)} ₽',
            style: const TextStyle(
              color: _kText,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
