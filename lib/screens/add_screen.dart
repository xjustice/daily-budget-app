import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/expense.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

class AddScreen extends StatefulWidget {
  final DateTime? initialDate;
  const AddScreen({super.key, this.initialDate});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final _formKey = GlobalKey<FormState>();
  final DBHelper _dbHelper = DBHelper();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _memoController = TextEditingController();
  late final TextEditingController _dateController;

  @override
  void initState() {
    super.initState();
    final date = widget.initialDate ?? DateTime.now();
    _dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(date));
  }

  String _type = 'expense';

  final List<String> _expenseCategoriesEn = ['Food', 'Cafe', 'Transport', 'Shopping', 'Medical', 'Culture', 'Bills', 'Etc'];
  final List<String> _expenseCategoriesKo = ['식비', '카페', '교통', '쇼핑', '의료', '문화', '고정지출', '기타'];
  final List<String> _incomeCategoriesEn = ['Salary', 'Allowance', 'Investment', 'Other'];
  final List<String> _incomeCategoriesKo = ['급여', '용돈', '투자', '기타'];
  
  String? _selectedCategory;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _memoController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _save(AppLocalizations l10n, AppProvider provider) async {
    if (_formKey.currentState!.validate()) {
      final isEn = provider.locale.languageCode == 'en';
      final rate = provider.rate;
      
      // Clean up the commas before parsing
      final cleanAmountText = _amountController.text.replaceAll(',', '');
      double amountDouble = double.tryParse(cleanAmountText) ?? 0;
      int amount = amountDouble.round();
      
      // If English (USD), convert back to KRW for storage
      if (isEn && rate > 0) {
        amount = (amountDouble / rate).round();
      }

      final expense = Expense(
        date: _dateController.text,
        title: _titleController.text,
        amount: amount,
        category: _categoryController.text.isEmpty ? l10n.translate('other') : _categoryController.text,
        memo: _memoController.text,
        type: _type,
      );
      await _dbHelper.insert(expense);
      provider.addXP(20); // Reward XP for adding a record
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appProvider = Provider.of<AppProvider>(context);
    final isEn = appProvider.locale.languageCode == 'en';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bgColor1 = isDark ? const Color(0xFF0F172A) : const Color(0xFFE0EAFC);
    final bgColor2 = isDark ? const Color(0xFF1E293B) : const Color(0xFFCFDEF3);
    final textColor = isDark ? Colors.white : const Color(0xFF2C3E50);
    final glassColor = isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.5);
    final glassBorder = isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.5);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          // Theme Toggle Icon
          IconButton(
            onPressed: appProvider.toggleTheme,
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: textColor,
            ),
          ),
          // Language Toggle
          TextButton(
            onPressed: () {
              final newLocale = appProvider.locale.languageCode == 'ko' ? const Locale('en') : const Locale('ko');
              appProvider.setLocale(newLocale);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Text(
                appProvider.locale.languageCode.toUpperCase(),
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [bgColor1, bgColor2]),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(l10n.translate('add_title'), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textColor)),
                    const SizedBox(height: 32),
                    _buildGlassToggle(l10n, isDark),
                    const SizedBox(height: 10),
                    _buildCategoryChips(l10n, textColor, glassColor, glassBorder),
                    const SizedBox(height: 10),
                    _buildGlassField(_titleController, l10n.translate('where'), Icons.edit, false, l10n: l10n, textColor: textColor, glassColor: glassColor, glassBorder: glassBorder),
                    _buildGlassField(_amountController, 
                      '${l10n.translate('how_much')} (${isEn ? '\$' : '₩'})', 
                      Icons.wallet, false, 
                      keyboardType: const TextInputType.numberWithOptions(decimal: true), 
                      formatters: [ThousandsSeparatorInputFormatter(allowDecimal: isEn)],
                      l10n: l10n, textColor: textColor, glassColor: glassColor, glassBorder: glassBorder),
                    _buildGlassField(_categoryController, l10n.translate('category'), Icons.tag, false, l10n: l10n, textColor: textColor, glassColor: glassColor, glassBorder: glassBorder),
                    _buildGlassField(_dateController, l10n.translate('date'), Icons.calendar_month, true, l10n: l10n, textColor: textColor, glassColor: glassColor, glassBorder: glassBorder, onTap: () async {
                      final picked = await showDatePicker(
                        context: context, 
                        initialDate: DateTime.now(), 
                        firstDate: DateTime(2000), 
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.fromSeed(seedColor: textColor, brightness: isDark ? Brightness.dark : Brightness.light),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) setState(() => _dateController.text = DateFormat('yyyy-MM-dd').format(picked));
                    }),
                    const SizedBox(height: 48),
                    _buildSaveButton(l10n, appProvider),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassToggle(AppLocalizations l10n, bool isDark) {
    bool isIncome = _type == 'income';
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          _toggleBtn(l10n.translate('expense'), !isIncome, Colors.pinkAccent, 'expense', isDark),
          _toggleBtn(l10n.translate('income'), isIncome, Colors.blueAccent, 'income', isDark),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool active, Color color, String value, bool isDark) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? (isDark ? Colors.white.withOpacity(0.15) : Colors.white) : Colors.transparent, 
            borderRadius: BorderRadius.circular(16), 
          ),
          child: Center(child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: active ? color : (isDark ? Colors.white38 : Colors.black45)))),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(AppLocalizations l10n, Color textColor, Color glassColor, Color glassBorder) {
    bool isKo = l10n.locale.languageCode == 'ko';
    List<String> categories = _type == 'expense' 
        ? (isKo ? _expenseCategoriesKo : _expenseCategoriesEn)
        : (isKo ? _incomeCategoriesKo : _incomeCategoriesEn);

    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          bool isSelected = _categoryController.text == category;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _categoryController.text = category;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.amber.withOpacity(0.8) : glassColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? Colors.amber : glassBorder),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.black87 : textColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlassField(TextEditingController controller, String label, IconData icon, bool readOnly, {VoidCallback? onTap, TextInputType keyboardType = TextInputType.text, List<TextInputFormatter>? formatters, required AppLocalizations l10n, required Color textColor, required Color glassColor, required Color glassBorder}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        decoration: BoxDecoration(
          color: glassColor, 
          borderRadius: BorderRadius.circular(20), 
          border: Border.all(color: glassBorder)
        ),
        child: TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
            prefixIcon: Icon(icon, color: textColor.withOpacity(0.7)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(20),
          ),
          validator: (v) => v!.isEmpty && !readOnly ? l10n.translate('required') : null,
        ),
      ),
    );
  }

  Widget _buildSaveButton(AppLocalizations l10n, AppProvider provider) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)]),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ElevatedButton(
        onPressed: () => _save(l10n, provider),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, 
          shadowColor: Colors.transparent, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
        ),
        child: Text(l10n.translate('save'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final bool allowDecimal;
  ThousandsSeparatorInputFormatter({this.allowDecimal = false});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;

    // Remove old commas
    String newText = newValue.text.replaceAll(',', '');
    
    // Only allow digits (and one dot if allowDecimal is true)
    if (allowDecimal) {
      if (newText == '.') return newValue.copyWith(text: '0.', selection: const TextSelection.collapsed(offset: 2));
      if (newText.split('.').length > 2) return oldValue;
      if (!RegExp(r'^\d*\.?\d*$').hasMatch(newText)) return oldValue;
    } else {
      if (!RegExp(r'^\d*$').hasMatch(newText)) return oldValue;
    }

    try {
      if (newText.endsWith('.')) return newValue;
      
      final parts = newText.split('.');
      final formatter = NumberFormat('#,###');
      String formattedText = formatter.format(double.parse(parts[0]));
      
      if (parts.length > 1) {
        formattedText += '.${parts[1]}';
      }

      return TextEditingValue(
        text: formattedText,
        selection: TextSelection.collapsed(offset: formattedText.length),
      );
    } catch (e) {
      return oldValue;
    }
  }
}
