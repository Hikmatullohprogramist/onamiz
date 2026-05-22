class AppConstants {
  // API
  static const apiBase = 'http://10.0.2.2:8001'; // Android emulator
  // static const apiBase = 'http://localhost:8001'; // iOS simulator
  // static const apiBase = 'https://your-api.com'; // Production

  // SharedPreferences keys
  static const keyUserType       = 'user_type';
  static const keyTrimester      = 'trimester';
  static const keyGestWeek       = 'gestational_week';
  static const keyBabyBirthDate  = 'baby_birth_date';
  static const keyOnboardingDone = 'onboarding_done';
  static const keyUserAge        = 'user_age';
  static const keyRural          = 'rural';
  static const keyParity         = 'parity';
}

enum UserType {
  pregnant,    // Homilador
  postpartum,  // Chaqaloq bor
  planning,    // Rejalashtiraman (keyingi versiya)
}

enum Trimester { T1, T2, T3 }

extension TrimesterExt on Trimester {
  String get label {
    switch (this) {
      case Trimester.T1: return '1-trimest (1–12 hafta)';
      case Trimester.T2: return '2-trimest (13–26 hafta)';
      case Trimester.T3: return '3-trimest (27–40 hafta)';
    }
  }

  String get code {
    switch (this) {
      case Trimester.T1: return 'T1';
      case Trimester.T2: return 'T2';
      case Trimester.T3: return 'T3';
    }
  }

  int get enc {
    switch (this) {
      case Trimester.T1: return 0;
      case Trimester.T2: return 1;
      case Trimester.T3: return 2;
    }
  }
}
