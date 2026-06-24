/// App-wide constants for PUMS.
class AppConstants {
  AppConstants._();

  static const String appName        = 'PUMS';
  static const String appFullName    = 'Prisoner & Undertrial Monitoring System';
  static const String appVersion     = '1.0.0';
  static const String orgName        = 'Karnataka State Police';
  static const String govtName       = 'Government of Karnataka';
  static const String cityPolice     = 'Bangalore City Police';

  // ── DB ──────────────────────────────────────────────────────────────────────
  static const String dbName         = 'pums.db';
  static const int    dbVersion      = 1;

  // ── Tables ──────────────────────────────────────────────────────────────────
  static const String tablePrisoners = 'prisoners';
  static const String tableUsers     = 'users';
  static const String tableAuditLogs = 'audit_logs';
  static const String tableIpcSections = 'ipc_sections';
  static const String tableBnsSections = 'bns_sections';

  // ── Shared Prefs keys ───────────────────────────────────────────────────────
  static const String prefCurrentUser   = 'current_user';
  static const String prefLeftLogoPath  = 'logo_left';
  static const String prefCenterLogoPath= 'logo_center';
  static const String prefRightLogoPath = 'logo_right';
  static const String prefDarkMode      = 'dark_mode';

  // ── Pagination ──────────────────────────────────────────────────────────────
  static const int defaultPageSize = 50;

  // ── Date formats ────────────────────────────────────────────────────────────
  static const String dateDisplayFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat    = 'dd/MM/yyyy HH:mm';
  static const String dateIso           = 'yyyy-MM-dd';
}

/// Spacing constants — 4-pt grid.
class Spacing {
  Spacing._();
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 16;
  static const double lg  = 24;
  static const double xl  = 32;
  static const double xxl = 48;
}

/// Border radius constants.
class Radii {
  Radii._();
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
}

/// Sidebar / layout breakpoints.
class Breakpoints {
  Breakpoints._();
  static const double mobile  = 600;
  static const double tablet  = 900;
  static const double desktop = 1200;
}
