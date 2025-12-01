import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'firebase_options.dart';
import 'dart:async';
// import 'dart:convert'; // No longer needed
import 'dart:math';
import 'auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui' as ui;
// import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // No longer needed

// --- ADDED: New packages for Wi-Fi Provisioning ---
import 'package:webview_flutter/webview_flutter.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';


// --- Centralized sendCommand function ---
void _sendCommand(String command) {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    FirebaseFirestore.instance
        .collection('devices')
        .doc(user.uid)
        .update({'last_command': command, 'timestamp': FieldValue.serverTimestamp()});
  }
}

// --- The 3D Animated Button Widget ---
class AnimatedBorderButton extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isActive;
  final VoidCallback onPressed;

  const AnimatedBorderButton({
    Key? key,
    required this.title,
    required this.icon,
    required this.isActive,
    required this.onPressed,
  }) : super(key: key);

  @override
  _AnimatedBorderButtonState createState() => _AnimatedBorderButtonState();
}

class _AnimatedBorderButtonState extends State<AnimatedBorderButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (widget.isActive) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedBorderButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = Color(0xFF1E1E1E);
    final Color lightShadow = Color(0xFF2A2A2A);
    final Color darkShadow = Colors.black;

    return GestureDetector(
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 70,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(15),
          gradient: widget.isActive
            ? LinearGradient( // "Pressed" Inset Gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  darkShadow,
                  backgroundColor,
                ],
                stops: [0.0, 0.9],
              )
            : null,
          boxShadow: widget.isActive
              ? [] // No outer shadow when pressed
              : [ // "Raised" Outer Shadows
                  BoxShadow(
                    color: lightShadow,
                    offset: Offset(-5, -5),
                    blurRadius: 10,
                  ),
                  BoxShadow(
                    color: darkShadow,
                    offset: Offset(5, 5),
                    blurRadius: 10,
                  ),
                ],
        ),
        child: CustomPaint(
          painter: _BorderPainter(
            animation: _animationController,
            isActive: widget.isActive,
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: Colors.orange, size: 22),
                SizedBox(width: 10),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BorderPainter extends CustomPainter {
  final Animation<double> animation;
  final bool isActive;

  _BorderPainter({required this.animation, required this.isActive})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(15),
      ),
      borderPaint,
    );
    
    if (!isActive) return;

    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = SweepGradient(
      center: Alignment.center,
      colors: const [
        Colors.red,
        Colors.yellow,
        Colors.green,
        Colors.blue,
        Colors.purple,
        Colors.red,
      ],
      stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
      transform: GradientRotation(animation.value * 2 * pi),
    );

    final animPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(15),
        ),
      );

    canvas.drawPath(path, animPaint);
  }

  @override
  bool shouldRepaint(covariant _BorderPainter oldDelegate) =>
      isActive != oldDelegate.isActive ||
      animation.value != oldDelegate.animation.value;
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase connected successfully!');
  } catch (e) {
    print('❌ Firebase error: $e');
  }
  runApp(DivaApp());
}

class DivaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diva App',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _divaController;
  late AnimationController _sparkleController;
  late AnimationController _loadingController;

  late Animation<double> _divaScaleAnimation;
  late Animation<double> _sparkleOpacityAnimation;
  late Animation<double> _loadingAnimation;

  bool _showSparkles = false;
  bool _showLoading = false;
  final Random _random = Random();
  List<SparkleParticle> _sparkles = [];

  @override
  void initState() {
    super.initState();

    _divaController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _divaScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _divaController, curve: Curves.elasticOut),
    );

    _sparkleController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );
    _sparkleOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeIn),
    );

    _loadingController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );

    _startAnimationAndCheckAuth();
    _generateSparkles();
  }

  void _generateSparkles() {
    _sparkles = List.generate(15, (index) => SparkleParticle(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      size: _random.nextDouble() * 8 + 6,
      rotation: _random.nextDouble() * 2 * pi,
    ));
  }

  void _startAnimationAndCheckAuth() async {
    _divaController.forward();
    setState(() => _showSparkles = true);
    _sparkleController.forward();
    setState(() => _showLoading = true);
    await _loadingController.forward();
    
    await Future.delayed(Duration(milliseconds: 500));
    
    User? user = FirebaseAuth.instance.currentUser;

    if (mounted) {
      if (user == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginSignUpPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    }
  }

  @override
  void dispose() {
    _divaController.dispose();
    _sparkleController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [Colors.orange.withOpacity(0.2), Colors.black],
                stops: [0.3, 1.0],
              ),
            ),
          ),
          if (_showSparkles)
            AnimatedBuilder(
              animation: _sparkleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: SparklesPainter(_sparkles, _sparkleOpacityAnimation.value),
                  size: Size.infinite,
                );
              },
            ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _divaScaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _divaScaleAnimation.value,
                      child: Container(
                        width: 120,
                        height: 160,
                        child: CustomPaint(
                          painter: DivaLampPainter(),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 60),
                if (_showLoading)
                  AnimatedBuilder(
                    animation: _loadingAnimation,
                    builder: (context, child) {
                      return Column(
                        children: [
                          Text(
                            'Loading...',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          SizedBox(height: 20),
                          Container(
                            width: 200,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: _loadingAnimation.value,
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.orange,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LoginSignUpPage extends StatefulWidget {
  @override
  _LoginSignUpPageState createState() => _LoginSignUpPageState();
}

class _LoginSignUpPageState extends State<LoginSignUpPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();
  final TextEditingController _signUpEmailController = TextEditingController();
  final TextEditingController _signUpPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    setState(() => _isLoading = true);
    User? user = await _authService.signInWithEmail(_loginEmailController.text.trim(), _loginPasswordController.text.trim());
    if (user != null && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _handleSignUp() async {
    setState(() => _isLoading = true);
    User? user = await _authService.signUpWithEmail(_signUpEmailController.text.trim(), _signUpPasswordController.text.trim());
     if (user != null && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showForgotPasswordDialog() {
    final TextEditingController resetEmailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text("Reset Password", style: TextStyle(color: Colors.orange)),
          content: TextFormField(
            controller: resetEmailController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Enter your registered email',
              labelStyle: TextStyle(color: Colors.orange.withOpacity(0.7)),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange, width: 2)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {
                if (resetEmailController.text.isNotEmpty) {
                  _authService.sendPasswordResetEmail(resetEmailController.text.trim());
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Password reset link sent to your email!')),
                  );
                }
              },
              child: Text("Send Link", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.withOpacity(0.1), Colors.black],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  SizedBox(height: 40),
                  Text('Diva', style: TextStyle(color: Colors.orange, fontSize: 48, fontWeight: FontWeight.bold)),
                  SizedBox(height: 40),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.orange,
                    indicatorWeight: 3.0,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: Colors.orange,
                    unselectedLabelColor: Colors.white70,
                    tabs: [
                      Tab(text: 'Login'),
                      Tab(text: 'Sign Up'),
                    ],
  
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAuthForm(
                          isLogin: true,
                          emailController: _loginEmailController,
                          passwordController: _loginPasswordController,
                          onSubmit: _handleLogin,
                        ),
                        _buildAuthForm(
                          isLogin: false,
                          emailController: _signUpEmailController,
                          passwordController: _signUpPasswordController,
                          onSubmit: _handleSignUp,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthForm({
    required bool isLogin,
    required TextEditingController emailController,
    required TextEditingController passwordController,
    required VoidCallback onSubmit,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 40.0),
      child: Column(
        children: [
          TextFormField(
            controller: emailController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: TextStyle(color: Colors.orange),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange), borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange, width: 2), borderRadius: BorderRadius.circular(10)),
              prefixIcon: Icon(Icons.email, color: Colors.orange),
            ),
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: passwordController,
            obscureText: true,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: TextStyle(color: Colors.orange),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange), borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange, width: 2), borderRadius: BorderRadius.circular(10)),
              prefixIcon: Icon(Icons.lock, color: Colors.orange),
            ),
          ),
          if (isLogin)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: _showForgotPasswordDialog,
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(color: Colors.orange[200], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: isLogin ? 20 : 40),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : onSubmit,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(isLogin ? 'Login' : 'Sign Up', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Stream<DocumentSnapshot>? _deviceStream;
  // --- REMOVED: AuthService instance ---

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _deviceStream = FirebaseFirestore.instance
          .collection('devices')
          .doc(user.uid)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.withOpacity(0.1), Colors.black],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.settings, color: Colors.orange, size: 28),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SettingsPage()),
                        );
                      },
                    ),
                    Text(
                      'Diva Home',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // --- MODIFIED: Removed logout button, added SizedBox for spacing ---
                    SizedBox(width: 48), 
                  ],
                ),
              ),
              Spacer(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: _deviceStream,
                  builder: (context, snapshot) {
                    String activeCommand = '';
                    if (snapshot.hasData && snapshot.data!.exists) {
                      try {
                        activeCommand = (snapshot.data!.data() as Map<String, dynamic>)['active_state'] ?? '';
                      } catch (e) {
                        activeCommand = '';
                      }
                    }

                    return Column(
                      children: [
                        AnimatedBorderButton(
                          title: 'Home Automation',
                          icon: Icons.home_outlined,
                          isActive: activeCommand.startsWith('Automation_'),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => HomeAutomationPage())),
                        ),
                        SizedBox(height: 20),
                        AnimatedBorderButton(
                          title: 'Festival',
                          icon: Icons.celebration_outlined,
                          isActive: activeCommand.startsWith('Festival_'),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FestivalPage())),
                        ),
                        SizedBox(height: 20),
                        AnimatedBorderButton(
                          title: 'Spiritual Wellness',
                          icon: Icons.spa_outlined,
                          isActive: activeCommand.startsWith('Spiritual_'),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SpiritualWellnessPage())),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

