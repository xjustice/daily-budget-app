import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../db/db_helper.dart';
import '../models/expense.dart';
import '../main.dart';
import '../l10n/app_localizations.dart';
import 'add_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DBHelper _dbHelper = DBHelper();
  List<Expense> _expenses = [];
  Map<String, int> _totals = {'income': 0, 'expense': 0, 'balance': 0};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    final data = await _dbHelper.getAllExpenses();
    final totals = await _dbHelper.getTotals();
    setState(() {
      _expenses = data;
      _totals = totals;
      _isLoading = false;
    });
  }

  Future<void> _addMockData() async {
    final now = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await _dbHelper.insert(Expense(date: now, title: 'Test Income', amount: 50000, category: 'Work', memo: 'Mock', type: 'income'));
    await _dbHelper.insert(Expense(date: now, title: 'Test Coffee', amount: 5000, category: 'Food', memo: 'Mock', type: 'expense'));
    _refreshData();
  }

  String _formatAmount(int amount, String localeCode, double rate) {
    bool isEn = localeCode == 'en';
    double converted = isEn ? amount * rate : amount.toDouble();
    final formatter = NumberFormat.currency(
      locale: isEn ? 'en_US' : 'ko_KR',
      symbol: isEn ? '\$' : '₩',
      decimalDigits: 0,
    );
    return formatter.format(converted.toInt());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appProvider = Provider.of<AppProvider>(context);
    final isEn = appProvider.locale.languageCode == 'en';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dark Mode Theme Color Palette
    final bgColor1 = isDark ? const Color(0xFF0F172A) : const Color(0xFFE0EAFC);
    final bgColor2 = isDark ? const Color(0xFF1E293B) : const Color(0xFFCFDEF3);
    final bgColor3 = isDark ? const Color(0xFF334155) : const Color(0xFFE8EAF6);
    final textColor = isDark ? Colors.white : const Color(0xFF2C3E50);
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final glassColor = isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.5);
    final glassBorder = isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.5);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [bgColor1, bgColor2, bgColor3],
              ),
            ),
          ),
          
          // Liquid Blobs
          Positioned(
            top: -50, right: -50, 
            child: _buildBlob(300, (isDark ? Colors.indigo : const Color(0xFFBBDEFB)).withOpacity(isDark ? 0.2 : 0.4))
          ),
          Positioned(
            bottom: 100, left: -80, 
            child: _buildBlob(400, (isDark ? Colors.deepPurple : const Color(0xFFF3E5F5)).withOpacity(isDark ? 0.2 : 0.5))
          ),

          if (appProvider.isRateUpdated && isEn)
            Positioned(
              top: 100, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('WiFi Rate Updated!', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(l10n, appProvider, textColor),
              _buildSummaryHeader(l10n, appProvider, glassColor, glassBorder, textColor, secondaryTextColor),
              _isLoading
                  ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                  : _expenses.isEmpty
                      ? _buildEmptyState(l10n, secondaryTextColor)
                      : _buildGlassList(l10n, appProvider, glassColor, glassBorder, textColor, secondaryTextColor),
            ],
          ),
        ],
      ),
      floatingActionButton: _buildGlassFAB(l10n, isDark),
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }

  Widget _buildAppBar(AppLocalizations l10n, AppProvider provider, Color textColor) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      centerTitle: false,
      title: GestureDetector(
        onLongPress: _addMockData,
        child: Text(
          l10n.translate('app_title'),
          style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 24),
        ),
      ),
      actions: [
        // Theme Toggle Icon
        IconButton(
          onPressed: provider.toggleTheme,
          icon: Icon(
            provider.themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: textColor,
          ),
        ),
        // Language Toggle
        TextButton(
          onPressed: () {
            final newLocale = provider.locale.languageCode == 'ko' ? const Locale('en') : const Locale('ko');
            provider.setLocale(newLocale);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Text(
              provider.locale.languageCode.toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSummaryHeader(AppLocalizations l10n, AppProvider provider, Color glassColor, Color glassBorder, Color textColor, Color secondaryTextColor) {
    final languageCode = provider.locale.languageCode;
    final rate = provider.rate;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: glassColor,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: glassBorder),
              ),
              child: Column(
                children: [
                  Text(l10n.translate('balance'), style: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Text(
                    _formatAmount(_totals['balance']!, languageCode, rate),
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1, color: textColor),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniSummary(l10n.translate('income'), _formatAmount(_totals['income']!, languageCode, rate), Colors.blueAccent, secondaryTextColor),
                      Container(width: 1, height: 40, color: glassBorder),
                      _buildMiniSummary(l10n.translate('expense'), _formatAmount(_totals['expense']!, languageCode, rate), Colors.pinkAccent, secondaryTextColor),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniSummary(String label, String amount, Color color, Color secondaryTextColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: secondaryTextColor, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(amount, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }

  Widget _buildGlassList(AppLocalizations l10n, AppProvider provider, Color glassColor, Color glassBorder, Color textColor, Color secondaryTextColor) {
    final languageCode = provider.locale.languageCode;
    final rate = provider.rate;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final expense = _expenses[index];
            final isIncome = expense.type == 'income';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: glassColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: glassBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (isIncome ? Colors.blueAccent : Colors.pinkAccent).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isIncome ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                            color: isIncome ? Colors.blueAccent : Colors.pinkAccent,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(expense.title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: textColor)),
                              Text(expense.category, style: TextStyle(color: secondaryTextColor, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text(
                          '${isIncome ? '+' : '-'}${_formatAmount(expense.amount, languageCode, rate)}',
                          style: TextStyle(
                            color: isIncome ? Colors.blueAccent : Colors.pinkAccent,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          childCount: _expenses.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, Color secondaryTextColor) {
    return SliverFillRemaining(
      child: Center(
        child: Text(l10n.translate('empty_state'), style: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildGlassFAB(AppLocalizations l10n, bool isDark) {
    return FloatingActionButton.extended(
      onPressed: () async {
        final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddScreen()));
        if (result == true) _refreshData();
      },
      backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.2),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: BorderSide(color: Colors.white.withOpacity(0.2))),
      label: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.add, color: isDark ? Colors.white : const Color(0xFF2C3E50)),
                const SizedBox(width: 8),
                Text(l10n.translate('add_record'), style: TextStyle(color: isDark ? Colors.white : const Color(0xFF2C3E50), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
