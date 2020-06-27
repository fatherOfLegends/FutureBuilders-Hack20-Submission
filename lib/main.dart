import 'package:flame/game.dart';
import 'package:flame/gestures.dart';
import 'package:flame/util.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  Util flameUtil = Util();
  WidgetsFlutterBinding.ensureInitialized();
  await flameUtil.fullScreen();
  await flameUtil.setOrientation(DeviceOrientation.portraitUp);

  BoxGame game = BoxGame();
  runApp(game.widget);
}

class BoxGame extends Game with TapDetector {
  Size screenSize;
  bool hasWon = false;

  double scaleFactor = 1.0;
  bool shrink = false;

  void render(Canvas canvas) {
    // draw a black background on the whole screen
    Rect bgRect = Rect.fromLTWH(0, 0, screenSize.width, screenSize.height);
    Paint bgPaint = Paint();
    bgPaint.color = Color(0xff000000);
    canvas.drawRect(bgRect, bgPaint);

    if (scaleFactor >= 1.2) {
      shrink = true;
    } else if (scaleFactor <= 1.0) {
      shrink = false;
    }
    scaleFactor = shrink ? scaleFactor * .99 : scaleFactor * 1.01;

    // draw a box (make it green if won, white otherwise)
    double screenCenterX = screenSize.width / 2;
    double screenCenterY = screenSize.height / 2;
    Rect boxRect = Rect.fromLTWH(
      screenCenterX - 75 * scaleFactor,
      screenCenterY - 75 * scaleFactor,
      150 * scaleFactor,
      150 * scaleFactor,
    );
    Paint boxPaint = Paint();
    if (hasWon) {
      boxPaint.color = Color(0xfffe00fe);
    } else {
      boxPaint.color = Color(0xff00b3fe);
    }
    canvas.drawRect(boxRect, boxPaint);
  }

  void update(double t) {}

  void resize(Size size) {
    screenSize = size;
    super.resize(size);
  }

  @override
  void onTapDown(TapDownDetails d) {
    double screenCenterX = screenSize.width / 2;
    double screenCenterY = screenSize.height / 2;
    if (d.globalPosition.dx >= screenCenterX - 75 &&
        d.globalPosition.dx <= screenCenterX + 75 &&
        d.globalPosition.dy >= screenCenterY - 75 &&
        d.globalPosition.dy <= screenCenterY + 75) {
      hasWon = true;
    } else {
      hasWon = false;
    }
  }
}
