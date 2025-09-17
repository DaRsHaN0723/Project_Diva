import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'firebase_options.dart'; // auto-generated when you added Firebase
import 'dart:async';
import 'dart:math';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Test Firebase connection
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
    
    // Diva scaling animation
    _divaController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _divaScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _divaController, curve: Curves.elasticOut),
    );
    
    // Sparkle animation
    _sparkleController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );
    _sparkleOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeIn),
    );
    
    // Loading animation
    _loadingController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );
    
    _startAnimationSequence();
    _generateSparkles();
  }
  
  void _generateSparkles() {
    _sparkles = List.generate(15, (index) => SparkleParticle(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      size: _random.nextDouble() * 8 + 6, // Increased from 4+2 to 8+6
      rotation: _random.nextDouble() * 2 * pi,
    ));
  }
  
  void _startAnimationSequence() async {
    // Start diva animation
    await _divaController.forward();
    
    // Show sparkles and start sparkle animation
    setState(() => _showSparkles = true);
    _sparkleController.forward();
    
    // Show loading bar and start loading
    setState(() => _showLoading = true);
    await _loadingController.forward();
    
    // Navigate to login after completion
    await Future.delayed(Duration(milliseconds: 500));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
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
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [Colors.orange.withOpacity(0.2), Colors.black],
                stops: [0.3, 1.0],
              ),
            ),
          ),
          
          // Sparkles
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
          
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Diva (Lamp) Animation
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
                
                // Loading bar
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

class SparkleParticle {
  final double x;
  final double y;
  final double size;
  final double rotation;
  
  SparkleParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.rotation,
  });
}

class SparklesPainter extends CustomPainter {
  final List<SparkleParticle> sparkles;
  final double opacity;
  
  SparklesPainter(this.sparkles, this.opacity);
  
