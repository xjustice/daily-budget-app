import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:ui';
import '../db/db_helper.dart';
import '../models/expense.dart';
import '../models/character.dart';
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
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month; // Start with month view
  bool _isDateFiltered = false; // Add state to track if filtered by date
  Map<String, Map<String, int>> _dailyTotals = {}; // Store {dateString: {'income': sum, 'expense': sum}}

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _addMockData() async {
    final now = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await _dbHelper.insert(Expense(date: now, title: 'Test Income', amount: 50000, category: 'Work', memo: 'Mock', type: 'income'));
    await _dbHelper.insert(Expense(date: now, title: 'Test Coffee', amount: 5000, category: 'Food', memo: 'Mock', type: 'expense'));
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    final data = await _dbHelper.getAllExpenses();
    final totals = await _dbHelper.getTotals();
    
    // Group totals by date for calendar display
    Map<String, Map<String, int>> daily = {};
    for (var e in data) {
      daily.putIfAbsent(e.date, () => {'income': 0, 'expense': 0});
      daily[e.date]![e.type] = (daily[e.date]![e.type] ?? 0) + e.amount;
    }

    setState(() {
      _dailyTotals = daily;
      // Filter expenses by selected date ONLY if isDateFiltered is true
      if (_isDateFiltered) {
        _expenses = data.where((e) => e.date == DateFormat('yyyy-MM-dd').format(_selectedDay)).toList();
      } else {
        _expenses = data;
      }
      _totals = totals;
      _isLoading = false;
    });
  }

  String _formatAmount(int amount, String localeCode, double rate) {
    bool isEn = localeCode == 'en';
    double converted = isEn ? amount * rate : amount.toDouble();
    final formatter = NumberFormat.currency(
      locale: isEn ? 'en_US' : 'ko_KR',
      symbol: isEn ? '\$' : '₩',
      decimalDigits: isEn ? 2 : 0,
    );
    return formatter.format(isEn ? converted : converted.toInt());
  }

  String _formatCompact(int amount, String localeCode, double rate) {
    bool isEn = localeCode == 'en';
    double converted = isEn ? amount * rate : amount.toDouble();
    if (isEn) {
       return "\$${NumberFormat.compact().format(converted)}";
    } else {
       return NumberFormat.compact(locale: 'ko_KR').format(converted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appProvider = Provider.of<AppProvider>(context);
    final isEn = appProvider.locale.languageCode == 'en';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    
    // More compact dynamic values for "all-in-one" screen look
    final double dynamicRowHeight = (screenHeight * 0.075).clamp(58, 65);
    final double dynamicBottomSpacer = (screenHeight * 0.15).clamp(100, 180);

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
              _buildAppBar(l10n, appProvider, textColor, isDark, glassColor, glassBorder, secondaryTextColor),
              _buildSummaryHeader(l10n, appProvider, glassColor, glassBorder, textColor, secondaryTextColor),
              _buildCharacterSection(l10n, appProvider, glassColor, glassBorder, textColor, secondaryTextColor),
              _buildCalendarSection(l10n, appProvider, isDark, glassColor, glassBorder, textColor, dynamicRowHeight),
              if (_isDateFiltered) 
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${DateFormat('yyyy-MM-dd').format(_selectedDay)} ${l10n.translate('history') ?? 'History'}", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.amber),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => AddScreen(initialDate: _selectedDay)),
                                );
                                if (result == true) _refreshData();
                              },
                            ),
                            ActionChip(
                              label: Text(l10n.translate('view_all') ?? 'View All'),
                              onPressed: () {
                                setState(() => _isDateFiltered = false);
                                _refreshData();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              _isLoading
                  ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                  : _expenses.isEmpty
                      ? _buildEmptyState(l10n, secondaryTextColor)
                      : _buildGlassList(l10n, appProvider, glassColor, glassBorder, textColor, secondaryTextColor),
              SliverToBoxAdapter(child: SizedBox(height: dynamicBottomSpacer)),
            ],
          ),
        ],
      ),
      floatingActionButton: _buildGlassFAB(l10n, isDark),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }

  Widget _buildAppBar(AppLocalizations l10n, AppProvider provider, Color textColor, bool isDark, Color glassColor, Color glassBorder, Color secondaryTextColor) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      centerTitle: false,
      title: GestureDetector(
        onLongPress: _addMockData,
        child: Text(
          l10n.translate('app_title'),
          style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 24),
        ),
      ),
      actions: [
        // Reset Data Button
        IconButton(
          icon: Icon(Icons.refresh, color: textColor),
          onPressed: () async {
            final confirm = await showGeneralDialog<bool>(
              context: context,
              barrierDismissible: true,
              barrierLabel: '',
              pageBuilder: (ctx, anim1, anim2) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: glassColor,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: glassBorder),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.warning_rounded, color: Colors.red, size: 40),
                              ),
                              const SizedBox(height: 20),
                              Text(l10n.translate('reset_data'), style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 20)),
                              const SizedBox(height: 12),
                              Text(
                                l10n.translate('reset_confirm'),
                                textAlign: TextAlign.center,
                                style: TextStyle(color: secondaryTextColor, fontSize: 14),
                              ),
                              const SizedBox(height: 32),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text(l10n.translate('cancel'), style: TextStyle(color: textColor.withOpacity(0.6))),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.withOpacity(0.8),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: Text(l10n.translate('reset'), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            if (confirm == true) {
              await provider.resetData();
              _refreshData();
            }
          },
        ),
        // Theme Toggle Icon
        IconButton(
          onPressed: provider.toggleTheme,
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
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

  Widget _buildCalendarSection(AppLocalizations l10n, AppProvider provider, bool isDark, Color glassColor, Color glassBorder, Color textColor, double dynamicRowHeight) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: glassColor,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: glassBorder),
              ),
              child: Column(
                children: [
                  // Custom Format Picker & Today Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildFormatPicker(l10n, isDark, textColor, glassColor, glassBorder),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDay = DateTime.now();
                              _focusedDay = DateTime.now();
                              _isDateFiltered = true;
                            });
                            _refreshData();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: glassBorder),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.today, size: 14, color: textColor),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.translate('today') ?? 'Today',
                                  style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TableCalendar(
                    locale: provider.locale.languageCode == 'ko' ? 'ko_KR' : 'en_US',
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Month',
                      CalendarFormat.twoWeeks: '2 Weeks',
                      CalendarFormat.week: 'Week',
                    },
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    rowHeight: dynamicRowHeight, // Dynamic responsive height
                    daysOfWeekHeight: 40,
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                        _isDateFiltered = true;
                      });
                      _refreshData();
                    },
                    onDayLongPressed: (selectedDay, focusedDay) async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddScreen(initialDate: selectedDay)),
                      );
                      if (result == true) _refreshData();
                    },
                    onFormatChanged: (format) {
                      setState(() => _calendarFormat = format);
                    },
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false, // Turn off the confusing button
                      titleCentered: true,
                      titleTextStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                      leftChevronIcon: Icon(Icons.chevron_left, color: textColor),
                      rightChevronIcon: Icon(Icons.chevron_right, color: textColor),
                    ),
                    calendarStyle: CalendarStyle(
                      defaultTextStyle: TextStyle(color: textColor),
                      weekendTextStyle: const TextStyle(color: Colors.redAccent),
                      outsideDaysVisible: false,
                      selectedDecoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                      todayDecoration: BoxDecoration(color: Colors.amber.withOpacity(0.3), shape: BoxShape.circle),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(color: textColor.withOpacity(0.6)),
                      weekendStyle: const TextStyle(color: Colors.redAccent),
                    ),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        final dateStr = DateFormat('yyyy-MM-dd').format(date);
                        final dayData = _dailyTotals[dateStr];
                        if (dayData == null) return null;

                        final income = dayData['income'] ?? 0;
                        final expense = dayData['expense'] ?? 0;

                        if (income == 0 && expense == 0) return null;

                        return Positioned(
                          bottom: 0,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (income > 0)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 1),
                                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    _formatCompact(income, provider.locale.languageCode, provider.rate),
                                    style: const TextStyle(color: Colors.blueAccent, fontSize: 7, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              if (expense > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                                  decoration: BoxDecoration(
                                    color: Colors.pinkAccent.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.pinkAccent.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    _formatCompact(expense, provider.locale.languageCode, provider.rate),
                                    style: const TextStyle(color: Colors.pinkAccent, fontSize: 7, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormatPicker(AppLocalizations l10n, bool isDark, Color textColor, Color glassColor, Color glassBorder) {
    bool isKo = l10n.locale.languageCode == 'ko';
    final formats = [
      {'label': isKo ? '주' : 'Week', 'format': CalendarFormat.week},
      {'label': isKo ? '2주' : '2 Weeks', 'format': CalendarFormat.twoWeeks},
      {'label': isKo ? '월' : 'Month', 'format': CalendarFormat.month},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: formats.map((f) {
          bool isSelected = _calendarFormat == f['format'] as CalendarFormat;
          return GestureDetector(
            onTap: () => setState(() => _calendarFormat = f['format'] as CalendarFormat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.amber.withOpacity(0.8) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                f['label'] as String,
                style: TextStyle(
                  color: isSelected ? Colors.black87 : textColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCharacterSection(AppLocalizations l10n, AppProvider provider, Color glassColor, Color glassBorder, Color textColor, Color secondaryTextColor) {
    final char = provider.character;
    final level = char.level;
    final xpPercent = char.xp / char.maxXP;

    // Determine character icon based on level
    IconData charIcon = Icons.egg;
    String charTitle = "Egg (Lv 1)";
    if (level >= 10) {
      charIcon = Icons.workspace_premium;
      charTitle = "Rich King (Lv $level)";
    } else if (level >= 5) {
      charIcon = Icons.person;
      charTitle = "Adult (Lv $level)";
    } else if (level >= 3) {
      charIcon = Icons.pets;
      charTitle = "Pet (Lv $level)";
    } else if (level >= 2) {
      charIcon = Icons.pest_control_rodent;
      charTitle = "Baby (Lv $level)";
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2), // Reduced vertical spacing
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24), // Slightly smaller radius
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Compact inner padding
              decoration: BoxDecoration(
                color: glassColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: glassBorder),
              ),
              child: Row(
                children: [
                   // Character Visuals
                   Container(
                     padding: const EdgeInsets.all(12), // Smaller avatar container
                     decoration: BoxDecoration(
                       color: Colors.amber.withOpacity(0.2),
                       shape: BoxShape.circle,
                     ),
                     child: Icon(charIcon, size: 30, color: Colors.amber), // Smaller icon
                   ),
                   const SizedBox(width: 16),
                   // Progress Stats
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(charTitle, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)), // Smaller font
                         const SizedBox(height: 6),
                         ClipRRect(
                           borderRadius: BorderRadius.circular(10),
                           child: LinearProgressIndicator(
                             value: xpPercent,
                             backgroundColor: Colors.white.withOpacity(0.1),
                             valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                             minHeight: 6, // Slimmer progress bar
                           ),
                         ),
                         const SizedBox(height: 4),
                         Text("${char.xp} / ${char.maxXP} XP", style: TextStyle(color: secondaryTextColor, fontSize: 11)),
                       ],
                     ),
                   ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(AppLocalizations l10n, AppProvider provider, Color glassColor, Color glassBorder, Color textColor, Color secondaryTextColor) {
    final languageCode = provider.locale.languageCode;
    final rate = provider.rate;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 5, 16, 5),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: glassColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: glassBorder),
              ),
              child: Column(
                children: [
                  Text(l10n.translate('balance'), style: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    _formatAmount(_totals['balance']!, languageCode, rate),
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1, color: textColor),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniSummary(l10n.translate('income'), _formatAmount(_totals['income']!, languageCode, rate), Colors.blueAccent, secondaryTextColor),
                      Container(width: 1, height: 35, color: glassBorder),
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
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddScreen(initialDate: _isDateFiltered ? _selectedDay : null)),
        );
        if (result == true) {
          _refreshData();
        }
      },
      elevation: 0,
      backgroundColor: Colors.transparent,
      label: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : const Color(0xFF2C3E50)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: (isDark ? Colors.white : const Color(0xFF2C3E50)).withOpacity(0.2)),
            ),
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