// --- MODIFIED: This page is now the Wi-Fi setup assistant ---
class AddDevicePage extends StatefulWidget {
  @override
  _AddDevicePageState createState() => _AddDevicePageState();
}

class _AddDevicePageState extends State<AddDevicePage> {
  final NetworkInfo _networkInfo = NetworkInfo();
  String _currentWifiSSID = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkWifiConnection();
  }

  Future<void> _checkWifiConnection() async {
    setState(() => _isLoading = true);
    String? wifiName;
    try {
      wifiName = await _networkInfo.getWifiName();
    } catch (e) {
      print("Failed to get Wi-Fi name: $e");
      wifiName = "Error";
    }
    setState(() {
      _currentWifiSSID = wifiName?.replaceAll('"', '') ?? "Not Connected";
      _isLoading = false;
    });
  }

  Future<void> _openWifiSettings() async {
    // This is a more direct intent for Android Wi-Fi settings.
    final Uri wifiSettingsUri = Uri.parse('android.settings.WIFI_SETTINGS');
    try {
      if (await canLaunchUrl(wifiSettingsUri)) {
        await launchUrl(wifiSettingsUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback for iOS and other devices
        final Uri appSettingsUri = Uri.parse('App-Settings:');
        if (await canLaunchUrl(appSettingsUri)) {
          await launchUrl(appSettingsUri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Could not open settings');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not open Wi-Fi settings. Please open them manually."), backgroundColor: Colors.red),
      );
    }
  }

  void _continueToWebView() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: You must be logged in."), backgroundColor: Colors.red),
      );
      return;
    }
    
    // --- THIS IS THE CORRECTED LINE ---
    // We now pass the user's ID in the URL
    String configUrl = "http://192.168.4.1?uid=${user.uid}";

    print("Opening WebView with URL: $configUrl"); // Added for debugging

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeviceConfigWebView(url: configUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isConnectedToDevice = _currentWifiSSID == "Diva-Setup";

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Add New Device', style: TextStyle(color: Colors.orange)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.orange),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.withOpacity(0.1), Colors.black],
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Step 1: Connect to the Device",
              style: TextStyle(color: Colors.orange, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              "Go to your phone's Wi-Fi settings and connect to the network named \"Diva-Setup\".",
              style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 24),
            AnimatedBorderButton(
              title: "Open Wi-Fi Settings",
              icon: Icons.wifi,
              isActive: false,
              onPressed: _openWifiSettings,
            ),
            SizedBox(height: 32),
            Text(
              "Step 2: Configure Device",
              style: TextStyle(color: Colors.orange, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              "After connecting to the 'Diva-Setup' network, return here and tap 'Configure'.",
              style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 24),
            AnimatedBorderButton(
              title: "Configure Device",
              icon: Icons.settings_ethernet,
              isActive: isConnectedToDevice, // Button "activates" when connected
              onPressed: isConnectedToDevice
                  ? _continueToWebView
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("You are not connected to the 'Diva-Setup' network. Please check and try again."), backgroundColor: Colors.red),
                      );
                      _checkWifiConnection();
                    },
            ),
            Spacer(),
            if (_isLoading)
              Center(child: CircularProgressIndicator(color: Colors.orange))
            else
              GestureDetector(
                onTap: _checkWifiConnection,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Current Wi-Fi: ",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      _currentWifiSSID,
                      style: TextStyle(
                        color: isConnectedToDevice ? Colors.green : Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.refresh, color: Colors.white70, size: 18)
                  ],
                ),
              ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// --- ADDED: New page to host the web view ---
