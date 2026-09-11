/// Route name constants for the SamalNav app.
class AppRoutes {
  static const String landing = '/';
  static const String login = '/login';
  static const String register = '/register';

  // Staff / management portal (establishment owner, administrator, super_admin)
  static const String managementLogin = '/management-login';

  // Tourist app
  static const String home = '/home';
  static const String plan = '/plan';
  static const String map = '/map';
  static const String favorite = '/favorite';
  static const String profile = '/profile';

  // RBAC dashboards
  static const String establishmentOwner = '/establishment';
  static const String administrator = '/administrator';
  static const String superAdmin = '/super-admin';

  static const touristRoutes = [home, plan, map, favorite, profile];
}