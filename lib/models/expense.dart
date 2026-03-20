class Expense {
  int? id;
  String date;
  String title;
  int amount;
  String category;
  String memo;
  String type; // 'income' or 'expense'

  Expense({
    this.id,
    required this.date,
    required this.title,
    required this.amount,
    required this.category,
    required this.memo,
    required this.type,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'title': title,
        'amount': amount,
        'category': category,
        'memo': memo,
        'type': type,
      };

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
        id: map['id'],
        date: map['date'],
        title: map['title'],
        amount: map['amount'],
        category: map['category'],
        memo: map['memo'],
        type: map['type'],
      );
}
