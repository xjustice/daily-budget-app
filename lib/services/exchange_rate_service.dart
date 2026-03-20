import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExchangeRateService {
  static const String _rateKey = 'usd_krw_rate';
  static const double _defaultRate = 0.00075; // 1 KRW = 0.00075 USD (roughly 1333:1)

  static Future<double> fetchRate() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.wifi)) {
      try {
        final response = await http.get(Uri.parse('https://api.exchangerate-api.com/v4/latest/KRW'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final rate = data['rates']['USD'] as double;
          await _saveRate(rate);
          return rate;
        }
      } catch (e) {
        // Fallback to saved rate or default
      }
    }
    return await _getSavedRate();
  }

  static Future<void> _saveRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_rateKey, rate);
  }

  static Future<double> _getSavedRate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_rateKey) ?? _defaultRate;
  }
}
