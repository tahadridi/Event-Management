import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _authService = AuthService();
  
  bool _isOrganizer = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isTermsAccepted = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Color palette - Dark Red & Dark Blue
  static const Color darkRed = Color(0xFF8B0000);
  static const Color darkRedLight = Color(0xFFB22222);
  static const Color darkRedDark = Color(0xFF660000);
  static const Color darkBlue = Color(0xFF00008B);
  static const Color darkBlueLight = Color(0xFF1A1AA5);
  static const Color darkBlueDark = Color(0xFF000066);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textLight = Color(0xFF4A4A5E);
  static const Color textMuted = Color(0xFF7A7A8E);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isError ? darkRed : darkBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _register() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Please enter your full name');
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      _showSnackBar('Please enter your email');
      return;
    }
    if (!_emailController.text.contains('@')) {
      _showSnackBar('Please enter a valid email');
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showSnackBar('Please enter your password');
      return;
    }
    if (_passwordController.text.length < 6) {
      _showSnackBar('Password must be at least 6 characters');
      return;
    }
    if (!_isTermsAccepted) {
      _showSnackBar('Please accept the terms and conditions');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        isOrganizer: _isOrganizer,
      );
      if (mounted) {
        _showSnackBar('Account created successfully!', isError: false);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 480;
    
    // Responsive variables
    final appBarTitleFontSize = isSmallScreen ? 20.0 : 24.0;
    final headerLogoSize = isSmallScreen ? 60.0 : 70.0;
    final headerLogoIconSize = isSmallScreen ? 28.0 : 34.0;
    final headerTitleFontSize = isSmallScreen ? 28.0 : 34.0;
    final headerSubtitleFontSize = isSmallScreen ? 13.0 : 15.0;
    final horizontalPadding = isSmallScreen ? 20.0 : 24.0;
    final headerTopSpacing = isSmallScreen ? 32.0 : 28.0;
    final textFieldHeight = isSmallScreen ? 50.0 : 56.0;
    final switchTitleFontSize = isSmallScreen ? 15.0 : 16.0;
    final switchSubtitleFontSize = isSmallScreen ? 12.0 : 13.0;
    final termsTextFontSize = isSmallScreen ? 12.0 : 13.0;
    final buttonTextFontSize = isSmallScreen ? 15.0 : 17.0;
    final buttonIconSize = isSmallScreen ? 18.0 : 20.0;
    final loginLinkFontSize = isSmallScreen ? 13.0 : 15.0;
    final socialButtonHeight = isSmallScreen ? 48.0 : 54.0;
    final socialButtonTextFontSize = isSmallScreen ? 13.0 : 15.0;
    final versionFontSize = isSmallScreen ? 10.0 : 11.0;
    
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(
          "Sign Up",
          style: TextStyle(
            fontSize: appBarTitleFontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: darkRed,
          ),
        ),
        elevation: 0,
        backgroundColor: background,
        foregroundColor: darkRed,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        centerTitle: false,
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: headerLogoSize,
                          height: headerLogoSize,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                darkRed,
                                darkRedLight,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: darkRed.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.person_add_alt_1,
                            size: headerLogoIconSize,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: headerTopSpacing),
                        Text(
                          "Commencez votre aventure avec nous",
                          style: TextStyle(
                            fontSize: headerTitleFontSize,
                            fontWeight: FontWeight.w800,
                            color: textDark,
                            letterSpacing: -0.8,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        Text(
                          "Créez votre compte en quelques secondes",
                          style: TextStyle(
                            fontSize: headerSubtitleFontSize,
                            color: textLight,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 32 : 48),
                
                // Form Section
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.05),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
                    )),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full name
                        _buildTextField(
                          controller: _nameController,
                          label: 'Nom complet',
                          hint: 'Taha Dridi',
                          icon: Icons.person_outline,
                          height: textFieldHeight,
                          inputFontSize: isSmallScreen ? 14.0 : 16.0,
                          labelFontSize: isSmallScreen ? 13.0 : 14.0,
                          isSmallScreen: isSmallScreen,
                        ),
                        SizedBox(height: isSmallScreen ? 14 : 18),
                        
                        // Email
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'taha@example.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          height: textFieldHeight,
                          inputFontSize: isSmallScreen ? 14.0 : 16.0,
                          labelFontSize: isSmallScreen ? 13.0 : 14.0,
                          isSmallScreen: isSmallScreen,
                        ),
                        SizedBox(height: isSmallScreen ? 14 : 18),
                        
                        // Password
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Mot de passe',
                          hint: '••••••••',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          height: textFieldHeight,
                          inputFontSize: isSmallScreen ? 14.0 : 16.0,
                          labelFontSize: isSmallScreen ? 13.0 : 14.0,
                          isSmallScreen: isSmallScreen,
                        ),
                        SizedBox(height: isSmallScreen ? 20 : 28),
                        
                        // Organizer Switch - Redesigned with dual colors
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                darkRed.withOpacity(0.05),
                                darkBlue.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: darkRed.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20, vertical: isSmallScreen ? 6 : 8),
                            title: Text(
                              'Mode Organisateur',
                              style: TextStyle(
                                fontSize: switchTitleFontSize,
                                fontWeight: FontWeight.w700,
                                color: textDark,
                              ),
                            ),
                            subtitle: Text(
                              'Créer et gérer vos événements',
                              style: TextStyle(
                                fontSize: switchSubtitleFontSize,
                                color: textLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            value: _isOrganizer,
                            onChanged: (val) => setState(() => _isOrganizer = val),
                            activeColor: darkRed,
                            inactiveThumbColor: textLight.withOpacity(0.5),
                            inactiveTrackColor: Colors.grey[200],
                            activeTrackColor: darkRed.withOpacity(0.2),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 20 : 28),
                        
                        // Terms and Conditions
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                darkRed.withOpacity(0.05),
                                darkBlue.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: darkBlue.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: CheckboxListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20, vertical: isSmallScreen ? 6 : 8),
                            title: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: termsTextFontSize,
                                  color: textLight,
                                  height: 1.4,
                                ),
                                children: [
                                  const TextSpan(text: 'J\'accepte les '),
                                  TextSpan(
                                    text: 'Conditions d\'utilisation',
                                    style: TextStyle(
                                      color: darkRed,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const TextSpan(text: ' et '),
                                  TextSpan(
                                    text: 'Politique de confidentialité',
                                    style: TextStyle(
                                      color: darkBlue,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            value: _isTermsAccepted,
                            onChanged: (val) => setState(() => _isTermsAccepted = val ?? false),
                            activeColor: darkRed,
                            checkColor: Colors.white,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 24 : 32),
                        
                        // Register Button with gradient
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              elevation: 0,
                              shadowColor: darkRed.withOpacity(0.4),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [darkRed, darkBlue],
                                ),
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: isSmallScreen ? 20 : 22,
                                      width: isSmallScreen ? 20 : 22,
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Padding(
                                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 18),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Créer un compte",
                                            style: TextStyle(
                                              fontSize: buttonTextFontSize,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          SizedBox(width: isSmallScreen ? 6 : 8),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            size: buttonIconSize,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 20),
                        
                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Vous avez déjà un compte? ",
                              style: TextStyle(
                                color: textLight,
                                fontSize: loginLinkFontSize,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Text(
                                  "Se connecter",
                                  style: TextStyle(
                                    fontSize: loginLinkFontSize,
                                    fontWeight: FontWeight.w700,
                                    foreground: Paint()
                                      ..shader = const LinearGradient(
                                        colors: [darkRed, darkBlue],
                                      ).createShader(
                                        const Rect.fromLTWH(0.0, 0.0, 100.0, 20.0),
                                      ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? 32 : 40),
                
                // Divider with "OR"
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: textMuted.withOpacity(0.3),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
                        child: Text(
                          'OU',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12.0 : 13.0,
                            color: textLight,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: textMuted.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isSmallScreen ? 20 : 28),
                
                // Social Register Buttons
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSocialButton(
                          icon: Icons.g_mobiledata,
                          label: 'Google',
                          color: const Color(0xFFDB4437),
                          onPressed: () {
                            _showSnackBar('Coming soon', isError: false);
                          },
                          height: socialButtonHeight,
                          fontSize: socialButtonTextFontSize,
                          iconSize: isSmallScreen ? 20.0 : 22.0,
                          isSmallScreen: isSmallScreen,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 10 : 12),
                      Expanded(
                        child: _buildSocialButton(
                          icon: Icons.apple,
                          label: 'Apple',
                          color: const Color(0xFF000000),
                          onPressed: () {
                            _showSnackBar('Coming soon', isError: false);
                          },
                          height: socialButtonHeight,
                          fontSize: socialButtonTextFontSize,
                          iconSize: isSmallScreen ? 20.0 : 22.0,
                          isSmallScreen: isSmallScreen,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? 32 : 48),
                
                // Version
                Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 10 : 12, vertical: isSmallScreen ? 5 : 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          darkRed.withOpacity(0.1),
                          darkBlue.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '© $year Reservi. Tous droits réservés.',
                      style: TextStyle(
                        fontSize: versionFontSize,
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: [darkRed, darkBlue],
                          ).createShader(
                            const Rect.fromLTWH(0.0, 0.0, 100.0, 20.0),
                          ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    required double height,
    required double inputFontSize,
    required double labelFontSize,
    required bool isSmallScreen,
  }) {
    final contentPaddingVertical = isSmallScreen ? 12.0 : 16.0;
    final iconSize = isSmallScreen ? 20.0 : 22.0;
    
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: textMuted.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: inputFontSize,
          color: textDark,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: textLight,
            fontWeight: FontWeight.w500,
            fontSize: labelFontSize,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: textLight.withOpacity(0.5),
            fontWeight: FontWeight.w400,
            fontSize: inputFontSize,
          ),
          prefixIcon: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [darkRed, darkBlue],
            ).createShader(bounds),
            child: Icon(
              icon,
              size: iconSize,
              color: Colors.white,
            ),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: textLight,
                    size: iconSize - 2,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
              color: darkRed,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: contentPaddingVertical,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    required double height,
    required double fontSize,
    required double iconSize,
    required bool isSmallScreen,
  }) {
    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide(color: textMuted.withOpacity(0.3), width: 1.5),
          backgroundColor: surface,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize, color: color),
            SizedBox(width: isSmallScreen ? 8 : 10),
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}