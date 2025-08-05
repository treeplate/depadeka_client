import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart';

void main() {
  runApp(const MyApp());
}

const String serverURL =
    'https://treeplate.damowmow.com/depadeka_server/main.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

Future<String> sendMessage(String message) async {
  return (await post(Uri.parse(serverURL), body: message)).body;
}

class _MyHomePageState extends State<MyHomePage> {
  String value = '';
  GameState? state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 200,
              height: 50,
              child: TextField(
                onChanged: (final String value) {
                  this.value = value;
                },
              ),
            ),
            OutlinedButton(
              onPressed: () async {
                post(Uri.parse(serverURL), body: 'get-board\n$value').then((
                  body,
                ) {
                  setState(() {
                    state = parse(body.body);
                  });
                });
              },
              child: Text('send this'),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double cellSize = constraints.biggest.shortestSide / 21;
                  return Stack(
                    children: [
                      if (state != null)
                        ...state!.pieces
                            .expand(
                          (e) => e.places.map(
                            (f) => (piece: e.piece, place: f),
                          ),
                        )
                            .map((piece) {
                          return Positioned(
                            bottom: constraints.biggest.shortestSide *
                                    (piece.piece.top(piece.place.y) + 2) /
                                    21 +
                                (constraints.maxHeight -
                                            constraints.biggest.shortestSide)
                                        .abs() /
                                    2,
                            left: constraints.biggest.shortestSide *
                                    (piece.piece.left(piece.place.x) + 4) /
                                    21 +
                                (constraints.maxWidth -
                                            constraints.biggest.shortestSide)
                                        .abs() /
                                    2,
                            child: Transform.rotate(angle: pi/4 * piece.piece.orientation.index,
                              child: Container(
                                width: cellSize * piece.piece.width,
                                height: cellSize * piece.piece.height,
                                decoration: BoxDecoration(
                                  color: piece.piece.white
                                      ? Colors.white
                                      : Colors.black,
                                  border: Border.all(color:  piece.piece.white ? Colors.black : Colors.white),
                                ),
                                child: Center(child: Text(piece.piece.runtimeType.toString(), style: TextStyle(color: piece.piece.white ? Colors.black : Colors.white, fontSize: 10),),),
                              ),
                            ),
                          );
                        }),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef PiecePlaces = ({
  Piece piece,
  Set<({int x, int y})> places,
});

enum Orientation { up, upright, right, rightdown, down, downleft, left, leftup }

sealed class Piece {
  final Orientation orientation;
  final bool white;
  const Piece._(this.orientation, this.white);
  int get _upWidth => 1;
  int get _upHeight => 1;
  int get _uprightWidth => 1;
  int get _uprightHeight => 1;
  int get width {
    switch (orientation) {
      case Orientation.up:
      case Orientation.down:
        return _upWidth;
      case Orientation.downleft:
      case Orientation.upright:
        return _uprightWidth;
      case Orientation.left:
      case Orientation.right:
        return _upHeight;
      case Orientation.leftup:
      case Orientation.rightdown:
        return _uprightHeight;
    }
  }

  int get height {
    switch (orientation) {
      case Orientation.up:
      case Orientation.down:
        return _upHeight;
      case Orientation.downleft:
      case Orientation.upright:
        return _uprightHeight;
      case Orientation.left:
      case Orientation.right:
        return _upWidth;
      case Orientation.leftup:
      case Orientation.rightdown:
        return _uprightWidth;
    }
  }
  int top(int y) {
    switch(orientation) {
      case Orientation.down:
      case Orientation.downleft:
      case Orientation.left:
      case Orientation.leftup:
        return y;
      case Orientation.up:
      case Orientation.upright:
      case Orientation.right:
      case Orientation.rightdown:
        return y - height + 1;
    }
  }
  int left(int x) {
    switch(orientation) {
      case Orientation.left:
      case Orientation.leftup:
      case Orientation.up:
      case Orientation.upright:
        return x;
      case Orientation.right:
      case Orientation.rightdown:
      case Orientation.down:
      case Orientation.downleft:
        return x - width + 1;
    }
  }
  static const Map<String, Orientation> _orientations = {
    'A': Orientation.up,
    '^': Orientation.upright,
    '>': Orientation.right,
    '_': Orientation.rightdown,
    'V': Orientation.down,
    '<': Orientation.left,
  };
  factory Piece(String piece, bool white) {
    Orientation orientation;
    String pieceChar;
    if (piece.startsWith('^')) {
      orientation = Orientation.leftup;
      pieceChar = piece.substring(1);
    } else if (piece.startsWith('_')) {
      orientation = Orientation.downleft;
      pieceChar = piece.substring(1);
    } else {
      pieceChar = piece.substring(0, 1);
      orientation = _orientations[piece.substring(1)]!;
    }
    switch (pieceChar) {
      case 'K':
        return Knife._(orientation, white);
      case 'k':
        return Whip._(orientation, white);
      case 'B':
        return Barricade._(orientation, white);
      case 'A':
        return Ballista._(orientation, white);
      case 'a':
        return Cannon._(orientation, white);
      case 'M':
        return Monarch._(orientation, white);
      case 'm':
        return Warlord._(orientation, white);
      case 'C':
        return Civilian._(orientation, white);
      case 'c':
        return Guard._(orientation, white);
      case 'h':
        return Hero._(orientation, white);
      case 'D':
        return Dragon._(orientation, white);
      case 'W':
        return Worker._(orientation, white);
      case 'G':
        return Mage._(orientation, white);
      case 'g':
        return Sage._(orientation, white);
      case 'L':
        return Lance._(orientation, white);
      case 'l':
        return Gryphon._(orientation, white);
      default:
        throw FormatException('unknown piece $pieceChar');
    }
  }
}

class Knife extends Piece {
  Knife._(super.orientation, super.white) : super._();
}

class Whip extends Piece {
  Whip._(super.orientation, super.white) : super._();
}

class Barricade extends Piece {
  Barricade._(super.orientation, super.white) : super._();
  @override
  int get _upWidth => 3;
}

class Ballista extends Piece {
  Ballista._(super.orientation, super.white) : super._();
  @override
  int get _upWidth => 2;
  @override
  int get _upHeight => 2;
}

class Cannon extends Piece {
  Cannon._(super.orientation, super.white) : super._();
  @override
  int get _upWidth => 2;
  @override
  int get _upHeight => 2;
}

class Monarch extends Piece {
  Monarch._(super.orientation, super.white) : super._();
}

class Warlord extends Piece {
  Warlord._(super.orientation, super.white) : super._();
}

class Civilian extends Piece {
  Civilian._(super.orientation, super.white) : super._();
}

class Guard extends Piece {
  Guard._(super.orientation, super.white) : super._();
}

class Hero extends Piece {
  Hero._(super.orientation, super.white) : super._();
}

class Dragon extends Piece {
  Dragon._(super.orientation, super.white) : super._();
  @override
  int get _upWidth => 3;
  @override
  int get _upHeight => 3;
  @override
  int get _uprightWidth => 3;
  @override
  int get _uprightHeight => 3;
}

class Worker extends Piece {
  Worker._(super.orientation, super.white) : super._();
}

class Mage extends Piece {
  Mage._(super.orientation, super.white) : super._();
}

class Sage extends Piece {
  Sage._(super.orientation, super.white) : super._();
}

class Lance extends Piece {
  Lance._(super.orientation, super.white) : super._();
}

class Gryphon extends Piece {
  Gryphon._(super.orientation, super.white) : super._();
}

typedef GameState = ({
  int turnNumber,
  bool whiteTurn,
  List<String> moveTypes,
  Set<PiecePlaces> pieces,
});

/// Reads a file and parses it into a [GameState].
GameState parse(String file) {
  print(file);
  List<String> lines = file.split('\n');
  List<String> parts = lines.first.split(' ');
  int turnNumber = int.parse(parts.first.substring(0, parts.first.length - 1));
  bool whiteTurn = parts.first[parts.first.length - 1] == 'w';
  List<String> moveTypes = parts.last.split('');
  Set<PiecePlaces> pieces = {};
  for (String line in lines.skip(1)) {
    parts = line.split(' ');
    String piece = parts.first.substring(0, parts.first.length - 1);
    bool white = parts.first[parts.first.length - 1] == 'w';
    Set<({int x, int y})> positions =
        parts.skip(1).map(algebraicToPair).toSet();
    pieces.add((piece: Piece(piece, white), places: positions));
  }
  return (
    turnNumber: turnNumber,
    whiteTurn: whiteTurn,
    moveTypes: moveTypes,
    pieces: pieces,
  );
}

({int x, int y}) algebraicToPair(String square) {
  String letter = square[0];
  int y = int.parse(square.substring(1)) - 1;
  int x = letter.codeUnits.single - 0x61;
  return (x: x, y: y);
}
