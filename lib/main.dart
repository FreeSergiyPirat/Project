import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'statistics_page.dart';

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
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  List<Transaction> _transactions = [];
  List<Account> _accounts = [const Account(id: 'main', name: 'Основной')];
  String _currentAccountId = 'main';

  Account get _currentAccount => _accounts.firstWhere(
        (a) => a.id == _currentAccountId,
        orElse: () => _accounts.first,
      );

  List<Transaction> get _currentTransactions =>
      _transactions.where((t) => t.accountId == _currentAccountId).toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawTx = prefs.getString('transactions');
    final rawAccounts = prefs.getString('accounts');

    setState(() {
      if (rawAccounts != null) {
        final list = jsonDecode(rawAccounts) as List;
        final loaded = list
            .map((e) => Account.fromJson(e as Map<String, dynamic>))
            .toList();
        if (loaded.isNotEmpty) _accounts = loaded;
      }
      if (rawTx != null) {
        final list = jsonDecode(rawTx) as List;
        _transactions = list
            .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'transactions',
      jsonEncode(_transactions.map((t) => t.toJson()).toList()),
    );
    await prefs.setString(
      'accounts',
      jsonEncode(_accounts.map((a) => a.toJson()).toList()),
    );
  }

  void _add(Transaction t) {
    setState(() => _transactions.add(t));
    _save();
  }

  void _selectAccount(Account account) {
    setState(() => _currentAccountId = account.id);
  }

  void _addAccount(String name) {
    final id = 'acc_${DateTime.now().millisecondsSinceEpoch}';
    final account = Account(id: id, name: name);
    setState(() {
      _accounts.add(account);
      _currentAccountId = id;
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          BalancePage(
            transactions: _currentTransactions,
            currentAccount: _currentAccount,
            accounts: _accounts,
            onAdd: _add,
            onAccountSelect: _selectAccount,
            onAddAccount: _addAccount,
          ),
          StatisticsPage(transactions: _currentTransactions),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Главная',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Анализ',
          ),
        ],
      ),
    );
  }
}

class BalancePage extends StatefulWidget {
  final List<Transaction> transactions;
  final Account currentAccount;
  final List<Account> accounts;
  final void Function(Transaction) onAdd;
  final void Function(Account) onAccountSelect;
  final void Function(String) onAddAccount;

  const BalancePage({
    super.key,
    required this.transactions,
    required this.currentAccount,
    required this.accounts,
    required this.onAdd,
    required this.onAccountSelect,
    required this.onAddAccount,
  });

  @override
  State<BalancePage> createState() => _BalancePageState();
}

class _BalancePageState extends State<BalancePage> {
  bool _isIncome = false;
  final TextEditingController _amountController = TextEditingController();
  Category? _selectedCategory;
  String _selectedDate = 'Сегодня';
  final List<Category> _extraCategories = [];
  final List<Category> _extraIncomeCategories = [];

  double get _balance => widget.transactions.fold(
        0.0,
        (sum, t) => sum + (t.isIncome ? t.amount : -t.amount),
      );

  void _apply() {
    final input = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (input == null || input <= 0 || _selectedCategory == null) return;
    widget.onAdd(Transaction(
      amount: input,
      isIncome: _isIncome,
      categoryName: _selectedCategory!.name,
      categoryIconCode: _selectedCategory!.icon.codePoint,
      categoryFontFamily: _selectedCategory!.icon.fontFamily ?? 'MaterialIcons',
      categoryColor: _selectedCategory!.color.value,
      date: _selectedDate,
      accountId: widget.currentAccount.id,
    ));
    _amountController.clear();
  }

