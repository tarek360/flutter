import 'dart:math';
import 'dart:ui' show Vertices;
import 'package:flutter/material.dart';
import 'transformations_demo_board.dart';
import 'transformations_demo_edit_board_point.dart';
import 'transformations_demo_gesture_transformable.dart';

class TransformationsDemo extends StatefulWidget {
  const TransformationsDemo({ Key key }) : super(key: key);

  static const String routeName = '/transformations';

  @override _TransformationsDemoState createState() => _TransformationsDemoState();
}
class _TransformationsDemoState extends State<TransformationsDemo> {
  // The radius of a hexagon tile in pixels.
  static const double _kHexagonRadius = 32.0;
  // The margin between hexagons.
  static const double _kHexagonMargin = 1.0;
  // The radius of the entire board in hexagons, not including the center.
  static const int _kBoardRadius = 8;

  bool _reset = false;
  Board _board = Board(
    boardRadius: _kBoardRadius,
    hexagonRadius: _kHexagonRadius,
    hexagonMargin: _kHexagonMargin,
  );

  @override
  Widget build (BuildContext context) {
    final BoardPainter painter = BoardPainter(
      board: _board,
    );

    // The scene is drawn by a CustomPaint, but user interaction is handled by
    // the GestureTransformable parent widget.
    return Scaffold(
      appBar: AppBar(
        title: const Text('2D Tranformations'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.help),
            tooltip: 'Help',
            onPressed: () {
              showDialog<Column>(
                context: context,
                builder: (BuildContext context) => instructionDialog,
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // Draw the scene as big as is available, but allow the user to
          // translate beyond that to a visibleSize that's a bit bigger.
          final Size size = Size(constraints.maxWidth, constraints.maxHeight);
          final Size visibleSize = Size(size.width * 3, size.height * 2);
          final Rect visibleRect = Rect.fromLTWH(
            -(visibleSize.width - size.width) / 2,
            -(visibleSize.height - size.height) / 2,
            visibleSize.width,
            visibleSize.height,
          );

          return GestureTransformable(
            reset: _reset,
            onResetEnd: () {
              setState(() {
                _reset = false;
              });
            },
            child: CustomPaint(
              painter: HeartsPainter(),
            ),
            boundaryRect: visibleRect,
            // Center the board in the middle of the screen. It's drawn centered
            // at the origin, which is the top left corner of the
            // GestureTransformable.
            initialTranslation: Offset(size.width / 2, size.height / 2),
            onTapUp: _onTapUp,
            size: size,
          );
        },
      ),
      floatingActionButton: _board.selected == null ? resetButton : editButton,
    );
  }

  Widget get instructionDialog {
    return AlertDialog(
      title: const Text('2D Transformations'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: const <Widget>[
          Text('Tap to edit hex tiles, and use gestures to move around the scene:\n'),
          Text('- Drag to pan.'),
          Text('- Pinch to zoom.'),
          Text('- Rotate with two fingers.'),
          Text('\nYou can always press the home button to return to the starting orientation!'),
        ],
      ),
      actions: <Widget>[
        FlatButton(
          child: const Text('OK'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  FloatingActionButton get resetButton {
    return FloatingActionButton(
      onPressed: () {
        setState(() {
          _reset = true;
        });
      },
      tooltip: 'Reset Transform',
      backgroundColor: Theme.of(context).primaryColor,
      child: const Icon(Icons.home),
    );
  }

  FloatingActionButton get editButton {
    return FloatingActionButton(
      onPressed: () {
        if (_board.selected == null) {
          return;
        }
        showModalBottomSheet<Widget>(context: context, builder: (BuildContext context) {
          return Container(
            width: double.infinity,
            height: 150,
            padding: const EdgeInsets.all(12.0),
            child: EditBoardPoint(
              boardPoint: _board.selected,
              onColorSelection: (Color color) {
                setState(() {
                  _board = _board.copyWithBoardPointColor(_board.selected, color);
                  Navigator.pop(context);
                });
              },
            ),
          );
        });
      },
      tooltip: 'Edit Tile',
      child: const Icon(Icons.edit),
    );
  }

  void _onTapUp(TapUpDetails details) {
    final Offset scenePoint = details.globalPosition;
    final BoardPoint boardPoint = _board.pointToBoardPoint(scenePoint);
    setState(() {
      _board = _board.copyWithSelected(boardPoint);
    });
  }
}

// CustomPainter is what is passed to CustomPaint and actually draws the scene
// when its `paint` method is called.
class BoardPainter extends CustomPainter {
  const BoardPainter({
    this.board,
  });

  final Board board;

  @override
  void paint(Canvas canvas, Size size) {
    void drawBoardPoint(BoardPoint boardPoint) {
      final Color color = boardPoint.color.withOpacity(
        board.selected == boardPoint ? 0.2 : 1.0,
      );
      final Vertices vertices = board.getVerticesForBoardPoint(boardPoint, color);
      canvas.drawVertices(vertices, BlendMode.color, Paint());
    }

    board.forEach(drawBoardPoint);
  }

  // We should repaint whenever the board changes, such as board.selected.
  @override
  bool shouldRepaint(BoardPainter oldDelegate) {
    return oldDelegate.board != board;
  }
}

class HeartsPainter extends CustomPainter {

  final Random rand = Random(100);
  final List<Color> colors = <Color>[
    Colors.red,
    Colors.blue,
    Colors.yellow,
    Colors.green,
    Colors.white,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    print('Hearts Painting..');
    for (int i = 0; i < 300; i++) {
      _drawHeart(canvas,
          Offset(rand.nextDouble() * size.width, rand.nextDouble() * size.height),
          colors[rand.nextInt(colors.length)].withOpacity(0.4));
    }
  }

  void _drawHeart(Canvas canvas, Offset offset, Color color) {
    final Path path = Path();
    const double width = 40;
    const double height = 40;

    // Starting point
    path.moveTo(offset.dx + width / 2, offset.dy + height / 5);

    // Upper left path
    path.cubicTo(offset.dx + 5 * width / 14, offset.dy + 0,
        offset.dx + 0, offset.dy + height / 15,
        offset.dx + width / 28, offset.dy + 2 * height / 5);

    // Lower left path
    path.cubicTo(offset.dx + width / 14, offset.dy + 2 * height / 3,
        offset.dx + 3 * width / 7, offset.dy + 5 * height / 6,
        offset.dx + width / 2, offset.dy + height);

    // Lower right path
    path.cubicTo(offset.dx + 4 * width / 7, offset.dy + 5 * height / 6,
        offset.dx + 13 * width / 14, offset.dy + 2 * height / 3,
        offset.dx + 27 * width / 28, offset.dy + 2 * height / 5);

    // Upper right path
    path.cubicTo(offset.dx + width, offset.dy + height / 15,
        offset.dx + 9 * width / 14, offset.dy + 0,
        offset.dx + width / 2, offset.dy + height / 5);

    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color.withOpacity(0.4));
  }

  @override
  bool shouldRepaint(HeartsPainter oldDelegate) => false;
}
