import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/anchor.dart';
import 'package:flame/components/component.dart';
import 'package:flame/components/mixins/has_game_ref.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/gestures.dart';
import 'package:flame/palette.dart';
import 'package:flame/position.dart';
import 'package:flame/text_config.dart';
import 'package:flame/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  Util flameUtil = Util();
  WidgetsFlutterBinding.ensureInitialized();
  await flameUtil.fullScreen();
  await flameUtil.setOrientation(DeviceOrientation.portraitUp);

  final game = MyGame();
  runApp(game.widget);
  /*BoxGame game = BoxGame();
  runApp(
    Stack(
      children: [
        game.widget,
        Image.asset('images/neon-background.jpg'),
        Align(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Image.asset(
              'images/car.png',
              width: 100,
              height: 200,
            ),
          ),
          alignment: Alignment.bottomCenter,
        ),
      ],
      textDirection: TextDirection.ltr,
      alignment: Alignment.topCenter,
    ),
  );*/
}

class Palette {
  static const PaletteEntry white = BasicPalette.white;
  static const PaletteEntry magenta = PaletteEntry(Color(0xffF20098));
  static const PaletteEntry pink = PaletteEntry(Color(0xfffe00fe));
  static const PaletteEntry purple = PaletteEntry(Color(0xff7700a6));
  static const PaletteEntry blue = PaletteEntry(Color(0xff00b3fe));
}

class MyGame extends BaseGame with TapDetector {
  int score = 0;
  bool running = true;
  Size screenSize;
  ui.Image carImage;
  ui.Image carImageLeft;
  ui.Image carImageRight;
  ui.Image horizonImage;
  Ground ground;
  Car car;

  MyGame() {
    ground = Ground();
    add(ground);
    car = Car();
    add(car);
    add(Score());
    add(Pause());
    _loadImages();
  }

  void resize(Size size) {
    screenSize = size;
    super.resize(size);
  }

  @override
  void onTap() {
    ground.driftLeft = !ground.driftLeft;
    car.driftLeft = !car.driftLeft;
  }

  @override
  void onTapDown(TapDownDetails details) {
    if (details.globalPosition.dx > screenSize.width - 80 && details.globalPosition.dy < 48) {
      if (running) {
        pauseEngine();
      } else {
        resumeEngine();
      }

      running = !running;
    }
  }

  Future<void> _loadImages() async {
    carImage = await Flame.images.load('2.png');
    carImageLeft = await Flame.images.load('1.png');
    carImageRight = await Flame.images.load('3.png');
    horizonImage = await Flame.images.load('neon-background.png');
  }
}

class Score extends PositionComponent with HasGameRef<MyGame> {
  @override
  void render(Canvas c) {
    prepareCanvas(c);
    textConfig.render(c, 'Score: ${gameRef.score}', Position(24, 24));
  }
}

class Pause extends PositionComponent with HasGameRef<MyGame> {
  @override
  void render(Canvas c) {
    prepareCanvas(c);
    textConfig.render(c, 'Pause', Position(gameRef.screenSize.width - 94, 24));
  }
}

class Car extends PositionComponent with HasGameRef<MyGame> {
  static const SPEED = 0.25;

  bool driftLeft = true;

  @override
  void resize(Size size) {
    x = size.width * .3;
    y = size.height * .75;
  }

  @override
  void render(Canvas c) {
    prepareCanvas(c);
    if (gameRef.carImage != null) {
      c.save();
      c.scale(0.3, 0.3);
      if (angle < 0) {
        c.drawImage(gameRef.carImageRight, Offset(-180, -120), Paint());
      } else if (angle >= 0) {
        c.drawImage(gameRef.carImageLeft, Offset(-180, -120), Paint());
      }
      c.restore();
    }
  }

  @override
  void update(double t) {
    super.update(t);
    if (driftLeft) {
      angle = math.min(.1, angle + .01);
    } else {
      angle = math.max(-.1, angle - .01);
    }
  }

  @override
  void onMount() {
    anchor = Anchor.center;
  }
}

final textConfig = TextConfig(color: Palette.white.color);

class Ground extends PositionComponent with HasGameRef<MyGame> {
  double friction = 1;
  static const ROTATION_SPEED = 0.75;
  int currentTime = 0;
  bool driftLeft = true;
  int projectileLeftStartTime = 0;
  int projectileRightStartTime = 0;

  Size get screenSize => gameRef.screenSize;
  double get height => screenSize.height;
  double get width => screenSize.width;

  @override
  void resize(Size size) {
    x = size.width / 2;
    y = size.height / 2;
  }

