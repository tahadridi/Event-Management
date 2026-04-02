import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import 'register_page.dart';
import '../home/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _rememberMe = true; // Default to true for better UX

  // Color palette - Dark Red & Dark Blue (matching register page)
  static const Color darkRed = Color(0xFF8B0000);
  static const Color darkRedLight = Color(0xFFB22222);
  static const Color darkBlue = Color(0xFF00008B);
  static const Color darkBlueLight = Color(0xFF1A1AA5);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textLight = Color(0xFF4A4A5E);
  static const Color textMuted = Color(0xFF7A7A8E);

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _login() async {
    if (_emailController.text.trim().isEmpty) {
      _showSnackBar('Veuillez entrer votre email');
      return;
    }
    if (!_emailController.text.contains('@')) {
      _showSnackBar('Veuillez entrer un email valide');
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showSnackBar('Veuillez entrer votre mot de passe');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // On mobile, Firebase automatically persists auth state
      // The rememberMe parameter is used to store user preference
      await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        rememberMe: _rememberMe,
      );

      if (mounted) {
        _showSnackBar('Connexion réussie!', isError: false);
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, animation, __) => const HomePage(),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erreur: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Reset Password Dialog
  void _showResetPasswordDialog() {
    final TextEditingController emailController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: darkRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                color: darkRed,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Réinitialiser le mot de passe',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Entrez votre adresse email et nous vous enverrons un lien pour réinitialiser votre mot de passe.',
              style: TextStyle(
                fontSize: 14,
                color: textLight,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Adresse email',
                hintText: 'exemple@email.com',
                prefixIcon: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [darkRed, darkBlue],
                  ).createShader(bounds),
                  child: const Icon(
                    Icons.email_outlined,
                    color: Colors.white,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: textMuted.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: darkRed, width: 2),
                ),
                filled: true,
                fillColor: background,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez entrer votre email'),
                    backgroundColor: darkRed,
                  ),
                );
                return;
              }
              
              // Close dialog
              Navigator.pop(context);
              
              // Show loading indicator
              setState(() => _isLoading = true);
              
              try {
                await _authService.sendPasswordResetEmail(email);
                if (mounted) {
                  _showSnackBar(
                    'Un email de réinitialisation a été envoyé à $email.\nVérifiez votre boîte de réception.',
                    isError: false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  _showSnackBar(e.toString());
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: darkRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Envoyer',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 480;
    final isMediumScreen = screenWidth >= 480 && screenWidth < 768;

    // Responsive variables
    final appBarTitleFontSize = isSmallScreen ? 20.0 : 24.0;
    final headerLogoSize = isSmallScreen ? 60.0 : 70.0;
    final headerLogoIconSize = isSmallScreen ? 28.0 : 34.0;
    final headerTitleFontSize = isSmallScreen ? 28.0 : 34.0;
    final headerSubtitleFontSize = isSmallScreen ? 13.0 : 15.0;
    final horizontalPadding = isSmallScreen ? 20.0 : 24.0;
    final headerTopSpacing = isSmallScreen ? 32.0 : 28.0;
    final textFieldHeight = isSmallScreen ? 50.0 : 56.0;
    final buttonTextFontSize = isSmallScreen ? 15.0 : 17.0;
    final buttonIconSize = isSmallScreen ? 18.0 : 20.0;
    final rememberMeFontSize = isSmallScreen ? 12.0 : 13.0;
    final forgotPasswordFontSize = isSmallScreen ? 12.0 : 13.0;
    final registerLinkFontSize = isSmallScreen ? 13.0 : 15.0;
    final socialButtonHeight = isSmallScreen ? 48.0 : 54.0;
    final socialButtonTextFontSize = isSmallScreen ? 13.0 : 15.0;
    final versionFontSize = isSmallScreen ? 10.0 : 11.0;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(
          "Se connecter",
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
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [darkRed, darkRedLight],
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
                            Icons.event_available_rounded,
                            size: headerLogoIconSize,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: headerTopSpacing),
                        Text(
                          "Bienvenue de retour",
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
                          "Connectez-vous pour accéder à votre espace événementiel",
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
                        // Email Field
                        _buildTextField(
                          controller: _emailController,
                          label: 'Adresse email',
                          hint: 'exemple@email.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          height: textFieldHeight,
                          inputFontSize: isSmallScreen ? 14.0 : 16.0,
                          labelFontSize: isSmallScreen ? 13.0 : 14.0,
                          isSmallScreen: isSmallScreen,
                        ),
                        SizedBox(height: isSmallScreen ? 14 : 18),

                        // Password Field
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
                        SizedBox(height: isSmallScreen ? 12 : 16),

                        // Remember me & Forgot Password
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildRememberMe(rememberMeFontSize, isSmallScreen),
                            _buildForgotPassword(forgotPasswordFontSize, isSmallScreen),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 24 : 32),

                        // Login Button with gradient
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
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
                                            "Se connecter",
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

                        // Register Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Vous n'avez pas de compte ? ",
                              style: TextStyle(
                                color: textLight,
                                fontSize: registerLinkFontSize,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (_, animation, __) => const RegisterPage(),
                                    transitionsBuilder: (_, animation, __, child) {
                                      const begin = Offset(1.0, 0.0);
                                      const end = Offset.zero;
                                      const curve = Curves.easeOutCubic;
                                      var tween = Tween(begin: begin, end: end).chain(
                                        CurveTween(curve: curve),
                                      );
                                      return SlideTransition(
                                        position: animation.drive(tween),
                                        child: child,
                                      );
                                    },
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Text(
                                  "S'inscrire",
                                  style: TextStyle(
                                    fontSize: registerLinkFontSize,
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

                // Social Login Buttons
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
                            _showSnackBar('Fonctionnalité à venir', isError: false);
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
                            _showSnackBar('Fonctionnalité à venir', isError: false);
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
            borderSide: const BorderSide(
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

 Widget _buildRememberMe(double fontSize, bool isSmallScreen) {
    return GestureDetector(
      onTap: () {
        setState(() => _rememberMe = !_rememberMe);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: _rememberMe ? darkRed : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _rememberMe ? darkRed : textMuted.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: _rememberMe
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Text(
            'Se souvenir de moi',
            style: TextStyle(
              fontSize: fontSize,
              color: textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }


  // UPDATED: Now opens the reset password dialog
  Widget _buildForgotPassword(double fontSize, bool isSmallScreen) {
    return TextButton(
      onPressed: _showResetPasswordDialog,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        'Mot de passe oublié ?',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          foreground: Paint()
            ..shader = const LinearGradient(
              colors: [darkRed, darkBlue],
            ).createShader(
              const Rect.fromLTWH(0.0, 0.0, 150.0, 20.0),
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