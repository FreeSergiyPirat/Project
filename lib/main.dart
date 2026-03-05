import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'statistics_page.dart';

const _kPrimary = Color(0xFF6C5DD3);
const _kPrimaryLight = Color(0xFFC1B9F9);
const _kBg = Color(0xFFF8F9FE);
const _kCard = Color(0xFFFFFFFF);
const _kText = Color(0xFF1A1D2E);
const _kTextSub = Color(0xFF9BA3AF);

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: _kPrimary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: _kBg,
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
  int _visualIndex = 0;
  List<Transaction> _transactions = [];
  List<Account> _accounts = [const Account(id: 'main', name: 'Основной')];
  String _currentAccountId = 'main';

  int get _pageIndex => _visualIndex == 2 ? 1 : 0;

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

  void _showWalletsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WalletsSheet(
        accounts: _accounts,
        transactions: _transactions,
        currentAccountId: _currentAccountId,
        onSelect: (acc) {
          Navigator.pop(context);
          _selectAccount(acc);
          setState(() => _visualIndex = 0);
        },
        onAddTap: () {
          Navigator.pop(context);
          _showAddAccountShellDialog();
        },
      ),
    );
  }

  void _showAddAccountShellDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: _kCard,
        title: const Text('Новый счет',
            style: TextStyle(color: _kText, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Название счета',
            hintStyle: const TextStyle(color: _kTextSub),
            filled: true,
            fillColor: _kBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Отмена', style: TextStyle(color: _kTextSub)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_kPrimary, _kPrimaryLight]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  final name = ctrl.text.trim();
                  if (name.isEmpty) return;
                  Navigator.pop(context);
                  _addAccount(name);
                  setState(() => _visualIndex = 0);
                },
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Создать',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: IndexedStack(
        index: _pageIndex,
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
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: _visualIndex,
        onTap: (i) {
          if (i == 1) {
            _showWalletsSheet();
          } else {
            setState(() => _visualIndex = i);
          }
        },
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onTap;

  const _BottomNavBar({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, Icons.home_outlined, 'Главная'),
      (Icons.account_balance_wallet_rounded,
          Icons.account_balance_wallet_outlined, 'Кошельки'),
      (Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Аналитика'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withOpacity(0.10),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isSelected = selectedIndex == i;
              final (activeIcon, inactiveIcon, label) = items[i];
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _kPrimary.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? activeIcon : inactiveIcon,
                        color: isSelected ? _kPrimary : _kTextSub,
                        size: 24,
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        child: isSelected
                            ? Row(children: [
                                const SizedBox(width: 6),
                                Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _kPrimary,
                                  ),
                                ),
                              ])
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: _kCard,
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: _kCard,
        title: const Text(
          'Новый счет',
          style: TextStyle(color: _kText, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Название счета',
            hintStyle: const TextStyle(color: _kTextSub),
            filled: true,
            fillColor: _kBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена', style: TextStyle(color: _kTextSub)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_kPrimary, _kPrimaryLight]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  final name = ctrl.text.trim();
                  if (name.isEmpty) return;
                  Navigator.pop(context);
                  widget.onAddAccount(name);
                },
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Создать',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
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
    final isInc = _isIncome;
    final gradColors = isInc
        ? [const Color(0xFF43A047), const Color(0xFF81C784)]
        : [const Color(0xFFE53935), const Color(0xFFEF9A9A)];
    final actionColor =
        isInc ? const Color(0xFF43A047) : const Color(0xFFE53935);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Привет, Пользователь!',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: _kText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Управляй своими финансами',
                                style:
                                    TextStyle(fontSize: 13, color: _kTextSub),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _showAccountSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _kCard,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.currentAccount.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _kPrimary,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.keyboard_arrow_down,
                                    color: _kPrimary, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kPrimary, _kPrimaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: _kPrimary.withOpacity(0.40),
                            blurRadius: 30,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Текущий баланс',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_balance >= 0 ? '+' : ''}${_balance.toStringAsFixed(2)} ₽',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.currentAccount.name,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.22),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      decoration: BoxDecoration(
                        color: _kCard,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _SegmentButton(
                            label: 'Доходы',
                            selected: _isIncome,
                            color: const Color(0xFF43A047),
                            onTap: () => setState(() {
                              _isIncome = true;
                              _selectedCategory = null;
                            }),
                          ),
                          _SegmentButton(
                            label: 'Расходы',
                            selected: !_isIncome,
                            color: const Color(0xFFE53935),
                            onTap: () => setState(() {
                              _isIncome = false;
                              _selectedCategory = null;
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: _kCard,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]')),
                        ],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: _kText,
                        ),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: const TextStyle(
                            color: _kTextSub,
                            fontSize: 26,
                            fontWeight: FontWeight.w400,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _CategoryGrid(
                      categories: _displayCategories,
                      selected: _selectedCategory,
                      onSelect: (cat) =>
                          setState(() => _selectedCategory = cat),
                      onMore: _openCategoryPicker,
                      isIncome: _isIncome,
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradColors,
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: actionColor.withOpacity(0.38),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _apply,
                          borderRadius: BorderRadius.circular(28),
                          child: const Center(
                            child: Text(
                              'Применить',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
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
                color: _kTextSub.withOpacity(0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Счета',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _kText),
            ),
            const SizedBox(height: 8),
            ...accounts.map((acc) {
              final isSelected = acc.id == currentAccountId;
              return ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [_kPrimary, _kPrimaryLight],
                          )
                        : null,
                    color: isSelected ? null : _kBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: isSelected ? Colors.white : _kTextSub,
                    size: 20,
                  ),
                ),
                title: Text(
                  acc.name,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.normal,
                    color: _kText,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: _kPrimary)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  onSelect(acc);
                },
              );
            }),
            Divider(height: 1, color: _kBg),
            ListTile(
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _kPrimary.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: _kPrimary, size: 20),
              ),
              title: const Text(
                'Добавить счет',
                style: TextStyle(
                    color: _kPrimary, fontWeight: FontWeight.w600),
              ),
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
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : _kTextSub,
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
                        blurRadius: 12,
                        spreadRadius: 2,
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
              color: _kText,
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
              gradient: LinearGradient(
                colors: isIncome
                    ? [const Color(0xFF43A047), const Color(0xFF81C784)]
                    : [_kPrimary, _kPrimaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 5),
          const Text(
            'Ещё',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: _kTextSub),
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
    const presets = ['Сегодня', 'Вчера', 'Последняя'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          ...presets.map((label) {
            final isSelected = selected == label;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSelect(label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [_kPrimary, _kPrimaryLight],
                          )
                        : null,
                    color: isSelected ? null : _kBg,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : _kTextSub,
                    ),
                  ),
                ),
              ),
            );
          }),
          if (!presets.contains(selected))
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_kPrimary, _kPrimaryLight]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                selected,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          const Spacer(),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _kPrimary.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: onCalendar,
              icon: const Icon(Icons.calendar_today_rounded,
                  color: _kPrimary, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
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
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCard,
        elevation: 0,
        title: Text(
          widget.isIncome ? 'Категория дохода' : 'Добавить категорию',
          style: const TextStyle(
            color: _kText,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: _kPrimary),
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Поиск категории',
                  hintStyle: const TextStyle(color: _kTextSub),
                  prefixIcon:
                      const Icon(Icons.search, color: _kTextSub),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 0, horizontal: 16),
                ),
              ),
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Ничего не найдено',
                      style: TextStyle(color: _kTextSub),
                    ),
                  )
                : GridView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_kPrimary, _kPrimaryLight]),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: _kPrimary.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showCreateDialog,
                  borderRadius: BorderRadius.circular(28),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Создать',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
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

