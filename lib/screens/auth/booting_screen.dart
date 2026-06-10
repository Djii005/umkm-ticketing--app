import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// Provider for boot completion state
final bootCompletedProvider = StateProvider<bool>((ref) => false);

class BootingScreen extends ConsumerStatefulWidget {
  const BootingScreen({super.key});

  @override
  ConsumerState<BootingScreen> createState() => _BootingScreenState();
}

class _BootingScreenState extends ConsumerState<BootingScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeIn;
  late Animation<double> _pulse;
  
  double _loadingProgress = 0.0;
  String _statusText = 'Menginisialisasi sistem...';
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _pulse = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _startLoadingSimulation();
  }

  void _startLoadingSimulation() {
    const steps = [
      {'progress': 0.2, 'text': 'Menghubungkan ke server aman...'},
      {'progress': 0.5, 'text': 'Sinkronisasi modul alat medis...'},
      {'progress': 0.8, 'text': 'Mempersiapkan dasbor interaktif...'},
      {'progress': 1.0, 'text': 'Sistem siap!'}
    ];

    int currentStep = 0;
    
    _progressTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (!mounted) return;
      
      setState(() {
        _loadingProgress = steps[currentStep]['progress'] as double;
        _statusText = steps[currentStep]['text'] as String;
      });

      if (currentStep == steps.length - 1) {
        timer.cancel();
        // Give 400ms to show 100% then transition
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            ref.read(bootCompletedProvider.notifier).state = true;
          }
        });
      } else {
        currentStep++;
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A), // Slate 900
              Color(0xFF020617), // Slate 950
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background glow
            Positioned(
              top: -100,
              left: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      blurRadius: 100,
                      spreadRadius: 50,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.12),
                      blurRadius: 120,
                      spreadRadius: 60,
                    ),
                  ],
                ),
              ),
            ),
            
            // Core content
            FadeTransition(
              opacity: _fadeIn,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      // Glowing Premium Custom Logo
                      ScaleTransition(
                        scale: _pulse,
                        child: CustomPaint(
                          size: const Size(120, 120),
                          painter: LogoPainter(),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Title with elegant fonts
                      Text(
                        'PT. ARSYA ANAKTA MEDIKAL',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2.0,
                          shadows: [
                            Shadow(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                              offset: const Offset(0, 4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'MOBILE TICKETING SYSTEM',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF94A3B8), // Slate 400
                          letterSpacing: 4.0,
                        ),
                      ),
                      const Spacer(),
                      // Status Text
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _statusText,
                          key: ValueKey<String>(_statusText),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B), // Slate 500
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Glowing Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          children: [
                            Container(
                              height: 6,
                              width: double.infinity,
                              color: const Color(0xFF1E293B), // Slate 800
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              height: 6,
                              width: MediaQuery.of(context).size.width * 0.8 * _loadingProgress,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF3B82F6), // Royal Blue
                                    Color(0xFF06B6D4), // Teal
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF3B82F6),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter to draw a modern glowing medical shield + check
class LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Glowing effect
    final shadowPaint = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    
    final path = Path()
      ..moveTo(w * 0.5, h * 0.05) // Top Center
      ..quadraticBezierTo(w * 0.8, h * 0.05, w * 0.85, h * 0.15)
      ..quadraticBezierTo(w * 0.9, h * 0.5, w * 0.5, h * 0.95) // Pointy Bottom
      ..quadraticBezierTo(w * 0.1, h * 0.5, w * 0.15, h * 0.15)
      ..quadraticBezierTo(w * 0.2, h * 0.05, w * 0.5, h * 0.05)
      ..close();

    canvas.drawPath(path, shadowPaint);

    // Main Shield Gradient Fill
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF2563EB), // Royal Blue
          Color(0xFF1E3A8A), // Dark Navy Blue
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);

    // Border Glow Line
    final borderPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF60A5FA),
          Color(0xFF06B6D4),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    canvas.drawPath(path, borderPaint);

    // Inner Glowing Cross
    final crossPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    // Draw stylized medical plus / ticket mark inside
    // Vertical line
    canvas.drawLine(Offset(w * 0.5, h * 0.3), Offset(w * 0.5, h * 0.65), crossPaint);
    // Horizontal line
    canvas.drawLine(Offset(w * 0.32, h * 0.475), Offset(w * 0.68, h * 0.475), crossPaint);
    
    // Add minor secondary highlights
    final dotPaint = Paint()
      ..color = const Color(0xFF06B6D4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.2), 4.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
