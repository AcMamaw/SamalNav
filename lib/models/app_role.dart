/// Application roles aligned with the SamalNav use-case diagram.
enum AppRole {
  tourist,
  establishmentOwner,
  administrator,
  superAdmin;

  /// Database value — kept as 'establishment' to match existing Supabase data.
  String get value {
    switch (this) {
      case AppRole.tourist:
        return 'tourist';
      case AppRole.establishmentOwner:
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
      case AppRole.establishmentOwner:
        return 'Establishment Owner';
      case AppRole.administrator:
        return 'Administrator';
      case AppRole.superAdmin:
        return 'Super Admin';
    }
  }

  static AppRole fromString(String? raw) {
    switch (raw?.toLowerCase().trim()) {
      case 'establishment':
      case 'establishment_owner':
      case 'tourism_establishment':
        return AppRole.establishmentOwner;
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
