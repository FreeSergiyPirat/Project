import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Balance Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const BalancePage(),
    );
  }
}

class Category {
  final String name;
  final IconData icon;
  final Color color;

  const Category({required this.name, required this.icon, required this.color});
}

const List<Category> kDefaultCategories = [
  Category(name: 'Здоровье', icon: Icons.favorite, color: Color(0xFFE53935)),
  Category(name: 'Досуг', icon: Icons.beach_access, color: Color(0xFF00ACC1)),
  Category(name: 'Дом', icon: Icons.home, color: Color(0xFFFF7043)),
  Category(name: 'Кафе', icon: Icons.restaurant, color: Color(0xFF8E24AA)),
  Category(name: 'Образование', icon: Icons.school, color: Color(0xFF1E88E5)),
  Category(name: 'Подарки', icon: Icons.card_giftcard, color: Color(0xFFEC407A)),
  Category(name: 'Продукты', icon: Icons.shopping_basket, color: Color(0xFF43A047)),
];

const List<Category> kAllCategories = [
  Category(name: 'Здоровье', icon: Icons.favorite, color: Color(0xFFE53935)),
  Category(name: 'Досуг', icon: Icons.beach_access, color: Color(0xFF00ACC1)),
  Category(name: 'Дом', icon: Icons.home, color: Color(0xFFFF7043)),
  Category(name: 'Кафе', icon: Icons.restaurant, color: Color(0xFF8E24AA)),
  Category(name: 'Образование', icon: Icons.school, color: Color(0xFF1E88E5)),
  Category(name: 'Подарки', icon: Icons.card_giftcard, color: Color(0xFFEC407A)),
  Category(name: 'Продукты', icon: Icons.shopping_basket, color: Color(0xFF43A047)),
  Category(name: 'Семья', icon: Icons.people, color: Color(0xFFFF7043)),
  Category(name: 'Спорт', icon: Icons.fitness_center, color: Color(0xFF1565C0)),
  Category(name: 'Транспорт', icon: Icons.directions_bus, color: Color(0xFF546E7A)),
  Category(name: 'Кофе', icon: Icons.local_cafe, color: Color(0xFF6D4C41)),
  Category(name: 'Игры', icon: Icons.sports_esports, color: Color(0xFF3949AB)),
  Category(name: 'Такси', icon: Icons.local_taxi, color: Color(0xFFF9A825)),
  Category(name: 'Долг', icon: Icons.account_balance_wallet, color: Color(0xFFC62828)),
  Category(name: 'Путешествия', icon: Icons.flight, color: Color(0xFF00838F)),
  Category(name: 'Одежда', icon: Icons.checkroom, color: Color(0xFFD81B60)),
  Category(name: 'Красота', icon: Icons.face, color: Color(0xFFAD1457)),
  Category(name: 'Животные', icon: Icons.pets, color: Color(0xFF5D4037)),
  Category(name: 'Авто', icon: Icons.directions_car, color: Color(0xFF455A64)),
  Category(name: 'Связь', icon: Icons.phone, color: Color(0xFF00695C)),
  Category(name: 'Аптека', icon: Icons.local_pharmacy, color: Color(0xFF2E7D32)),
  Category(name: 'Кино', icon: Icons.movie, color: Color(0xFF6A1B9A)),
];

class BalancePage extends StatefulWidget {
  const BalancePage({super.key});

  @override
  State<BalancePage> createState() => _BalancePageState();
}

