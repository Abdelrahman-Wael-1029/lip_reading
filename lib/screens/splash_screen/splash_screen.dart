import 'dart:async';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lip_reading/cubit/auth/auth_cubit.dart';
import 'package:lip_reading/screens/auth/login_screen.dart';
import 'package:lip_reading/screens/lip_reading/lip_reading_screen.dart';
import 'package:lip_reading/utils/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String routeName = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  double ballY = 0;
  bool add = false;
  bool showShadow = false;
  int times = 0;
  bool showComic = false;

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: Duration(seconds: 1))
          ..addListener(() {
            if (add) {
              ballY += 15;
            } else {
              ballY -= 15;
            }

            if (ballY <= -200) {
              times += 1;
              add = true;
              showShadow = true;
            }
            if (ballY >= 0) {
              add = false;
              showShadow = false;
            }
            if (times == 3) {
              showShadow = false;
              Timer(Duration(milliseconds: 300), () {
                if (mounted) {
                  setState(() {
                    showComic = true;
                  });
                }
              });
              _controller.stop();
            }
            if (mounted) setState(() {}); // Only update if widget is mounted
          });

    // Navigate after 4 seconds
    Timer(Duration(seconds: 4), () {
      if (mounted) {
        final authCubit = context.read<AuthCubit>();
        Navigator.pushReplacementNamed(
            context,
            authCubit.isAuthenticated()
                ? LipReadingScreen.routeName
                : LoginScreen.routeName);
      }
    });

    _controller.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;
          double screenHeight = constraints.maxHeight;

          // Dynamically calculated values
          double widthVal = times < 3 ? 50 + (times * 50) : screenWidth;
          double heightVal = times < 3 ? 50 + (times * 50) : screenHeight;
          double bottomVal = times < 3 ? screenHeight * 0.6 - (times * 200) : 0;

          return Stack(
            alignment: Alignment.center,
            children: [
              LogoAnimation(
                bottomVal: bottomVal,
                heightVal: heightVal,
                ballY: ballY,
                times: times,
                showShadow: showShadow,
                widthVal: widthVal,
              ),
              if (showComic)
                Positioned(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chrome_reader_mode_outlined,
                            size: 60,
                            color: AppColors.white,
                          ),
                          SizedBox(width: 10),
                          DefaultTextStyle(
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 30.0,
                              fontFamily: 'Bobbers',
                            ),
                            child: AnimatedTextKit(
                              totalRepeatCount: 1,
                              animatedTexts: [
                                TyperAnimatedText('Lip Reading'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      TextInSplash(text: 'Know what they are saying'),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class LogoAnimation extends StatelessWidget {
  const LogoAnimation({
    super.key,
    required this.bottomVal,
    required this.widthVal,
    required this.heightVal,
    required this.ballY,
    required this.times,
    required this.showShadow,
  });

  final double bottomVal;
  final double widthVal;
  final double heightVal;
  final double ballY;
  final int times;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      bottom: bottomVal,
      duration: Duration(milliseconds: 600),
      child: Column(
        children: [
          Transform.translate(
            offset: Offset(0, ballY),
            child: AnimatedScale(
              duration: Duration(milliseconds: 200),
              scale: times == 3 ? 5 : 1,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 1000),
                width: widthVal,
                height: heightVal,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor),
              ),
            ),
          ),
          if (showShadow)
            Container(
              width: 50,
              height: 10,
              decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.2),
                  borderRadius: BorderRadius.circular(100)),
            ),
        ],
      ),
    );
  }
}

class TextInSplash extends StatelessWidget {
  final String text;
  const TextInSplash({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 24,
      ),
      child: AnimatedTextKit(
        totalRepeatCount: 1,
        animatedTexts: [
          TypewriterAnimatedText(
            text,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
