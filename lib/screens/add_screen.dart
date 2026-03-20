import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/expense.dart';
import '../l10n/app_localizations.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

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
  final _dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  String _type = 'expense';

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _memoController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _save(AppLocalizations l10n) async {
    if (_formKey.currentState!.validate()) {
      final expense = Expense(
        date: _dateController.text,
        title: _titleController.text,
        amount: int.parse(_amountController.text),
        category: _categoryController.text.isEmpty ? l10n.translate('other') : _categoryController.text,
        memo: _memoController.text,
        type: _type,
      );
      await _dbHelper.insert(expense);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                    const SizedBox(height: 40),
                    _buildGlassField(_titleController, l10n.translate('where'), Icons.edit, false, l10n: l10n, textColor: textColor, glassColor: glassColor, glassBorder: glassBorder),
                    _buildGlassField(_amountController, l10n.translate('how_much'), Icons.wallet, false, keyboardType: TextInputType.number, l10n: l10n, textColor: textColor, glassColor: glassColor, glassBorder: glassBorder),
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
                    _buildSaveButton(l10n),
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

  Widget _buildGlassField(TextEditingController controller, String label, IconData icon, bool readOnly, {VoidCallback? onTap, TextInputType keyboardType = TextInputType.text, required AppLocalizations l10n, required Color textColor, required Color glassColor, required Color glassBorder}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
        ),
      ),
    );
  }

  Widget _buildSaveButton(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)]),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ElevatedButton(
        onPressed: () => _save(l10n),
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
