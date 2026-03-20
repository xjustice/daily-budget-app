import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'ko': {
      'app_title': '마이 부켓',
      'balance': '현재 잔액',
      'income': '수입',
      'expense': '지출',
      'add_record': '새로운 기록',
      'add_title': '내역 추가',
      'empty_state': '첫 내역을 기록해 보세요 🖋️',
      'where': '어디에 쓰셨나요?',
      'how_much': '얼마인가요?',
      'category': '카테고리',
      'date': '날짜',
      'save': '저장하기',
      'other': '기타',
      'required': '필수 입력 항목입니다',
      'language': '언어',
    },
    'en': {
      'app_title': 'My Budget',
      'balance': 'Current Balance',
      'income': 'Income',
      'expense': 'Expense',
      'add_record': 'New Record',
      'add_title': 'Add Entry',
      'empty_state': 'Record your first entry 🖋️',
      'where': 'What is the title?',
      'how_much': 'How much?',
      'category': 'Category',
      'date': 'Date',
      'save': 'Save',
      'other': 'Other',
      'required': 'This field is required',
      'language': 'Language',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]![key] ?? key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ko', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
