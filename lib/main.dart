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
                                bottom:
                                    constraints.biggest.shortestSide *
                                        (piece.place.y + 2) /
                                        21 +
                                    (constraints.maxHeight -
                                                constraints
                                                    .biggest
                                                    .shortestSide)
                                            .abs() /
                                        2,
                                left:
                                    constraints.biggest.shortestSide *
                                        (piece.place.x + 4) /
                                        21 +
                                    (constraints.maxWidth -
                                                constraints
                                                    .biggest
                                                    .shortestSide)
                                            .abs() /
                                        2,
                                child: Container(
                                  width: cellSize,
                                  height: cellSize,
                                  decoration: BoxDecoration(
                                    color: piece.piece.white
                                        ? Colors.white
                                        : Colors.black,
                                    border: Border.all(),
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
  ({String piece, bool white}) piece,
  Set<({int x, int y})> places,
});
/*
enum Piece {
  knife._(), whip._(),
  barricade._(),
  ballista._(), cannon._(),
  monarch._(), warlord._(),
  civilian._(), guard._(), hero._(),
  dragon._(),
  worker._(),
  mage._(), sage._(),
  lance._(), gryphon._();
  const Piece._();
  static const Map<String, Piece> _pieces = {
    'K': knife,
    'k': whip,
    'B': barricade,
    'A': ballista,
    'a': cannon,

  };
  factory Piece(String str) {
    return _pieces[str]!;
  }
}*/
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
    Set<({int x, int y})> positions = parts
        .skip(1)
        .map(algebraicToPair)
        .toSet();
    pieces.add((piece: (piece: piece, white: white), places: positions));
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
