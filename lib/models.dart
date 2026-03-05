import 'package:flutter/material.dart';

class Category {
  final String name;
  final IconData icon;
  final Color color;

  const Category({required this.name, required this.icon, required this.color});
}

class Transaction {
  final double amount;
  final bool isIncome;
  final String categoryName;
  final int categoryIconCode;
  final String categoryFontFamily;
  final int categoryColor;
  final String date;

  Transaction({
    required this.amount,
    required this.isIncome,
    required this.categoryName,
    required this.categoryIconCode,
    required this.categoryFontFamily,
    required this.categoryColor,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'isIncome': isIncome,
        'categoryName': categoryName,
        'categoryIconCode': categoryIconCode,
        'categoryFontFamily': categoryFontFamily,
        'categoryColor': categoryColor,
        'date': date,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        amount: (json['amount'] as num).toDouble(),
        isIncome: json['isIncome'] as bool,
        categoryName: json['categoryName'] as String,
        categoryIconCode: json['categoryIconCode'] as int,
        categoryFontFamily:
            json['categoryFontFamily'] as String? ?? 'MaterialIcons',
        categoryColor: json['categoryColor'] as int,
        date: json['date'] as String,
      );
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

const List<Category> kDefaultIncomeCategories = [
  Category(name: 'Зарплата', icon: Icons.credit_card, color: Color(0xFF2E7D32)),
  Category(name: 'Проценты', icon: Icons.trending_up, color: Color(0xFF00695C)),
  Category(name: 'Выигрыш', icon: Icons.emoji_events, color: Color(0xFF1565C0)),
  Category(name: 'Возврат долга', icon: Icons.reply, color: Color(0xFF0277BD)),
];

const List<Category> kAllIncomeCategories = [
  Category(name: 'Зарплата', icon: Icons.credit_card, color: Color(0xFF2E7D32)),
  Category(name: 'Проценты', icon: Icons.trending_up, color: Color(0xFF00695C)),
  Category(name: 'Выигрыш', icon: Icons.emoji_events, color: Color(0xFF1565C0)),
  Category(name: 'Возврат долга', icon: Icons.reply, color: Color(0xFF0277BD)),
  Category(name: 'Фриланс', icon: Icons.laptop, color: Color(0xFF1B5E20)),
  Category(name: 'Аренда', icon: Icons.home_work, color: Color(0xFF004D40)),
  Category(name: 'Дивиденды', icon: Icons.show_chart, color: Color(0xFF01579B)),
  Category(name: 'Подарок', icon: Icons.card_giftcard, color: Color(0xFF1A237E)),
  Category(name: 'Продажа', icon: Icons.sell, color: Color(0xFF006064)),
  Category(name: 'Стипендия', icon: Icons.school, color: Color(0xFF33691E)),
  Category(name: 'Пособие', icon: Icons.account_balance, color: Color(0xFF004D40)),
  Category(name: 'Другое', icon: Icons.more_horiz, color: Color(0xFF37474F)),
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
