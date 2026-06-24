/// Prisoner current status.
enum PrisonerStatus {
  undertrial,
  convicted,
  released,
  transferred,
  acquitted,
  bail;

  String get label => switch (this) {
    undertrial  => 'Undertrial',
    convicted   => 'Convicted',
    released    => 'Released',
    transferred => 'Transferred',
    acquitted   => 'Acquitted',
    bail        => 'Bail',
  };
}

/// Reason for release.
enum ReleaseReason {
  bail,
  sentenceCompletion,
  acquittal,
  courtOrder,
  transfer,
  other;

  String get label => switch (this) {
    bail               => 'Bail',
    sentenceCompletion => 'Sentence Completion',
    acquittal          => 'Acquittal',
    courtOrder         => 'Court Order',
    transfer           => 'Transfer',
    other              => 'Other',
  };
}

/// Gender.
enum Gender {
  male,
  female,
  other;

  String get label => switch (this) {
    male   => 'Male',
    female => 'Female',
    other  => 'Other',
  };
}

/// System roles — determines what a user can see / do.
enum UserRole {
  admin,
  commissioner,
  dcpSp,
  acpDySp,
  inspector,
  si,
  prisonOfficer;

  String get label => switch (this) {
    admin         => 'Admin',
    commissioner  => 'Commissioner',
    dcpSp         => 'DCP / SP',
    acpDySp       => 'ACP / DySP',
    inspector     => 'Inspector',
    si            => 'Sub-Inspector (SI)',
    prisonOfficer => 'Prison Officer',
  };

  /// Returns true if the role can manage users.
  bool get canManageUsers => this == admin || this == commissioner;

  /// Returns true if the role can delete prisoners.
  bool get canDelete => this == admin || this == commissioner || this == dcpSp;

  /// Returns true if the role can export reports.
  bool get canExport => true;
}

/// Audit action types.
enum AuditAction {
  login,
  logout,
  addPrisoner,
  editPrisoner,
  deletePrisoner,
  viewPrisoner,
  excelUpload,
  exportReport,
  addUser,
  editUser,
  deleteUser,
  changeSettings,
  backupDatabase,
  restoreDatabase;

  String get label => switch (this) {
    login           => 'Login',
    logout          => 'Logout',
    addPrisoner     => 'Add Prisoner',
    editPrisoner    => 'Edit Prisoner',
    deletePrisoner  => 'Delete Prisoner',
    viewPrisoner    => 'View Prisoner',
    excelUpload     => 'Excel Upload',
    exportReport    => 'Export Report',
    addUser         => 'Add User',
    editUser        => 'Edit User',
    deleteUser      => 'Delete User',
    changeSettings  => 'Change Settings',
    backupDatabase  => 'Backup Database',
    restoreDatabase => 'Restore Database',
  };
}

/// Date filter for Admitted / Released screens.
enum DateFilter {
  today,
  thisWeek,
  thisMonth,
  custom;

  String get label => switch (this) {
    today     => 'Today',
    thisWeek  => 'This Week',
    thisMonth => 'This Month',
    custom    => 'Custom Range',
  };
}

/// Law type for sections.
enum LawType {
  ipc,
  bns;

  String get label => switch (this) {
    ipc => 'IPC',
    bns => 'BNS',
  };
}

/// Report type.
enum ReportType {
  stationWise,
  prisonWise,
  admitted,
  released,
  bail;

  String get label => switch (this) {
    stationWise => 'Station Wise',
    prisonWise  => 'Prison Wise',
    admitted    => 'Admitted',
    released    => 'Released',
    bail        => 'Bail',
  };
}
