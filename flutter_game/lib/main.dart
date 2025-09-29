import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/services.dart';
import 'dart:math';

void main() {
  runApp(GameApp());
}

class GameApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Game Generator Pro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: GameWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GameWrapper extends StatefulWidget {
  @override
  _GameWrapperState createState() => _GameWrapperState();
}

class _GameWrapperState extends State<GameWrapper> {
  late AIGameGeneratorPro game;

  @override
  void initState() {
    super.initState();
    game = AIGameGeneratorPro();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(game: game),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          game.reset();
        },
        child: Icon(Icons.refresh),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

class AIGameGeneratorPro extends FlameGame with HasCollisionDetection, HasTappables {
  late Player player;
  late ScoreComponent scoreComponent;
  int score = 0;
  double spawnTimer = 0;
  final double spawnInterval = 2.0;
  final Random random = Random();

  @override
  Future<void> onLoad() async {
    // Add collision detection
    add(ScreenHitbox());
    
    // Create player
    player = Player();
    add(player);
    
    // Add score display
    scoreComponent = ScoreComponent();
    add(scoreComponent);
    
    // Add background
    add(Background());
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    spawnTimer += dt;
    if (spawnTimer >= spawnInterval) {
      spawnEnemy();
      spawnTimer = 0;
    }
  }

  void spawnEnemy() {
    final enemy = Enemy(
      position: Vector2(
        random.nextDouble() * size.x,
        -50,
      ),
    );
    add(enemy);
  }

  void increaseScore() {
    score += 10;
    scoreComponent.updateScore(score);
  }

  void reset() {
    score = 0;
    scoreComponent.updateScore(score);
    children.whereType<Enemy>().forEach((enemy) => enemy.removeFromParent());
    children.whereType<Collectible>().forEach((item) => item.removeFromParent());
    player.position = Vector2(size.x / 2, size.y * 0.8);
  }
}

class Player extends RectangleComponent with HasCollisionDetection, Tappable {
  late Vector2 velocity;
  final double speed = 200;

  @override
  Future<void> onLoad() async {
    size = Vector2(50, 50);
    position = Vector2(gameRef.size.x / 2, gameRef.size.y * 0.8);
    paint = Paint()..color = Colors.blue;
    velocity = Vector2.zero();
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    position += velocity * dt;
    
    // Keep player on screen
    position.x = position.x.clamp(0, gameRef.size.x - size.x);
    position.y = position.y.clamp(0, gameRef.size.y - size.y);
    
    // Gradually stop movement
    velocity *= 0.95;
  }

  @override
  bool onTapDown(TapDownInfo info) {
    final tapPosition = info.eventPosition.game;
    final direction = (tapPosition - position).normalized();
    velocity = direction * speed;
    return true;
  }

  @override
  bool onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Enemy) {
      // Handle collision with enemy
      other.removeFromParent();
      return true;
    } else if (other is Collectible) {
      // Handle collision with collectible
      other.removeFromParent();
      (gameRef as AIGameGeneratorPro).increaseScore();
      return true;
    }
    return false;
  }
}

class Enemy extends RectangleComponent with HasCollisionDetection {
  final double speed = 100;

  Enemy({required Vector2 position}) : super(position: position);

  @override
  Future<void> onLoad() async {
    size = Vector2(40, 40);
    paint = Paint()..color = Colors.red;
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += speed * dt;
    
    if (position.y > gameRef.size.y) {
      removeFromParent();
    }
  }
}

class Collectible extends CircleComponent with HasCollisionDetection {
  Collectible({required Vector2 position}) : super(position: position);

  @override
  Future<void> onLoad() async {
    radius = 15;
    paint = Paint()..color = Colors.green;
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += 50 * dt;
    
    if (position.y > gameRef.size.y) {
      removeFromParent();
    }
  }
}

class Background extends RectangleComponent {
  @override
  Future<void> onLoad() async {
    size = gameRef.size;
    paint = Paint()..color = Colors.black87;
  }
}

class ScoreComponent extends TextComponent {
  @override
  Future<void> onLoad() async {
    text = 'Score: 0';
    textRenderer = TextPaint(
      style: TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
    position = Vector2(20, 50);
  }

  void updateScore(int score) {
    text = 'Score: $score';
  }
}