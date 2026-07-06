import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/palette.dart';
import 'history_page.dart';

typedef _P = AppPalette;

final _supabase = Supabase.instance.client;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSigningOut = false;

  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  bool _is2FAEnabled = false;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _usernameCtrl = TextEditingController();

  final TextEditingController _oldPasswordCtrl = TextEditingController();
  final TextEditingController _newPasswordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();

  final TextEditingController _phoneCtrl = TextEditingController();

  StreamSubscription<AuthState>? _authSubscription;

  // ── Real connected-account status, derived from Supabase identities ──
  bool get _isGoogleConnected =>
      _supabase.auth.currentUser?.identities
          ?.any((i) => i.provider == 'google') ??
      false;

  bool get _isFacebookConnected =>
      _supabase.auth.currentUser?.identities
          ?.any((i) => i.provider == 'facebook') ??
      false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    // Listen for auth state changes (e.g. returning from social link OAuth browser flow)
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.signedIn || data.event == AuthChangeEvent.userUpdated) {
        // Refresh user details to update identity list
        await _supabase.auth.getUser();
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _oldPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ── Supabase: Load profile from DB ────────────────────────────────
  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final userResponse = await _supabase.auth.getUser();
      final user = userResponse.user;
      if (user == null) return;

      // Pre-fill email from auth
      _emailCtrl.text = user.email ?? '';

      // Load extra profile data from the profiles table
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          _nameCtrl.text = data['display_name'] ?? user.email?.split('@').first ?? '';
          _usernameCtrl.text = data['username'] ?? '';
          String phone = data['phone'] ?? '';
          if (phone.startsWith('+63')) {
            phone = phone.substring(3);
          }
          _phoneCtrl.text = phone;
          _is2FAEnabled = data['mfa_email_enabled'] ?? false;
        });
      } else {
        // Fallback: use auth metadata
        final meta = user.userMetadata;
        _nameCtrl.text = meta?['display_name'] ?? user.email?.split('@').first ?? '';
      }
    } catch (e) {
      _showSnack('Could not load profile: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Supabase: Save profile edits ───────────────────────────────────
  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() => _isSaving = false);
        return;
      }

      // If password fields are filled, update password
      final oldPw = _oldPasswordCtrl.text.trim();
      final newPw = _newPasswordCtrl.text.trim();
      final confirmPw = _confirmPasswordCtrl.text.trim();

      if (newPw.isNotEmpty) {
        if (newPw != confirmPw) {
          _showSnack('New passwords do not match.', isError: true);
          setState(() => _isSaving = false);
          return;
        }
        if (oldPw.isEmpty) {
          _showSnack('Enter your old password to change it.', isError: true);
          setState(() => _isSaving = false);
          return;
        }

        // Re-authenticate user to verify the old password is correct
        try {
          await _supabase.auth.signInWithPassword(
            email: user.email!,
            password: oldPw,
          );
        } catch (e) {
          _showSnack('Incorrect old password.', isError: true);
          setState(() => _isSaving = false);
          return;
        }

        // Old password verified, now update to new password
        await _supabase.auth.updateUser(UserAttributes(password: newPw));
        _oldPasswordCtrl.clear();
        _newPasswordCtrl.clear();
        _confirmPasswordCtrl.clear();
      }

      // Upsert profile row
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'display_name': _nameCtrl.text.trim(),
        'username': _usernameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isEmpty ? null : '+63${_phoneCtrl.text.trim()}',
        'email': _emailCtrl.text.trim(),
      });

      _showSnack('Profile saved successfully!');
      if (mounted) setState(() => _isEditing = false);
    } catch (e) {
      _showSnack('Failed to save: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Supabase: Sign out ─────────────────────────────────────────────
  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      _showSnack('Failed to log out: $e', isError: true);
      if (mounted) setState(() => _isSigningOut = false);
      return;
    }
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: isError ? Colors.red.shade600 : _P.deepNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _toggleEdit() => setState(() => _isEditing = !_isEditing);

  // ── Link / unlink a social provider ──────────────────────────────────
  Future<void> _toggleSocial(String provider, bool connect) async {
    try {
      if (connect) {
        await _supabase.auth.linkIdentity(
          provider == 'google' ? OAuthProvider.google : OAuthProvider.facebook,
        );
      } else {
        final userResponse = await _supabase.auth.getUser();
        final user = userResponse.user;
        if (user == null) return;
        final identity = user.identities?.firstWhere((i) => i.provider == provider);
        if (identity != null) {
          await _supabase.auth.unlinkIdentity(identity);
          // Reload user to update identities list
          await _supabase.auth.getUser();
        }
      }
      if (mounted) setState(() {});
    } catch (e) {
      _showSnack('Could not update $provider: $e', isError: true);
    }
  }

  // ── Email-based Two-Factor toggle ────────────────────────────────────
  Future<void> _toggle2FA(bool value) async {
    final email = _emailCtrl.text.trim();

    if (value) {
      if (email.isEmpty) {
        _showSnack('Add an email to your profile first.', isError: true);
        return;
      }
      try {
        await _supabase.auth.signInWithOtp(email: email);
        if (!mounted) return;
        final code = await _showOtpDialog();
        if (code == null || code.isEmpty) return; // user cancelled
        await _supabase.auth.verifyOTP(
          type: OtpType.email,
          token: code,
          email: email,
        );
      } catch (e) {
        _showSnack('Could not verify code: $e', isError: true);
        return;
      }
    }

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      await _supabase
          .from('profiles')
          .update({'mfa_email_enabled': value}).eq('id', user.id);
      if (mounted) setState(() => _is2FAEnabled = value);
      _showSnack(value
          ? 'Two-factor authentication enabled.'
          : 'Two-factor authentication disabled.');
    } catch (e) {
      _showSnack('Could not update 2FA setting: $e', isError: true);
    }
  }

  Future<String?> _showOtpDialog() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Enter verification code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'We sent a 6-digit code to your email. Enter it below to enable Two-Factor Authentication.',
              style: TextStyle(fontSize: 13, color: _P.inkSoft),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '6-digit code',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, ctrl.text.trim()),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(50))),
            const SizedBox(height: 12),
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Language',
                      style: TextStyle(color: _P.deepNavy, fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  _languageOption('English', selected: true),
                  const SizedBox(height: 10),
                  _languageOption('Filipino', selected: false),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _languageOption(String label, {required bool selected}) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _P.iceBlue : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: _P.deepNavy, fontSize: 14.5)),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: _P.blue, size: 20),
          ],
        ),
      ),
    );
  }

  void _requestLocation() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Requesting location permission...',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: _P.deepNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  MAIN PROFILE VIEW
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildMainProfile() {
    return Padding(
      key: const ValueKey('main_profile'),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'My Profile',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _P.deepNavy, letterSpacing: -0.5),
          ),
          const SizedBox(height: 24),

          // ── Hero card ────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_P.navy, _P.deepNavy],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(color: _P.deepNavy.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -30, right: -30,
                  child: Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05)),
                  ),
                ),
                Positioned(
                  bottom: -24, left: -16,
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.04)),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 104, height: 104,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _P.iceBlue,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 4),
                            ),
                            child: const Icon(Icons.person_rounded, size: 50, color: _P.skyBlue),
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: _P.skyBlue,
                                shape: BoxShape.circle,
                                border: Border.all(color: _P.navy, width: 2.5),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 14, color: _P.deepNavy),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Loading...',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _emailCtrl.text.isNotEmpty ? _emailCtrl.text : '',
                        style: TextStyle(fontSize: 13.5, color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 24),
                      _HoverButton(
                        text: 'Edit Profile',
                        icon: Icons.edit_rounded,
                        defaultColor: _P.blue,
                        hoverColor: _P.skyBlue,
                        onTap: _toggleEdit,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // ── Route History Section ────────────────────────────────
          _buildSectionHeader('My Activity'),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage())),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_P.navy, _P.deepNavy], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: _P.deepNavy.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 8))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.history_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My Route History', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                        SizedBox(height: 3),
                        Text('View past itineraries & day tours', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Menu section ─────────────────────────────────────────
          _buildSectionHeader('Preferences'),
          const SizedBox(height: 12),
          _menuCard([
            _HoverMenuItem(title: 'Language', icon: Icons.language_rounded, onTap: _showLanguageSelector),
            _HoverMenuItem(title: 'Location', icon: Icons.location_on_outlined, onTap: _requestLocation),
            _HoverMenuItem(title: 'Subscription', icon: Icons.credit_card_rounded),
          ]),
          const SizedBox(height: 24),

          _buildSectionHeader('Data'),
          const SizedBox(height: 12),
          _menuCard([
            _HoverMenuItem(title: 'Clear cache', icon: Icons.delete_outline_rounded),
            _HoverMenuItem(title: 'Clear history', icon: Icons.history_rounded),
          ]),
          const SizedBox(height: 30),

          // ── Log out ──────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: _HoverButton(
              text: 'Log out',
              icon: Icons.logout_rounded,
              defaultColor: Colors.transparent,
              hoverColor: Colors.red.shade600,
              textColor: Colors.red.shade600,
              hoverTextColor: Colors.white,
              borderColor: Colors.red.shade600,
              onTap: _isSigningOut ? () {} : _signOut,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  EDIT PROFILE VIEW
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildEditProfile() {
    return Padding(
      key: const ValueKey('edit_profile'),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _toggleEdit,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: _P.deepNavy.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: _P.deepNavy, size: 20),
                ),
              ),
              const Text('Edit Profile',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _P.deepNavy, letterSpacing: -0.3)),
              GestureDetector(
                onTap: _isSaving ? null : _saveProfile,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isSaving ? Colors.grey : _P.navy,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: _P.deepNavy.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Avatar
          Center(
            child: Stack(
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _P.iceBlue,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [BoxShadow(color: _P.deepNavy.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 8))],
                  ),
                  child: const Icon(Icons.person_rounded, size: 50, color: _P.skyBlue),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(color: _P.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2.5)),
                    child: const Icon(Icons.camera_alt_rounded, size: 15, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Personal Details ─────────────────────────────────────
          _buildSectionHeader('Personal Details'),
          const SizedBox(height: 14),
          _buildEditField('Full Name', _nameCtrl, Icons.person_rounded),
          const SizedBox(height: 14),
          _buildEditField('Email address', _emailCtrl, Icons.email_rounded),
          const SizedBox(height: 14),
          _buildEditField('Username', _usernameCtrl, Icons.alternate_email_rounded),
          const SizedBox(height: 14),
          _buildPhoneField(),
          const SizedBox(height: 28),

          // ── Security ─────────────────────────────────────────────
          _buildSectionHeader('Change Password'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: _P.iceBlue, borderRadius: BorderRadius.circular(14)),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: _P.blue, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Leave password fields empty to keep your current password.',
                    style: TextStyle(color: _P.blue, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildPasswordField('Old Password', _oldPasswordCtrl, _obscureOldPassword,
              (val) => setState(() => _obscureOldPassword = val)),
          const SizedBox(height: 14),
          _buildPasswordField('New Password', _newPasswordCtrl, _obscureNewPassword,
              (val) => setState(() => _obscureNewPassword = val)),
          const SizedBox(height: 14),
          _buildPasswordField('Confirm Password', _confirmPasswordCtrl, _obscureConfirmPassword,
              (val) => setState(() => _obscureConfirmPassword = val)),
          const SizedBox(height: 16),

          _buildToggleCard(
            'Two-Factor Authentication',
            'Require a verification code on login',
            Icons.security_rounded,
            _is2FAEnabled,
            _toggle2FA,
          ),
          const SizedBox(height: 28),

          // ── Connected Accounts ───────────────────────────────────
          _buildSectionHeader('Connected Accounts'),
          const SizedBox(height: 14),
          _buildSocialToggle('Google', Icons.g_mobiledata_rounded, _isGoogleConnected,
              (val) => _toggleSocial('google', val)),
          const SizedBox(height: 12),
          _buildSocialToggle('Facebook', Icons.facebook_rounded, _isFacebookConnected,
              (val) => _toggleSocial('facebook', val)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SHARED PIECES
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSectionHeader(String title) {
    return Text(title,
        style: const TextStyle(color: _P.deepNavy, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.2));
  }

  Widget _menuCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: _P.deepNavy.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _P.inkSoft, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _P.blue.withValues(alpha: 0.18), width: 1.5),
            boxShadow: [BoxShadow(color: _P.deepNavy.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 15, color: _P.deepNavy, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: _P.blue, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(
      String label, TextEditingController controller, bool isObscured, Function(bool) onToggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _P.inkSoft, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _P.blue.withValues(alpha: 0.18), width: 1.5),
            boxShadow: [BoxShadow(color: _P.deepNavy.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: TextField(
            controller: controller,
            obscureText: isObscured,
            style: const TextStyle(fontSize: 15, color: _P.deepNavy, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_rounded, color: _P.blue, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: GestureDetector(
                onTap: () => onToggle(!isObscured),
                child: Icon(
                  isObscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: _P.inkSoft,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Phone number', style: TextStyle(color: _P.inkSoft, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _P.blue.withValues(alpha: 0.18), width: 1.5),
            boxShadow: [BoxShadow(color: _P.deepNavy.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Row(
                  children: [
                    const Icon(Icons.phone_rounded, color: _P.blue, size: 20),
                    const SizedBox(width: 8),
                    const Text('+63', style: TextStyle(color: _P.deepNavy, fontSize: 15, fontWeight: FontWeight.w600)),
                    const Icon(Icons.arrow_drop_down_rounded, color: _P.inkSoft),
                  ],
                ),
              ),
              Container(height: 22, width: 1, color: _P.iceBlue),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 15, color: _P.deepNavy, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleCard(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _P.deepNavy.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _P.iceBlue, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: _P.blue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: _P.deepNavy, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: _P.inkSoft, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: _P.blue,
            inactiveThumbColor: _P.inkSoft,
            inactiveTrackColor: _P.iceBlue,
          ),
        ],
      ),
    );
  }

  // ── Aligned label/status row for Google & Facebook ──────────────────
  Widget _buildSocialToggle(String title, IconData icon, bool isConnected, Function(bool) onToggle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _P.deepNavy.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _P.iceBlue, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: _P.blue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: _P.deepNavy, fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  isConnected ? 'Connected' : 'Not connected',
                  style: TextStyle(
                    color: isConnected ? Colors.green.shade600 : _P.inkSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => onToggle(!isConnected),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isConnected ? Colors.red.shade50 : _P.iceBlue,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                isConnected ? 'Disconnect' : 'Connect',
                style: TextStyle(
                  color: isConnected ? Colors.redAccent : _P.blue,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: _P.blue, strokeWidth: 2.5),
              SizedBox(height: 16),
              Text('Loading profile...', style: TextStyle(color: _P.inkSoft, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    if (_isSigningOut) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: _P.blue, strokeWidth: 2.5),
              SizedBox(height: 16),
              Text('Logging out...', style: TextStyle(color: _P.inkSoft, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isEditing ? _buildEditProfile() : _buildMainProfile(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Hover Components ───────────────────────────────────────────────────

class _HoverButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final Color defaultColor;
  final Color hoverColor;
  final Color textColor;
  final Color hoverTextColor;
  final Color? borderColor;
  final VoidCallback onTap;

  const _HoverButton({
    required this.text,
    this.icon,
    required this.defaultColor,
    required this.hoverColor,
    this.textColor = Colors.white,
    this.hoverTextColor = Colors.white,
    this.borderColor,
    required this.onTap,
  });

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            color: _isHovered ? widget.hoverColor : widget.defaultColor,
            borderRadius: BorderRadius.circular(50),
            border: widget.borderColor != null ? Border.all(color: widget.borderColor!, width: 1.5) : null,
            boxShadow: _isHovered && widget.defaultColor != Colors.transparent
                ? [BoxShadow(color: widget.hoverColor.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: _isHovered ? widget.hoverTextColor : widget.textColor, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                widget.text,
                style: TextStyle(
                  color: _isHovered ? widget.hoverTextColor : widget.textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoverMenuItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const _HoverMenuItem({required this.title, required this.icon, this.onTap});

  @override
  State<_HoverMenuItem> createState() => _HoverMenuItemState();
}

class _HoverMenuItemState extends State<_HoverMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: _isHovered ? _P.iceBlue.withValues(alpha: 0.5) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isHovered ? Colors.white : _P.iceBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: _P.blue, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(widget.title,
                    style: const TextStyle(color: _P.deepNavy, fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              Icon(Icons.chevron_right_rounded, color: _isHovered ? _P.blue : _P.inkSoft.withValues(alpha: 0.5), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}