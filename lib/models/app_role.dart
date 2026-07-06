/// Application roles aligned with the SamalNav use-case diagram.
enum AppRole {
  tourist,
  establishment,
  administrator,
  superAdmin;

  String get value {
    switch (this) {
      case AppRole.tourist:
        return 'tourist';
      case AppRole.establishment:
        return 'establishment';
      case AppRole.administrator:
        return 'administrator';
      case AppRole.superAdmin:
        return 'super_admin';
    }
  }

  String get label {
    switch (this) {
      case AppRole.tourist:
        return 'Tourist';
      case AppRole.establishment:
        return 'Tourism Establishment';
      case AppRole.administrator:
        return 'Administrator';
      case AppRole.superAdmin:
        return 'Super Admin';
    }
  }

  static AppRole fromString(String? raw) {
    switch (raw?.toLowerCase().trim()) {
      case 'establishment':
      case 'tourism_establishment':
        return AppRole.establishment;
      case 'administrator':
      case 'admin':
        return AppRole.administrator;
      case 'super_admin':
      case 'superadmin':
        return AppRole.superAdmin;
      case 'tourist':
      default:
        return AppRole.tourist;
    }
  }
}