  @override
  void paint(Canvas canvas, Size size) {
    for (final sparkle in sparkles) {
      final center = Offset(
        sparkle.x * size.width,
        sparkle.y * size.height,
      );
      
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(sparkle.rotation);
      
      // Create gradient paint for sparkle
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: sparkle.size * 4,
        height: sparkle.size * 4,
      );
      
      final gradient = RadialGradient(
        colors: [
          Colors.yellow.withOpacity(opacity),
          Colors.orange.withOpacity(opacity * 0.8),
          Colors.orange.withOpacity(opacity * 0.3),
          Colors.transparent,
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      );
      
      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.fill;
      
      // Draw 4-pointed star shape
      final path = Path();
      
      // Top point
      path.moveTo(0, -sparkle.size * 2);
      path.quadraticBezierTo(-sparkle.size * 0.3, -sparkle.size * 0.3, -sparkle.size * 2, 0);
      
      // Left point
      path.quadraticBezierTo(-sparkle.size * 0.3, sparkle.size * 0.3, 0, sparkle.size * 2);
      
      // Bottom point
      path.quadraticBezierTo(sparkle.size * 0.3, sparkle.size * 0.3, sparkle.size * 2, 0);
      
      // Right point
      path.quadraticBezierTo(sparkle.size * 0.3, -sparkle.size * 0.3, 0, -sparkle.size * 2);
      
      path.close();
      
      canvas.drawPath(path, paint);
      
      // Add inner bright core
      final corePaint = Paint()
        ..color = Colors.white.withOpacity(opacity * 0.8)
        ..style = PaintingStyle.fill;
      
      final corePath = Path();
      final coreSize = sparkle.size * 0.6;
      
      // Smaller inner star
      corePath.moveTo(0, -coreSize);
      corePath.quadraticBezierTo(-coreSize * 0.2, -coreSize * 0.2, -coreSize, 0);
      corePath.quadraticBezierTo(-coreSize * 0.2, coreSize * 0.2, 0, coreSize);
      corePath.quadraticBezierTo(coreSize * 0.2, coreSize * 0.2, coreSize, 0);
      corePath.quadraticBezierTo(coreSize * 0.2, -coreSize * 0.2, 0, -coreSize);
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
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    // Main diya bowl (traditional teardrop shape)
    paint.color = Colors.brown[600]!;
    final diyaPath = Path();
    
    // Start from the spout (left side)
    diyaPath.moveTo(size.width * 0.15, size.height * 0.65);
    
    // Left side of spout
    diyaPath.quadraticBezierTo(
      size.width * 0.1, size.height * 0.6,
      size.width * 0.1, size.height * 0.7,
    );
    
    // Bottom curve of spout
    diyaPath.quadraticBezierTo(
      size.width * 0.12, size.height * 0.75,
      size.width * 0.2, size.height * 0.73,
    );
    
    // Main bowl bottom
    diyaPath.quadraticBezierTo(
      size.width * 0.5, size.height * 0.85,
      size.width * 0.8, size.height * 0.73,
    );
    
    // Right side of bowl
    diyaPath.quadraticBezierTo(
      size.width * 0.85, size.height * 0.7,
      size.width * 0.82, size.height * 0.65,
    );
    
    // Top rim of bowl
    diyaPath.quadraticBezierTo(
      size.width * 0.5, size.height * 0.6,
      size.width * 0.15, size.height * 0.65,
    );
    
    canvas.drawPath(diyaPath, paint);
    
    // Inner bowl (oil container)
    paint.color = Colors.brown[800]!;
    final innerBowlPath = Path();
    innerBowlPath.moveTo(size.width * 0.18, size.height * 0.66);
    innerBowlPath.quadraticBezierTo(
      size.width * 0.5, size.height * 0.62,
      size.width * 0.78, size.height * 0.66,
    );
    innerBowlPath.quadraticBezierTo(
      size.width * 0.75, size.height * 0.7,
      size.width * 0.5, size.height * 0.75,
    );
    innerBowlPath.quadraticBezierTo(
      size.width * 0.25, size.height * 0.7,
      size.width * 0.18, size.height * 0.66,
    );
    canvas.drawPath(innerBowlPath, paint);
    
    // Oil surface (golden)
    paint.color = Colors.amber[700]!;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.48, size.height * 0.67),
        width: size.width * 0.5,
        height: size.height * 0.08,
      ),
      paint,
    );
    
    // Wick in the spout
    paint.color = Colors.brown[900]!;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.13, size.height * 0.665),
        width: size.width * 0.025,
        height: size.height * 0.04,
      ),
      paint,
    );
    
    // Main flame from the spout
    paint.color = Colors.orange;
    final flamePath = Path();
    flamePath.moveTo(size.width * 0.13, size.height * 0.35);
    
    // Left side of flame
    flamePath.quadraticBezierTo(
      size.width * 0.08, size.height * 0.45,
      size.width * 0.1, size.height * 0.55,
    );
    flamePath.quadraticBezierTo(
      size.width * 0.11, size.height * 0.62,
      size.width * 0.13, size.height * 0.645,
    );
    
    // Right side of flame
    flamePath.quadraticBezierTo(
      size.width * 0.15, size.height * 0.62,
      size.width * 0.16, size.height * 0.55,
    );
    flamePath.quadraticBezierTo(
      size.width * 0.18, size.height * 0.45,
      size.width * 0.13, size.height * 0.35,
    );
    
    canvas.drawPath(flamePath, paint);
    
    // Inner flame (yellow core)
    paint.color = Colors.yellow;
    final innerFlamePath = Path();
    innerFlamePath.moveTo(size.width * 0.13, size.height * 0.4);
    innerFlamePath.quadraticBezierTo(
      size.width * 0.105, size.height * 0.48,
      size.width * 0.115, size.height * 0.56,
    );
    innerFlamePath.quadraticBezierTo(
      size.width * 0.125, size.height * 0.62,
      size.width * 0.13, size.height * 0.64,
    );
    innerFlamePath.quadraticBezierTo(
      size.width * 0.135, size.height * 0.62,
      size.width * 0.145, size.height * 0.56,
    );
    innerFlamePath.quadraticBezierTo(
      size.width * 0.155, size.height * 0.48,
      size.width * 0.13, size.height * 0.4,
    );
    canvas.drawPath(innerFlamePath, paint);
    
    // Decorative patterns on diya
    paint.color = Colors.orange[400]!;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.5;
    
    // Decorative dots around the rim
    for (double i = 0.25; i <= 0.75; i += 0.08) {
      canvas.drawCircle(
        Offset(size.width * i, size.height * 0.635),
        size.width * 0.008,
        Paint()..color = Colors.orange[400]!..style = PaintingStyle.fill,
      );
    }
    
    // Base shadow/reflection
    paint.color = Colors.black.withOpacity(0.2);
    paint.style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.45, size.height * 0.88),
        width: size.width * 0.6,
        height: size.height * 0.08,
      ),
      paint,
    );
    
    paint.style = PaintingStyle.fill;
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    
    // Simulate login process
    await Future.delayed(Duration(seconds: 1));
    
    if (_usernameController.text.isNotEmpty && 
        _passwordController.text.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter both username and password')),
      );
    }
    
    setState(() => _isLoading = false);
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
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App title
                Text(
                  'Diva',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 50),
                
                // Username field
                TextFormField(
                  controller: _usernameController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: Colors.orange),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.orange),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.orange, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.person, color: Colors.orange),
                  ),
                ),
                SizedBox(height: 20),
                
                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.orange),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.orange),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.orange, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.lock, color: Colors.orange),
                  ),
                ),
                SizedBox(height: 40),
                
                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            try {
                              if (kIsWeb ||
                                  defaultTargetPlatform == TargetPlatform.android ||
                                  defaultTargetPlatform == TargetPlatform.iOS) {
                                await FirebaseAnalytics.instance.logEvent(
                                  name: 'button_click',
                                  parameters: {
                                    'button_name': 'login_button',
                                    'timestamp': DateTime.now().toString(),
                                  },
                                );
                              }
                            } catch (_) {
                              // Ignore analytics errors on unsupported platforms
                            }
                            await _login();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class HomePage extends StatelessWidget {
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
              // Top bar with settings button
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
                      'Your App Name Here',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 48), // Balance the row
                  ],
                ),
              ),
              
              Spacer(),
              
              // Main feature buttons
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    _buildFeatureButton(
                      context,
                      'Home Automation',
                      Icons.home_outlined,
                    ),
                    SizedBox(height: 20),
                    _buildFeatureButton(
                      context,
                      'Festival',
                      Icons.celebration_outlined,
                    ),
                    SizedBox(height: 20),
                    _buildFeatureButton(
                      context,
                      'Spiritual Wellness',
                      Icons.spa_outlined,
                    ),
                  ],
                ),
              ),
              
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureButton(BuildContext context, String title, IconData icon) {
    return Container(
      width: double.infinity,
      height: 70,
      child: ElevatedButton(
        onPressed: () {
          Widget page;
          switch (title) {
            case 'Home Automation':
              page = HomeAutomationPage();
              break;
            case 'Festival':
              page = FestivalPage();
              break;
            case 'Spiritual Wellness':
              page = SpiritualWellnessPage();
              break;
            default:
              return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          side: BorderSide(color: Colors.orange, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.orange, size: 24),
            SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Settings Page
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
        child: Center(
          child: Text(
            'Settings Page',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// Home Automation Page
class HomeAutomationPage extends StatelessWidget {
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
          child: Padding(
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
                _buildAutomationActionButton(
                  context,
                  title: 'Integrated Calender',
                  icon: Icons.calendar_month_outlined,
                ),
                SizedBox(height: 16),
                _buildAutomationActionButton(
                  context,
                  title: 'Motion Detection',
                  icon: Icons.motion_photos_on_outlined,
                ),
                SizedBox(height: 16),
                _buildAutomationActionButton(
                  context,
                  title: 'Voice Greeting',
                  icon: Icons.record_voice_over_outlined,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAutomationActionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
  }) {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: () {
          if (title == 'Integrated Calender') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CalendarPage()),
            );
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title selected')),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          side: BorderSide(color: Colors.orange, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.orange, size: 22),
            SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Festival Page
class FestivalPage extends StatelessWidget {
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
          child: Padding(
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
                _buildFestivalActionButton(
                  context,
                  title: 'Normal',
                  icon: Icons.light_mode_outlined,
                ),
                SizedBox(height: 16),
                _buildFestivalActionButton(
                  context,
                  title: 'Aarti',
                  icon: Icons.local_fire_department_outlined,
                ),
                SizedBox(height: 16),
                _buildFestivalActionButton(
                  context,
                  title: 'Bhajan',
                  icon: Icons.library_music_outlined,
                ),
                SizedBox(height: 16),
                _buildFestivalActionButton(
                  context,
                  title: 'Smart Light',
                  icon: Icons.wb_incandescent_outlined,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFestivalActionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
  }) {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title selected')),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          side: BorderSide(color: Colors.orange, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.orange, size: 22),
            SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Spiritual Wellness Page
class SpiritualWellnessPage extends StatelessWidget {
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
          child: Padding(
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
                _buildWellnessActionButton(
                  context,
                  title: 'Meditation',
                  icon: Icons.self_improvement,
                ),
                SizedBox(height: 16),
                _buildWellnessActionButton(
                  context,
                  title: 'Claming',
                  icon: Icons.nightlight_outlined,
                ),
                SizedBox(height: 16),
                _buildWellnessActionButton(
                  context,
                  title: 'Healing',
                  icon: Icons.healing_outlined,
                ),
                SizedBox(height: 16),
                _buildWellnessActionButton(
                  context,
                  title: 'Chanting',
                  icon: Icons.library_music_outlined,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWellnessActionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
  }) {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title selected')),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          side: BorderSide(color: Colors.orange, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.orange, size: 22),
            SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Integrated Calendar Page (matches app theme)
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
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange, width: 2),
                ),
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
      DateTime finalDateTime = DateTime(
        _selectedDay.year,
        _selectedDay.month,
        _selectedDay.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await FirebaseFirestore.instance.collection("notes").add({
        "date": DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day).toIso8601String(),
        "time": _selectedTime.format(context), // This will show AM/PM format
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
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange, width: 2),
                ),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: editTime,
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
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.orange),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.orange, width: 2),
                            ),
                          ),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() {
                    editTime = picked;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: BorderSide(color: Colors.orange, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text("Pick Time", style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () async {
              DateTime finalDateTime = DateTime(
                _selectedDay.year,
                _selectedDay.month,
                _selectedDay.day,
                editTime.hour,
                editTime.minute,
              );

              await FirebaseFirestore.instance
                  .collection("notes")
                  .doc(note.id)
                  .update({
                "note": _noteController.text,
                "time": editTime.format(context), // This will show AM/PM format
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
                todayDecoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                outsideDaysVisible: false,
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getNotes(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Error loading notes: ${snapshot.error}',
                          style: TextStyle(color: Colors.orange),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator(color: Colors.orange));
                  }
                  final notes = snapshot.data!.docs.toList();

                  // Client-side sort by the stored datetime string
                  notes.sort((a, b) {
                    final ad = DateTime.tryParse(a['datetime'] ?? '') ?? DateTime(0);
                    final bd = DateTime.tryParse(b['datetime'] ?? '') ?? DateTime(0);
                    return ad.compareTo(bd);
                  });

                  if (notes.isEmpty) {
                    return Center(
                      child: Text(
                        "No notes for this day",
                        style: TextStyle(color: Colors.orange),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      final timeString = note['time'] ?? '';
                      final noteText = note['note'] ?? '';
                      
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            timeString,
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            noteText,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editNote(note),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteNote(note.id),
                              ),
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
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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