  void _showAccountSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AccountSelectorSheet(
        accounts: widget.accounts,
        currentAccountId: widget.currentAccount.id,
        onSelect: (acc) {
          widget.onAccountSelect(acc);
        },
        onAddTap: _showAddAccountDialog,
      ),
    );
  }

  void _showAddAccountDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Новый счет'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Название счета',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(context);
              widget.onAddAccount(name);
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  Future<void> _openCategoryPicker() async {
    final result = await Navigator.push<Category>(
      context,
      MaterialPageRoute(
          builder: (_) => CategoryPickerPage(isIncome: _isIncome)),
    );
    if (result != null) {
      setState(() {
        _selectedCategory = result;
        if (_isIncome) {
          if (!kDefaultIncomeCategories.any((c) => c.name == result.name) &&
              !_extraIncomeCategories.any((c) => c.name == result.name)) {
            _extraIncomeCategories.add(result);
          }
        } else {
          if (!kDefaultCategories.any((c) => c.name == result.name) &&
              !_extraCategories.any((c) => c.name == result.name)) {
            _extraCategories.add(result);
          }
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

  List<Category> get _displayCategories => _isIncome
      ? [...kDefaultIncomeCategories, ..._extraIncomeCategories]
      : [...kDefaultCategories, ..._extraCategories];

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
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: _showAccountSheet,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.currentAccount.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: scheme.onSurface.withOpacity(0.7),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
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
                            onTap: () => setState(() {
                              _isIncome = true;
                              _selectedCategory = null;
                            }),
                          ),
                          _SegmentButton(
                            label: 'Расходы',
                            selected: !_isIncome,
                            color: Colors.red.shade600,
                            onTap: () => setState(() {
                              _isIncome = false;
                              _selectedCategory = null;
                            }),
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
                      isIncome: _isIncome,
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

class _AccountSelectorSheet extends StatelessWidget {
  final List<Account> accounts;
  final String currentAccountId;
  final void Function(Account) onSelect;
  final VoidCallback onAddTap;

  const _AccountSelectorSheet({
    required this.accounts,
    required this.currentAccountId,
    required this.onSelect,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Счета',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...accounts.map((acc) {
              final isSelected = acc.id == currentAccountId;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSelected
                      ? scheme.primary
                      : scheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: isSelected ? scheme.onPrimary : scheme.onSurface,
                    size: 20,
                  ),
                ),
                title: Text(
                  acc.name,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check, color: scheme.primary)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  onSelect(acc);
                },
              );
            }),
            const Divider(height: 1),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: scheme.surfaceContainerHighest,
                child: Icon(Icons.add, color: scheme.onSurface, size: 20),
              ),
              title: const Text('Добавить счет'),
              onTap: () {
                Navigator.pop(context);
                onAddTap();
              },
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
  final bool isIncome;

  const _CategoryGrid({
    required this.categories,
    required this.selected,
    required this.onSelect,
    required this.onMore,
    required this.isIncome,
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
          return _MoreButton(onTap: onMore, isIncome: isIncome);
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
  final bool isIncome;

  const _MoreButton({required this.onTap, required this.isIncome});

  @override
  Widget build(BuildContext context) {
    final color =
        isIncome ? const Color(0xFF2E7D32) : const Color(0xFFBDBDBD);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
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
  final bool isIncome;

  const CategoryPickerPage({super.key, required this.isIncome});

  @override
  State<CategoryPickerPage> createState() => _CategoryPickerPageState();
}

class _CategoryPickerPageState extends State<CategoryPickerPage> {
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  List<Category> get _sourceCategories =>
      widget.isIncome ? kAllIncomeCategories : kAllCategories;

  List<Category> get _filtered => _sourceCategories
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
        isIncome: widget.isIncome,
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
    final accentColor =
        widget.isIncome ? Colors.green.shade700 : scheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.isIncome ? 'Категория дохода' : 'Добавить категорию'),
        centerTitle: true,
        elevation: 0,
        foregroundColor: widget.isIncome ? Colors.green.shade800 : null,
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
                icon: Icon(Icons.add, color: accentColor),
                label: Text(
                  'Создать',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: accentColor),
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
  final bool isIncome;

  const _CreateCategoryDialog(
      {required this.onCreated, required this.isIncome});

  @override
  State<_CreateCategoryDialog> createState() =>
      _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends State<_CreateCategoryDialog> {
  final TextEditingController _nameController = TextEditingController();
  late Color _selectedColor;
  IconData _selectedIcon = Icons.star;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.isIncome
        ? const Color(0xFF2E7D32)
        : const Color(0xFF1E88E5);
  }

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