class _BalancePageState extends State<BalancePage> {
  double _balance = 0.0;
  bool _isIncome = false;
  final TextEditingController _amountController = TextEditingController();
  Category? _selectedCategory;
  String _selectedDate = 'Сегодня';
  final List<Category> _extraCategories = [];

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _balance = prefs.getDouble('balance') ?? 0.0;
    });
  }

  Future<void> _saveBalance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('balance', _balance);
  }

  void _apply() {
    final input = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (input == null || input <= 0) return;
    setState(() {
      _balance += _isIncome ? input : -input;
    });
    _saveBalance();
    _amountController.clear();
  }

  Future<void> _openCategoryPicker() async {
    final result = await Navigator.push<Category>(
      context,
      MaterialPageRoute(builder: (_) => const CategoryPickerPage()),
    );
    if (result != null) {
      setState(() {
        _selectedCategory = result;
        if (!kDefaultCategories.any((c) => c.name == result.name) &&
            !_extraCategories.any((c) => c.name == result.name)) {
          _extraCategories.add(result);
        }
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate =
            '${picked.day.toString().padLeft(2, '0')}.${picked.month.toString().padLeft(2, '0')}.${picked.year}';
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  List<Category> get _displayCategories =>
      [...kDefaultCategories, ..._extraCategories];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final actionColor =
        _isIncome ? Colors.green.shade600 : Colors.red.shade600;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Баланс',
                      style: TextStyle(
                        fontSize: 16,
                        color: scheme.onSurface.withOpacity(0.55),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_balance >= 0 ? '+' : ''}${_balance.toStringAsFixed(2)} ₽',
                      style: TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.bold,
                        color: _balance >= 0
                            ? Colors.green.shade600
                            : Colors.red.shade600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _SegmentButton(
                            label: 'Доходы',
                            selected: _isIncome,
                            color: Colors.green.shade600,
                            onTap: () => setState(() => _isIncome = true),
                          ),
                          _SegmentButton(
                            label: 'Расходы',
                            selected: !_isIncome,
                            color: Colors.red.shade600,
                            onTap: () => setState(() => _isIncome = false),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _CategoryGrid(
                      categories: _displayCategories,
                      selected: _selectedCategory,
                      onSelect: (cat) =>
                          setState(() => _selectedCategory = cat),
                      onMore: _openCategoryPicker,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _apply,
                        style: FilledButton.styleFrom(
                          backgroundColor: actionColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Применить',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _DatePickerBar(
              selected: _selectedDate,
              onSelect: (d) => setState(() => _selectedDate = d),
              onCalendar: _pickDate,
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: selected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final Category? selected;
  final void Function(Category) onSelect;
  final VoidCallback onMore;

  const _CategoryGrid({
    required this.categories,
    required this.selected,
    required this.onSelect,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.82,
      ),
      itemCount: categories.length + 1,
      itemBuilder: (context, i) {
        if (i == categories.length) {
          return _MoreButton(onTap: onMore);
        }
        final cat = categories[i];
        return _CategoryItem(
          category: cat,
          isSelected: selected?.name == cat.name,
          onTap: () => onSelect(cat),
        );
      },
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: category.color,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: category.color.withOpacity(0.55),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 2.5)
                  : null,
            ),
            child: Icon(category.icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 5),
          Text(
            category.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MoreButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFBDBDBD),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 5),
          const Text(
            'Ещё',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _DatePickerBar extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;
  final VoidCallback onCalendar;

  const _DatePickerBar({
    required this.selected,
    required this.onSelect,
    required this.onCalendar,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const presets = ['Сегодня', 'Вчера', 'Последняя'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          ...presets.map((label) {
            final isSelected = selected == label;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => onSelect(label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? scheme.primary
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? scheme.onPrimary
                          : scheme.onSurface,
                    ),
                  ),
                ),
              ),
            );
          }),
          if (!presets.contains(selected))
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                selected,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: scheme.onPrimary,
                ),
              ),
            ),
          const Spacer(),
          IconButton(
            onPressed: onCalendar,
            icon: Icon(Icons.calendar_today_outlined,
                color: scheme.onSurface, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class CategoryPickerPage extends StatefulWidget {
  const CategoryPickerPage({super.key});

  @override
  State<CategoryPickerPage> createState() => _CategoryPickerPageState();
}

class _CategoryPickerPageState extends State<CategoryPickerPage> {
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  List<Category> get _filtered => kAllCategories
      .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
      .toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (_) => _CreateCategoryDialog(
        onCreated: (cat) {
          Navigator.pop(context);
          Navigator.pop(context, cat);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить категорию'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Поиск категории',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: scheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      'Ничего не найдено',
                      style: TextStyle(
                          color: scheme.onSurface.withOpacity(0.5)),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: _filtered.length,
                    itemBuilder: (context, i) {
                      final cat = _filtered[i];
                      return _CategoryItem(
                        category: cat,
                        isSelected: false,
                        onTap: () => Navigator.pop(context, cat),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.add),
                label: const Text(
                  'Создать',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateCategoryDialog extends StatefulWidget {
  final void Function(Category) onCreated;

  const _CreateCategoryDialog({required this.onCreated});

  @override
  State<_CreateCategoryDialog> createState() =>
      _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends State<_CreateCategoryDialog> {
  final TextEditingController _nameController = TextEditingController();
  Color _selectedColor = const Color(0xFF1E88E5);
  IconData _selectedIcon = Icons.star;

  static const _colors = [
    Color(0xFFE53935), Color(0xFF43A047), Color(0xFF1E88E5),
    Color(0xFF8E24AA), Color(0xFFFF7043), Color(0xFFEC407A),
    Color(0xFF00ACC1), Color(0xFFF9A825),
  ];

  static const _icons = [
    Icons.star, Icons.favorite, Icons.home, Icons.work,
    Icons.directions_car, Icons.flight, Icons.shopping_bag, Icons.local_cafe,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Новая категория'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Название',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          const Text('Цвет',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _colors
                .map((c) => GestureDetector(
                      onTap: () => setState(() => _selectedColor = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c,
                          border: _selectedColor == c
                              ? Border.all(color: Colors.black87, width: 2.5)
                              : null,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 14),
          const Text('Иконка',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _icons
                .map((ic) => GestureDetector(
                      onTap: () => setState(() => _selectedIcon = ic),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _selectedIcon == ic
                              ? _selectedColor
                              : Colors.grey.shade200,
                        ),
                        child: Icon(
                          ic,
                          size: 20,
                          color: _selectedIcon == ic
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            widget.onCreated(
              Category(
                  name: name, icon: _selectedIcon, color: _selectedColor),
            );
          },
          child: const Text('Создать'),
        ),
      ],
    );
  }
}