class _WalletsSheet extends StatelessWidget {
  final List<Account> accounts;
  final List<Transaction> transactions;
  final String currentAccountId;
  final void Function(Account) onSelect;
  final VoidCallback onAddTap;

  const _WalletsSheet({
    required this.accounts,
    required this.transactions,
    required this.currentAccountId,
    required this.onSelect,
    required this.onAddTap,
  });

  double _balanceFor(String accountId) {
    return transactions
        .where((t) => t.accountId == accountId)
        .fold(0.0, (sum, t) => sum + (t.isIncome ? t.amount : -t.amount));
  }

  String _fmtBalance(double v) {
    return '${v >= 0 ? '+' : ''}${v.toStringAsFixed(2)} ₽';
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.80),
      decoration: const BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: _kTextSub.withOpacity(0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Мои счета',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _kText,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: accounts.length,
              itemBuilder: (context, i) {
                final acc = accounts[i];
                final balance = _balanceFor(acc.id);
                final isSelected = acc.id == currentAccountId;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => onSelect(acc),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [_kPrimary, _kPrimaryLight],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : _kBg,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: _kPrimary.withOpacity(0.30),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                )
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.22)
                                  : _kPrimary.withOpacity(0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.account_balance_wallet_rounded,
                              color: isSelected ? Colors.white : _kPrimary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  acc.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : _kText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isSelected
                                      ? 'Активный счёт'
                                      : 'Нажмите для переключения',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected
                                        ? Colors.white70
                                        : _kTextSub,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _fmtBalance(balance),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : _kText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad + 16),
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                border: Border.all(color: _kPrimary, width: 1.5),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onAddTap,
                  borderRadius: BorderRadius.circular(28),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: _kPrimary),
                      SizedBox(width: 8),
                      Text(
                        'Добавить новый счёт',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                        ),
                      ),
                    ],
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
    _selectedColor =
        widget.isIncome ? const Color(0xFF2E7D32) : _kPrimary;
  }

  static const _colors = [
    Color(0xFFE53935),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFF6C5DD3),
    Color(0xFFFF7043),
    Color(0xFFEC407A),
    Color(0xFF00ACC1),
    Color(0xFFF9A825),
  ];

  static const _icons = [
    Icons.star,
    Icons.favorite,
    Icons.home,
    Icons.work,
    Icons.directions_car,
    Icons.flight,
    Icons.shopping_bag,
    Icons.local_cafe,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: _kCard,
      title: const Text(
        'Новая категория',
        style:
            TextStyle(color: _kText, fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Название',
              hintStyle: const TextStyle(color: _kTextSub),
              filled: true,
              fillColor: _kBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),
          const Text('Цвет',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kText)),
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
                              ? Border.all(
                                  color: _kText, width: 2.5)
                              : null,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 14),
          const Text('Иконка',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kText)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _icons
                .map((ic) => GestureDetector(
                      onTap: () =>
                          setState(() => _selectedIcon = ic),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _selectedIcon == ic
                              ? const LinearGradient(
                                  colors: [_kPrimary, _kPrimaryLight],
                                )
                              : null,
                          color:
                              _selectedIcon == ic ? null : _kBg,
                        ),
                        child: Icon(
                          ic,
                          size: 20,
                          color: _selectedIcon == ic
                              ? Colors.white
                              : _kTextSub,
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
          child: const Text('Отмена',
              style: TextStyle(color: _kTextSub)),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [_kPrimary, _kPrimaryLight]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                final name = _nameController.text.trim();
                if (name.isEmpty) return;
                widget.onCreated(
                  Category(
                      name: name,
                      icon: _selectedIcon,
                      color: _selectedColor),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Создать',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
