class AppConstants {
  static const apiBase = 'http://localhost:8001'; // iOS simulator
  // static const apiBase = 'http://10.0.2.2:8001'; // Android emulator

  // SharedPreferences keys
  static const keyUserType       = 'user_type';
  static const keyTrimester      = 'trimester';
  static const keyGestWeek       = 'gestational_week';
  static const keyBabyBirthDate  = 'baby_birth_date';
  static const keyOnboardingDone = 'onboarding_done';
  static const keyUserAge        = 'user_age';
  static const keyUserName       = 'user_name';
  static const keyRural          = 'rural';
  static const keyParity         = 'parity';
  static const keyDueDate        = 'due_date';
  static const keyAnemiaLevel    = 'anemia_level';
  static const keyNotifHour      = 'notif_hour';
  static const keyNotifEnabled   = 'notif_enabled';
  static const keyCheckHistory   = 'check_history'; // JSON list
}

enum UserType { pregnant, postpartum, planning }

enum Trimester { T1, T2, T3 }

extension TrimesterExt on Trimester {
  String get label => switch (this) {
    Trimester.T1 => '1-trimest',
    Trimester.T2 => '2-trimest',
    Trimester.T3 => '3-trimest',
  };

  String get weeks => switch (this) {
    Trimester.T1 => '1–12 hafta',
    Trimester.T2 => '13–26 hafta',
    Trimester.T3 => '27–40 hafta',
  };

  String get code => switch (this) {
    Trimester.T1 => 'T1',
    Trimester.T2 => 'T2',
    Trimester.T3 => 'T3',
  };

  int get enc => switch (this) {
    Trimester.T1 => 0,
    Trimester.T2 => 1,
    Trimester.T3 => 2,
  };

  static Trimester fromWeek(int week) {
    if (week <= 12) return Trimester.T1;
    if (week <= 26) return Trimester.T2;
    return Trimester.T3;
  }
}