class DeviceConfigWebView extends StatefulWidget {
  final String url;
  const DeviceConfigWebView({Key? key, required this.url}) : super(key: key);

  @override
  _DeviceConfigWebViewState createState() => _DeviceConfigWebViewState();
}

class _DeviceConfigWebViewState extends State<DeviceConfigWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            print("Web view error: ${error.description}");
            // Show an error to the user
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to load config page. Make sure you're connected to 'Diva-Setup'."), backgroundColor: Colors.red),
            );
          },
          onNavigationRequest: (NavigationRequest request) {
            // This listens for the ESP32 to restart
            if (!request.url.startsWith('http://192.168.4.1')) {
              // The ESP32 has sent a "Success" message and the phone is trying to browse the web
              // We can interpret this as a success.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Pairing Successful! Device is restarting."), backgroundColor: Colors.green),
              );
              // Pop twice: once for the webview, once for the AddDevicePage
              Navigator.of(context).pop(); 
              Navigator.of(context).pop(); 
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Configure Device", style: TextStyle(color: Colors.orange)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.orange),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(color: Colors.orange),
            ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // --- ADDED: AuthService instance to handle sign-out ---
    final AuthService _authService = AuthService();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(color: Colors.orange)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.orange),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.withOpacity(0.1), Colors.black],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- ADDED: "Add New Device" Button ---
              AnimatedBorderButton(
                title: 'Add New Device',
                icon: Icons.wifi_tethering, // Changed icon
                isActive: false, 
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddDevicePage()),
                  );
                },
              ),
              SizedBox(height: 16), // Spacing between buttons
              // --- ADDED: "Sign Out" Button (Moved from HomePage) ---
              AnimatedBorderButton(
                title: 'Sign Out',
                icon: Icons.logout,
                isActive: false, 
                onPressed: () {
                  _authService.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginSignUpPage()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeAutomationPage extends StatefulWidget {
  @override
  _HomeAutomationPageState createState() => _HomeAutomationPageState();
}

class _HomeAutomationPageState extends State<HomeAutomationPage> {
  Stream<DocumentSnapshot>? _deviceStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _deviceStream = FirebaseFirestore.instance
          .collection('devices')
          .doc(user.uid)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Home Automation', style: TextStyle(color: Colors.orange)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.orange),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.withOpacity(0.1), Colors.black],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: _deviceStream,
            builder: (context, snapshot) {
              String activeCommand = '';
              if (snapshot.hasData && snapshot.data!.exists) {
                try {
                  activeCommand = (snapshot.data!.data() as Map<String, dynamic>)['active_state'] ?? '';
                } catch (e) {
                  activeCommand = '';
                }
              }

              return Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Text(
                        'Automation Controls',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    AnimatedBorderButton(
                      title: 'Integrated Calender',
                      icon: Icons.calendar_month_outlined,
                      isActive: false, 
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CalendarPage())),
                    ),
                    SizedBox(height: 16),
                    AnimatedBorderButton(
                      title: 'Motion Detection',
                      icon: Icons.motion_photos_on_outlined,
                      isActive: activeCommand == 'Automation_Motion_Detection',
                      onPressed: () => _sendCommand('Automation_Motion_Detection'),
                    ),
                    SizedBox(height: 16),
                    AnimatedBorderButton(
                      title: 'Voice Greeting',
                      icon: Icons.record_voice_over_outlined,
                      isActive: activeCommand == 'Automation_Voice_Greeting',
                      onPressed: () => _sendCommand('Automation_Voice_Greeting'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class FestivalPage extends StatefulWidget {
  @override
  _FestivalPageState createState() => _FestivalPageState();
}

class _FestivalPageState extends State<FestivalPage> {
  Stream<DocumentSnapshot>? _deviceStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _deviceStream = FirebaseFirestore.instance
          .collection('devices')
          .doc(user.uid)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Festival', style: TextStyle(color: Colors.orange)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.orange),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.withOpacity(0.1), Colors.black],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: _deviceStream,
            builder: (context, snapshot) {
              String activeCommand = '';
              if (snapshot.hasData && snapshot.data!.exists) {
                try {
                  activeCommand = (snapshot.data!.data() as Map<String, dynamic>)['active_state'] ?? '';
                } catch (e) {
                  activeCommand = '';
                }
              }

              return Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Text(
                        'Festival Modes',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    AnimatedBorderButton(
                      title: 'Normal',
                      icon: Icons.light_mode_outlined,
                      isActive: activeCommand == 'Festival_Normal',
                      onPressed: () => _sendCommand('Festival_Normal'),
                    ),
                    SizedBox(height: 16),
                    AnimatedBorderButton(
                      title: 'Aarti',
                      icon: Icons.local_fire_department_outlined,
                      isActive: activeCommand == 'Festival_Aarti',
                      onPressed: () => _sendCommand('Festival_Aarti'),
                    ),
                    SizedBox(height: 16),
                    AnimatedBorderButton(
                      title: 'Bhajan',
                      icon: Icons.library_music_outlined,
                      isActive: activeCommand == 'Festival_Bhajan',
                      onPressed: () => _sendCommand('Festival_Bhajan'),
                    ),
                    SizedBox(height: 16),
                    AnimatedBorderButton(
                      title: 'Smart Light',
                      icon: Icons.wb_incandescent_outlined,
                      isActive: activeCommand == 'Festival_Smart_Light',
                      onPressed: () => _sendCommand('Festival_Smart_Light'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class SpiritualWellnessPage extends StatefulWidget {
  @override
  _SpiritualWellnessPageState createState() => _SpiritualWellnessPageState();
}

class _SpiritualWellnessPageState extends State<SpiritualWellnessPage> {
  Stream<DocumentSnapshot>? _deviceStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _deviceStream = FirebaseFirestore.instance
          .collection('devices')
          .doc(user.uid)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Spiritual Wellness', style: TextStyle(color: Colors.orange)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.orange),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.withOpacity(0.1), Colors.black],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: _deviceStream,
            builder: (context, snapshot) {
               String activeCommand = '';
              if (snapshot.hasData && snapshot.data!.exists) {
                try {
                  activeCommand = (snapshot.data!.data() as Map<String, dynamic>)['active_state'] ?? '';
                } catch (e) {
                  activeCommand = '';
                }
              }

              return Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Text(
                        'Spiritual Wellness',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    AnimatedBorderButton(
                      title: 'Meditation',
                      icon: Icons.self_improvement,
                      isActive: activeCommand == 'Spiritual_Meditation',
                      onPressed: () => _sendCommand('Spiritual_Meditation'),
                    ),
                    SizedBox(height: 16),
                    AnimatedBorderButton(
                      title: 'Claming',
                      icon: Icons.nightlight_outlined,
                      isActive: activeCommand == 'Spiritual_Claming',
                      onPressed: () => _sendCommand('Spiritual_Claming'),
                    ),
                    SizedBox(height: 16),
                    AnimatedBorderButton(
                      title: 'Healing',
                      icon: Icons.healing_outlined,
                      isActive: activeCommand == 'Spiritual_Healing',
                      onPressed: () => _sendCommand('Spiritual_Healing'),
                    ),
                    SizedBox(height: 16),
                    AnimatedBorderButton(
                      title: 'Chanting',
                      icon: Icons.library_music_outlined,
                      isActive: activeCommand == 'Spiritual_Chanting',
                      onPressed: () => _sendCommand('Spiritual_Chanting'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDay = DateTime.now();
  final TextEditingController _noteController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();

  Stream<QuerySnapshot> _getNotes() {
    return FirebaseFirestore.instance
        .collection("notes")
        .where("date", isEqualTo: DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day).toIso8601String())
        .snapshots();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              hourMinuteTextColor: Colors.white,
              hourMinuteColor: Colors.orange.withOpacity(0.2),
              dialHandColor: Colors.orange,
              dialBackgroundColor: Colors.black,
              entryModeIconColor: Colors.orange,
              dayPeriodTextColor: Colors.orange,
              dayPeriodColor: Colors.orange.withOpacity(0.2),
              helpTextStyle: TextStyle(color: Colors.orange),
              inputDecorationTheme: InputDecorationTheme(
                labelStyle: TextStyle(color: Colors.orange),
                border: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange, width: 2)),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _addNote() async {
    if (_noteController.text.isNotEmpty) {
      DateTime finalDateTime = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, _selectedTime.hour, _selectedTime.minute);
      await FirebaseFirestore.instance.collection("notes").add({
        "date": DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day).toIso8601String(),
        "time": _selectedTime.format(context),
        "note": _noteController.text,
        "datetime": finalDateTime.toIso8601String(),
        "created_at": DateTime.now(),
      });
      _noteController.clear();
    }
  }

  void _editNote(DocumentSnapshot note) async {
    _noteController.text = note['note'];
    TimeOfDay editTime = _selectedTime;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text("Edit Note", style: TextStyle(color: Colors.orange)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _noteController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Enter updated note",
                hintStyle: TextStyle(color: Colors.orange.withOpacity(0.6)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange, width: 2)),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final picked = await showTimePicker(context: context, initialTime: editTime, builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      timePickerTheme: TimePickerThemeData(
                        hourMinuteTextColor: Colors.white,
                        hourMinuteColor: Colors.orange.withOpacity(0.2),
                        dialHandColor: Colors.orange,
                        dialBackgroundColor: Colors.black,
                        entryModeIconColor: Colors.orange,
                        dayPeriodTextColor: Colors.orange,
                        dayPeriodColor: Colors.orange.withOpacity(0.2),
                        helpTextStyle: TextStyle(color: Colors.orange),
                        inputDecorationTheme: InputDecorationTheme(
                          labelStyle: TextStyle(color: Colors.orange),
                          border: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange, width: 2)),
                        ),
                      ),
                    ),
                    child: child!,
                  );
                });
                if (picked != null) {
                  setState(() {
                    editTime = picked;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: BorderSide(color: Colors.orange, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text("Pick Time", style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: TextStyle(color: Colors.orange))),
          TextButton(
            onPressed: () async {
              DateTime finalDateTime = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, editTime.hour, editTime.minute);
              await FirebaseFirestore.instance.collection("notes").doc(note.id).update({
                "note": _noteController.text,
                "time": editTime.format(context),
                "datetime": finalDateTime.toIso8601String(),
              });
              _noteController.clear();
              Navigator.pop(context);
            },
            child: Text("Save", style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _deleteNote(String id) async {
    await FirebaseFirestore.instance.collection("notes").doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("My Calendar", style: TextStyle(color: Colors.orange)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.orange),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.withOpacity(0.1), Colors.black],
          ),
        ),
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _selectedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                });
              },
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                leftChevronIcon: Icon(Icons.chevron_left, color: Colors.orange),
                rightChevronIcon: Icon(Icons.chevron_right, color: Colors.orange),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: Colors.orange),
                weekendStyle: TextStyle(color: Colors.orange),
              ),
              calendarStyle: CalendarStyle(
                defaultTextStyle: TextStyle(color: Colors.white),
                weekendTextStyle: TextStyle(color: Colors.white70),
                todayDecoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                outsideDaysVisible: false,
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getNotes(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Error loading notes: ${snapshot.error}', style: TextStyle(color: Colors.orange), textAlign: TextAlign.center)));
                  }
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator(color: Colors.orange));
                  }
                  final notes = snapshot.data!.docs.toList();
                  notes.sort((a, b) {
                    final ad = DateTime.tryParse(a['datetime'] ?? '') ?? DateTime(0);
                    final bd = DateTime.tryParse(b['datetime'] ?? '') ?? DateTime(0);
                    return ad.compareTo(bd);
                  });
                  if (notes.isEmpty) {
                    return Center(child: Text("No notes for this day", style: TextStyle(color: Colors.orange)));
                  }
                  return ListView.builder(
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      final timeString = note['time'] ?? '';
                      final noteText = note['note'] ?? '';
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(border: Border.all(color: Colors.orange.withOpacity(0.3)), borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                            child: Center(child: Text('${index + 1}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                          ),
                          title: Text(timeString, style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600, fontSize: 16)),
                          subtitle: Text(noteText, style: TextStyle(color: Colors.white, fontSize: 14)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: Icon(Icons.edit, color: Colors.blue), onPressed: () => _editNote(note)),
                              IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteNote(note.id)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _noteController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Enter note",
                        hintStyle: TextStyle(color: Colors.orange.withOpacity(0.6)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange), borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange, width: 2), borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    width: 48,
                    child: ElevatedButton(
                      onPressed: _pickTime,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        side: BorderSide(color: Colors.orange, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: Icon(Icons.access_time, color: Colors.orange),
                    ),
                  ),
                  SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    width: 48,
                    child: ElevatedButton(
                      onPressed: _addNote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}

class SparkleParticle {
  final double x, y, size, rotation;
  SparkleParticle({required this.x, required this.y, required this.size, required this.rotation});
}

class SparklesPainter extends CustomPainter {
  final List<SparkleParticle> sparkles;
  final double opacity;
  SparklesPainter(this.sparkles, this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    for (final sparkle in sparkles) {
      final center = Offset(sparkle.x * size.width, sparkle.y * size.height);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(sparkle.rotation);
      final rect = Rect.fromCenter(center: Offset.zero, width: sparkle.size * 4, height: sparkle.size * 4);
      final gradient = RadialGradient(colors: [
        Colors.yellow.withOpacity(opacity),
        Colors.orange.withOpacity(opacity * 0.8),
        Colors.orange.withOpacity(opacity * 0.3),
        Colors.transparent,
      ], stops: [0.0, 0.3, 0.7, 1.0]);
      final paint = Paint()..shader = gradient.createShader(rect)..style = PaintingStyle.fill;
      final path = Path();
      path.moveTo(0, -sparkle.size * 2);
      path.quadraticBezierTo(-sparkle.size * 0.3, -sparkle.size * 0.3, -sparkle.size * 2, 0);
      path.quadraticBezierTo(-sparkle.size * 0.3, sparkle.size * 0.3, 0, sparkle.size * 2);
      path.quadraticBezierTo(sparkle.size * 0.3, sparkle.size * 0.3, sparkle.size * 2, 0);
      path.quadraticBezierTo(sparkle.size * 0.3, -sparkle.size * 0.3, 0, -sparkle.size * 2);
      path.close();
      canvas.drawPath(path, paint);
      final corePaint = Paint()..color = Colors.white.withOpacity(opacity * 0.8)..style = PaintingStyle.fill;
      final corePath = Path();
      final coreSize = sparkle.size * 0.6;
      corePath.moveTo(0, -coreSize);
      corePath.quadraticBezierTo(-coreSize * 0.2, -coreSize * 0.2, -coreSize, 0);
      corePath.quadraticBezierTo(-coreSize * 0.2, coreSize * 0.2, 0, coreSize);
      corePath.quadraticBezierTo(coreSize * 0.2, coreSize * 0.2, coreSize, 0);
      corePath.quadraticBezierTo(coreSize * 2, -coreSize * 0.2, 0, -coreSize);
      corePath.close();
      canvas.drawPath(corePath, corePaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DivaLampPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = Colors.brown[600]!;
    final diyaPath = Path();
    diyaPath.moveTo(size.width * 0.15, size.height * 0.65);
    diyaPath.quadraticBezierTo(size.width * 0.1, size.height * 0.6, size.width * 0.1, size.height * 0.7);
    diyaPath.quadraticBezierTo(size.width * 0.12, size.height * 0.75, size.width * 0.2, size.height * 0.73);
    diyaPath.quadraticBezierTo(size.width * 0.5, size.height * 0.85, size.width * 0.8, size.height * 0.73);
    diyaPath.quadraticBezierTo(size.width * 0.85, size.height * 0.7, size.width * 0.82, size.height * 0.65);
    diyaPath.quadraticBezierTo(size.width * 0.5, size.height * 0.6, size.width * 0.15, size.height * 0.65);
    canvas.drawPath(diyaPath, paint);
    paint.color = Colors.brown[800]!;
    final innerBowlPath = Path();
    innerBowlPath.moveTo(size.width * 0.18, size.height * 0.66);
    innerBowlPath.quadraticBezierTo(size.width * 0.5, size.height * 0.62, size.width * 0.78, size.height * 0.66);
    innerBowlPath.quadraticBezierTo(size.width * 0.75, size.height * 0.7, size.width * 0.5, size.height * 0.75);
    innerBowlPath.quadraticBezierTo(size.width * 0.25, size.height * 0.7, size.width * 0.18, size.height * 0.66);
    canvas.drawPath(innerBowlPath, paint);
    paint.color = Colors.amber[700]!;
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.48, size.height * 0.67), width: size.width * 0.5, height: size.height * 0.08), paint);
    paint.color = Colors.brown[900]!;
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.13, size.height * 0.665), width: size.width * 0.025, height: size.height * 0.04), paint);
    paint.color = Colors.orange;
    final flamePath = Path();
    flamePath.moveTo(size.width * 0.13, size.height * 0.35);
    flamePath.quadraticBezierTo(size.width * 0.08, size.height * 0.45, size.width * 0.1, size.height * 0.55);
    flamePath.quadraticBezierTo(size.width * 0.11, size.height * 0.62, size.width * 0.13, size.height * 0.645);
    flamePath.quadraticBezierTo(size.width * 0.15, size.height * 0.62, size.width * 0.16, size.height * 0.55);
    flamePath.quadraticBezierTo(size.width * 0.18, size.height * 0.45, size.width * 0.13, size.height * 0.35);
    canvas.drawPath(flamePath, paint);
    paint.color = Colors.yellow;
    final innerFlamePath = Path();
    innerFlamePath.moveTo(size.width * 0.13, size.height * 0.4);
    innerFlamePath.quadraticBezierTo(size.width * 0.105, size.height * 0.48, size.width * 0.115, size.height * 0.56);
    innerFlamePath.quadraticBezierTo(size.width * 0.125, size.height * 0.62, size.width * 0.13, size.height * 0.64);
    innerFlamePath.quadraticBezierTo(size.width * 0.135, size.height * 0.62, size.width * 0.145, size.height * 0.56);
    innerFlamePath.quadraticBezierTo(size.width * 0.155, size.height * 0.48, size.width * 0.13, size.height * 0.4);
    canvas.drawPath(innerFlamePath, paint);
    paint.color = Colors.orange[400]!;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.5;
    for (double i = 0.25; i <= 0.75; i += 0.08) {
      canvas.drawCircle(Offset(size.width * i, size.height * 0.635), size.width * 0.008, Paint()..color = Colors.orange[400]!..style = PaintingStyle.fill);
    }
    paint.color = Colors.black.withOpacity(0.2);
    paint.style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.45, size.height * 0.88), width: size.width * 0.6, height: size.height * 0.08), paint);
    paint.style = PaintingStyle.fill;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}