import 'package:flutter/material.dart';
import '../../theme/palette.dart';

typedef _P = AppPalette;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;

  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  bool _is2FAEnabled = false;
  bool _isGoogleConnected = true;
  bool _isFacebookConnected = false;

  final TextEditingController _nameCtrl = TextEditingController(text: 'Charlotte King');
  final TextEditingController _emailCtrl = TextEditingController(text: 'charlotte@example.com');
  final TextEditingController _usernameCtrl = TextEditingController(text: '@johnkinggraphics');

  final TextEditingController _oldPasswordCtrl = TextEditingController();
  final TextEditingController _newPasswordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();

  final TextEditingController _phoneCtrl = TextEditingController(text: '6895312');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _oldPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
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
                      Text(_nameCtrl.text,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.2)),
                      const SizedBox(height: 4),
                      Text('@johnkinggraphics',
                          style: TextStyle(fontSize: 13.5, color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w500)),
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
              onTap: () {
                // Log out logic
              },
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
                onTap: _toggleEdit,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _P.navy,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: _P.deepNavy.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
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
          _buildEditField('Name', _nameCtrl, Icons.person_rounded),
          const SizedBox(height: 14),
          _buildEditField('E mail address', _emailCtrl, Icons.email_rounded),
          const SizedBox(height: 14),
          _buildEditField('User name', _usernameCtrl, Icons.alternate_email_rounded),
          const SizedBox(height: 14),
          _buildPhoneField(),
          const SizedBox(height: 28),

          // ── Security ─────────────────────────────────────────────
          _buildSectionHeader('Security'),
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
            (val) => setState(() => _is2FAEnabled = val),
          ),
          const SizedBox(height: 28),

          // ── Connected Accounts ───────────────────────────────────
          _buildSectionHeader('Connected Accounts'),
          const SizedBox(height: 14),
          _buildSocialToggle('Google', Icons.g_mobiledata_rounded, _isGoogleConnected,
              (val) => setState(() => _isGoogleConnected = val)),
          const SizedBox(height: 12),
          _buildSocialToggle('Facebook', Icons.facebook_rounded, _isFacebookConnected,
              (val) => setState(() => _isFacebookConnected = val)),
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
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: _P.deepNavy, fontSize: 15))),
          GestureDetector(
            onTap: () => onToggle(!isConnected),
            child: Text(
              isConnected ? 'Disconnect' : 'Connect',
              style: TextStyle(color: isConnected ? Colors.redAccent : _P.blue, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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