  @override
  void render(Canvas c) {
    prepareCanvas(c);
    _drawBackground(c);
    _drawGamePlane(c, color: Palette.pink.color, stroke: 3, blendMode: BlendMode.srcOver);
    _drawGamePlane(c, color: Palette.white.color, stroke: 1, blendMode: BlendMode.luminosity);
    if (gameRef.horizonImage != null) {
      c.save();
      c.scale(0.45, 0.45);
      c.drawImage(gameRef.horizonImage, Offset(-100, 0), Paint());
      c.restore();
    }
  }

  void _drawGamePlane(Canvas canvas, {Color color, double stroke, BlendMode blendMode}) {
    Paint linePaint = Paint()
      ..strokeWidth = stroke
      ..blendMode = blendMode;
    if (color != Palette.white.color) {
      linePaint.shader = ui.Gradient.linear(
          Offset(width / 2, 0), Offset(width, height), [Palette.magenta.color, Palette.pink.color, color], [.3, .7, 1]);
    } else {
      linePaint.shader = ui.Gradient.linear(
          Offset(width / 2, 0), Offset(width, height), [Palette.pink.color, Palette.magenta.color, color], [.1, .3, 1]);
    }

    final lineSpacing = 60.0;
    final speedFactor = (currentTime % (132 * friction)) / (160 * friction);
    final movementAmount = (lineSpacing * speedFactor).floorToDouble();
    double lastLineY = height + movementAmount;
    final horizonY = height * .6;
    canvas.drawLine(Offset(0 - width, lastLineY), Offset(width + width, lastLineY), linePaint);
    while (lastLineY > horizonY * 1.04) {
      final factor = (lastLineY - horizonY) / horizonY;
      final lineY = lastLineY - lineSpacing * factor;
      canvas.drawLine(Offset(0 - width, lineY), Offset(width + width, lineY), linePaint);
      lastLineY = lineY;
    }

    final centerX = width / 2 * (1 - angle);
    canvas.drawLine(Offset(centerX, height), Offset(centerX, horizonY * 1.04), linePaint);
    for (int i = 1; i < 20; i++) {
      double topSpacing = lineSpacing * .3 * i;
      double bottomSpacing = lineSpacing * i;
      canvas.drawLine(
          Offset(centerX - bottomSpacing, height), Offset(centerX - topSpacing, horizonY * 1.04), linePaint);
      canvas.drawLine(
          Offset(centerX + bottomSpacing, height), Offset(centerX + topSpacing, horizonY * 1.04), linePaint);
      if (i == 5) {
        if (projectileLeftStartTime > 0) {
          final time = math.min(currentTime - projectileLeftStartTime, 2000) / 2000;
          if (time < 1) {
            final t = Curves.easeInQuad.transform(time);
            final teen = Tween<Offset>(
                begin: Offset(centerX + topSpacing, horizonY * 1.06), end: Offset(centerX + bottomSpacing, height));
            final size = Tween<double>(begin: 2, end: 40);
            canvas.drawCircle(teen.transform(t), size.transform(time), Paint()..color = Palette.blue.color);
          } else {
            projectileLeftStartTime = 0;
            gameRef.score++;
          }
        }
        if (projectileRightStartTime > 0) {
          final time = math.min(currentTime - projectileRightStartTime, 2000) / 2000;
          if (time < 1) {
            final t = Curves.easeInQuad.transform(time);
            final teen = Tween<Offset>(
                begin: Offset(centerX - topSpacing, horizonY * 1.06), end: Offset(centerX - bottomSpacing, height));
            final size = Tween<double>(begin: 2, end: 40);
            canvas.drawCircle(teen.transform(t), size.transform(time), Paint()..color = Palette.blue.color);
          } else {
            projectileRightStartTime = 0;
            gameRef.score++;
          }
        }
      }
    }
  }

  void _drawBackground(Canvas canvas) {
    Rect bgRect = Rect.fromLTWH(0, 0, screenSize.width, screenSize.height);
    Paint bgPaint = Paint();
    bgPaint.color = Color(0xff000000);
    canvas.drawRect(bgRect, bgPaint);
  }

  @override
  void update(double t) {
    super.update(t);
    currentTime += (t * 1000).toInt();
    if (driftLeft) {
      angle = math.max(-.2, angle - .01);
      if (projectileRightStartTime == 0) {
        projectileRightStartTime = currentTime;
      }
    } else {
      if (projectileLeftStartTime == 0) {
        projectileLeftStartTime = currentTime;
      }

      angle = math.min(.2, angle + .01);
    }
  }

  @override
  void onMount() {
    anchor = Anchor.center;
  }
}
