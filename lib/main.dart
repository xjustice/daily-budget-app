import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'l10n/app_localizations.dart';
import 'services/exchange_rate_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db/db_helper.dart';
import 'models/character.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  await initializeDateFormatting('en_US', null);
  
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final appProvider = AppProvider();
  await appProvider.init();

  runApp(
    ChangeNotifierProvider.value(
      value: appProvider,
      child: const BudgetApp(),
    ),
  );
}

class AppProvider with ChangeNotifier {
  Locale _locale = const Locale('ko');
  ThemeMode _themeMode = ThemeMode.system;
  double _usdKrwRate = 0.00075;
  bool _isRateUpdated = false;
  Character _character = Character(level: 1, xp: 0, maxXP: 100, status: 'happy');

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  double get rate => _usdKrwRate;
  bool get isRateUpdated => _isRateUpdated;
  Character get character => _character;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load saved settings
    final savedLang = prefs.getString('language') ?? 'ko';
    _locale = Locale(savedLang);
    
    final savedTheme = prefs.getString('theme') ?? 'system';
    _themeMode = _parseThemeMode(savedTheme);

    _usdKrwRate = await ExchangeRateService.fetchRate();
    _character = await DBHelper().getCharacter();
    notifyListeners();

    Connectivity().onConnectivityChanged.listen((results) async {
       if (results.contains(ConnectivityResult.wifi)) {
         final newRate = await ExchangeRateService.fetchRate();
         if (newRate != _usdKrwRate) {
           _usdKrwRate = newRate;
           _isRateUpdated = true;
           notifyListeners();
           Future.delayed(const Duration(seconds: 3), () {
             _isRateUpdated = false;
             notifyListeners();
           });
         }
       }
    });
  }

  ThemeMode _parseThemeMode(String theme) {
    if (theme == 'light') return ThemeMode.light;
    if (theme == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  void setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', locale.languageCode);
    notifyListeners();
  }

  void toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', _themeMode == ThemeMode.light ? 'light' : 'dark');
    notifyListeners();
  }

  Future<void> addXP(int amount) async {
    int newXP = _character.xp + amount;
    int newLevel = _character.level;
    int newMaxXP = _character.maxXP;

    while (newXP >= newMaxXP) {
      newXP -= newMaxXP;
      newLevel++;
      newMaxXP = (newMaxXP * 1.2).toInt(); // Level difficulty increase
    }

    _character = _character.copyWith(
      level: newLevel,
      xp: newXP,
      maxXP: newMaxXP,
    );
    
    await DBHelper().updateCharacter(_character);
    notifyListeners();
  }

  void updateCharacterStatus(String status) async {
    _character = _character.copyWith(status: status);
    await DBHelper().updateCharacter(_character);
    notifyListeners();
  }

  Future<void> resetData() async {
    await DBHelper().clearAll();
    _character = Character(level: 1, xp: 0, maxXP: 100, status: 'happy');
    notifyListeners();
  }
}

class BudgetApp extends StatelessWidget {
  const BudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Daily Budget',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF1E293B),
        fontFamily: 'Inter',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF334155),
        fontFamily: 'Inter',
      ),
      themeMode: provider.themeMode,
      locale: provider.locale,
      supportedLocales: const [Locale('ko'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeScreen(),
    );
  }
}
