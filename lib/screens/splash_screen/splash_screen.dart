import 'dart:async';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:lip_reading/utils/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

double width(BuildContext context) {
  return MediaQuery.of(context).size.width;
}

double height(BuildContext context) {
  return MediaQuery.of(context).size.height;
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  double ballY = 0;
  double widthVal = 50;
  double heightVal = 50;
  double bottomVal = 500;
  bool add = false;
  bool showShadow = false;
  int times = 0;
  bool showComic = false;

  late AnimationController _controller;

  @override
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
              widthVal += 50;
              heightVal += 50;
              bottomVal -= 200;
            }
            if (times == 3) {
              showShadow = false;
              widthVal = width(context);
              heightVal = height(context);
              Timer(Duration(milliseconds: 300), () {
                setState(() {
                  showComic = true;
                });
              });
              _controller.stop();
            }
            setState(() {});
          });

    _controller.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      body: SizedBox(
        width: width(context),
        height: height(context),
        child: Stack(
          alignment: Alignment.center,
          children: [
            LogoAnimation(
                bottomVal: bottomVal,
                heightVal: heightVal,
                ballY: ballY,
                times: times,
                showShadow: showShadow,
                widthVal: widthVal),
            if (showComic)
              Positioned(
                  child: Column(
                // mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chrome_reader_mode_outlined, // Bus icon
                        size: 60,
                        color: AppColors.secondaryColor, // Purple icon
                      ),
                      SizedBox(width: 10),
                      DefaultTextStyle(
                        style: const TextStyle(
                          color: Color.fromARGB(255, 49, 47, 47),
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
              ))
          ],
        ),
      ),
    );
  }
}

class LogoAnimation extends StatelessWidget {
  const LogoAnimation(
      {super.key,
      required this.bottomVal,
      required this.widthVal,
      required this.heightVal,
      required this.ballY,
      required this.times,
      required this.showShadow});
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
                    shape: BoxShape.circle, color: AppColors.primaryColor),
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
            )
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
        // fontFamily: 'Agne',
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
