import 'dart:async';
import 'dart:math';

import 'package:basic/audio/audio_controller.dart';
import 'package:basic/audio/sounds.dart';
import 'package:basic/game_internals/level_state.dart';
import 'package:basic/game_internals/score.dart';
import 'package:basic/level_selection/levels.dart';
import 'package:basic/player_progress/persistence/memory_player_progress_persistence.dart';
import 'package:basic/player_progress/player_progress.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GameWidget extends StatefulWidget {
  final int boardSize;
  final DateTime startOfPlay;
  final VoidCallback onStopTimer;
  final VoidCallback onRestartTimer;
  const GameWidget(
      {Key? key,
      required this.boardSize,
      required this.startOfPlay,
      required this.onStopTimer,
      required this.onRestartTimer})
      : super(key: key);

  @override
  State<GameWidget> createState() => _GameWidgetState();
}

class _GameWidgetState extends State<GameWidget> {
  late int rankX;
  late int rankY;
  bool autoMove = true;
  late List<List<int>> fieldArr;
  late int curId;
  late int allowedSquares;
  late List<int> lastPos;
  late bool wantsAutoMove;
  int? coorX;
  int? coorY;
  String gameOverText = "";
  bool runningAlgorithm = false;

  @override
  void initState() {
    super.initState();

    rankX = widget.boardSize;
    rankY = widget.boardSize;
    initialize();
  }

  void initialize() {
    curId = 0;
    coorX = 0;
    coorY = 0;
    allowedSquares = 0;
    fieldArr = List.generate(rankY, (index) => List.filled(rankX, -1));
    lastPos = [0, 0];
    wantsAutoMove = true;
    gameOverText = "";

    highLightSquares();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: runningAlgorithm || curId != 1
                    ? null
                    : () => visualizeTour(coorX!, coorY!),
                child: Text('Visualize'),
                style: ElevatedButton.styleFrom(
                  disabledForegroundColor: Colors.grey.withOpacity(0.38),
                  disabledBackgroundColor:
                      Colors.grey.withOpacity(0.12), // Disable effect color
                ),
              ),
              Checkbox(
                value: autoMove,
                onChanged: (value) {
                  setState(() {
                    autoMove = value ?? false;
                  });
                },
              ),
              Text('Automove on last square'),
            ],
          ),
          SizedBox(height: 16.0),
          Expanded(
            child: Container(
              child: GridView.builder(
                itemCount: rankX * rankY,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: rankX,
                ),
                itemBuilder: (context, index) {
                  final y = index ~/ rankX;
                  final x = index % rankX;

                  return GestureDetector(
                    onTap: () {
                      onSquareClick(context, x, y);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(),
                        color: _getSquareColor(x, y),
                      ),
                      child: Center(
                        child: Text(
                          fieldArr[y][x] != 0 && fieldArr[y][x] != -1
                              ? fieldArr[y][x].toString()
                              : '',
                          style: TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 16.0),
          Text(
            gameOverText != '' ? gameOverText : '',
            style: TextStyle(fontSize: 16.0),
          ),
          Align(
            alignment: Alignment.center,
            child: InkResponse(
              onTap: () => setState(() {
                if (!runningAlgorithm) {
                  setState(() {
                    widget.onRestartTimer();
                  });
                  initialize();
                }
              }),
              child: Image.asset(
                'assets/images/restart.png',
                semanticLabel: 'Settings',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void visualizeTour(int x, int y) async {
    if (coorX != null && coorY != null) {
      initialize(); // Khởi tạo trạng thái ban đầu
      bool success = await warnsdorffTour(
          x, y, 1); // Sử dụng thuật toán Warnsdorff từ ô (0, 0)
      setState(() {
        runningAlgorithm = false;
      });
      if (!success) {
        setState(() {
          gameOverText = 'No solution found!';
          runningAlgorithm = false;
        });
      }
    }
  }

  Future<bool> warnsdorffTour(int x, int y, int moveId) async {
    setState(() {
      runningAlgorithm = true;
    });
    await Future.delayed(Duration(
        milliseconds: 300)); // Đợi 300ms để hiển thị từng bước di chuyển
    setState(() {
      fieldArr[y][x] = moveId; // Đánh dấu ô hiện tại đã được thăm
      curId = fieldArr[y][x];
    });

    if (moveId == rankX * rankY) {
      return true; // Đã thăm hết tất cả các ô trên bàn cờ
    }

    List<List<int>> nextMoves = getNextMoves(x, y);
    nextMoves.sort((a, b) => countOnwardMoves(a[0], a[1]).compareTo(
        countOnwardMoves(b[0],
            b[1]))); // Sắp xếp các bước đi tiếp theo theo số nước đi có thể từ các ô đó

    for (var nextMove in nextMoves) {
      int nextX = nextMove[0];
      int nextY = nextMove[1];
      if (fieldArr[nextY][nextX] == -1) {
        // Nếu ô tiếp theo chưa được thăm
        bool success = await warnsdorffTour(
            nextX, nextY, moveId + 1); // Đệ quy để thăm ô tiếp theo
        if (success) {
          return true; // Nếu đã thăm hết tất cả các ô trên bàn cờ, trả về true
        }
      }
    }

    // Nếu không tìm thấy giải pháp từ ô hiện tại, quay lại và thử các bước khác
    setState(() {
      fieldArr[y][x] = -1; // Hủy đánh dấu ô hiện tại
      runningAlgorithm = false;
    });
    return false;
  }

  int countOnwardMoves(int x, int y) {
    int count = 0;
    for (var d = 0; d < 8; d++) {
      List<int>? move = obtainSingleMove(x, y, d);
      if (move != null && fieldArr[move[1]][move[0]] == -1) {
        count++;
      }
    }
    return count;
  }

  List<List<int>> getNextMoves(int x, int y) {
    List<List<int>> nextMoves = [];
    for (var d = 0; d < 8; d++) {
      List<int>? move = obtainSingleMove(x, y, d);
      if (move != null) {
        nextMoves.add(move);
      }
    }
    return nextMoves;
  }

  void rereadRanks() {
    rankX = max(3, min(25, rankX));
    rankY = max(3, min(25, rankY));
  }

  void makeMoveTo(BuildContext context, int x, int y) {
    curId++;
    lastPos = [x, y];
    fieldArr[y][x] = curId;
    setState(() {
      applyMovePattern(context, x, y);
    });
  }

  void undo() {
    if (curId == 1) {
      setState(() {
        initialize();
      });
      return;
    }
    final tmpAMove = wantsAutoMove;
    wantsAutoMove = false;
    final movePattern = obtainMovePattern(lastPos[0], lastPos[1]);
    curId--;
    fieldArr[lastPos[1]][lastPos[0]] = 0;
    lastPos = [-1, -1];
    for (final move in movePattern) {
      if (fieldArr[move[1]][move[0]] == curId) {
        lastPos = move;
        break;
      }
    }
    setState(() {});
    applyMovePattern(context, lastPos[0], lastPos[1]);
    highLightSquares();
    wantsAutoMove = tmpAMove;
  }

  List<List<int>> obtainMovePattern(int x, int y) {
    final rez = <List<int>>[];
    for (var dirs = 0; dirs < 8; dirs++) {
      final trez = obtainSingleMove(x, y, dirs);
      if (trez != null) rez.add(trez);
    }
    return rez;
  }

  List<int>? obtainSingleMove(int x, int y, int d) {
    final moves = [0, 0];
    switch (d) {
      case 0:
        moves[0] = x + 1;
        moves[1] = y - 2;
        break;
      case 1:
        moves[0] = x + 2;
        moves[1] = y - 1;
        break;
      case 2:
        moves[0] = x + 2;
        moves[1] = y + 1;
        break;
      case 3:
        moves[0] = x + 1;
        moves[1] = y + 2;
        break;
      case 4:
        moves[0] = x - 1;
        moves[1] = y + 2;
        break;
      case 5:
        moves[0] = x - 2;
        moves[1] = y + 1;
        break;
      case 6:
        moves[0] = x - 2;
        moves[1] = y - 1;
        break;
      case 7:
        moves[0] = x - 1;
        moves[1] = y - 2;
        break;
    }

    if (moves[0] < 0 ||
        moves[0] >= rankX ||
        moves[1] < 0 ||
        moves[1] >= rankY) {
      return null;
    }

    return moves;
  }

  void applyMovePattern(BuildContext context, int x, int y) {
    for (var yi = 0; yi < rankY; yi++) {
      for (var xi = 0; xi < rankX; xi++) {
        if (isAllowed(xi, yi)) fieldArr[yi][xi] = 0;
      }
    }
    allowedSquares = 0;
    final movePattern = obtainMovePattern(x, y);
    for (final move in movePattern) {
      if (fieldArr[move[1]][move[0]] == 0) {
        fieldArr[move[1]][move[0]] = -1;
        allowedSquares++;
      }
    }
    if (allowedSquares == 0) {
      setState(() {
        gameOverText = gameOver(context);
      });
    } else if (allowedSquares == 1 && autoMove) {
      autoMoveFunc();
    }
  }

  void autoMoveFunc() {
    if (!wantsAutoMove) return;
    bool moveMade = false;
    for (var yi = 0; yi < rankY && !moveMade; yi++) {
      for (var xi = 0; xi < rankX && !moveMade; xi++) {
        if (fieldArr[yi][xi] == -1) {
          makeMoveTo(context, xi, yi);
          moveMade = true;
        }
      }
    }
  }

  bool isAllowed(int x, int y) {
    return fieldArr[y][x] == -1;
  }

  void highLightSquares() {
    for (var yi = 0; yi < rankY; yi++) {
      for (var xi = 0; xi < rankX; xi++) {
        if (isAllowed(xi, yi)) {
          fieldArr[yi][xi] = -1;
        }
      }
    }
  }

  Color _getSquareColor(int x, int y) {
    if (fieldArr[y][x] == -1) {
      return Colors.lightGreen[200]!;
    } else if (fieldArr[y][x] != 0 && fieldArr[y][x] == curId) {
      return Colors.lightBlue[200]!;
    } else {
      return Colors.white;
    }
  }

  void onSquareClick(BuildContext context, int x, int y) {
    setState(() {
      coorX = x;
      coorY = y;
    });
    if (!runningAlgorithm) {
      if (isAllowed(x, y)) {
        makeMoveTo(context, x, y);
        highLightSquares();
      } else if (lastPos[0] == x && lastPos[1] == y) {
        undo();
      }
    }
  }

  String formattedTime(Duration duration) {
    final buf = StringBuffer();
    if (duration.inHours > 0) {
      buf.write('${duration.inHours}');
      buf.write(':');
    }
    final minutes = duration.inMinutes % Duration.minutesPerHour;
    if (minutes > 9) {
      buf.write('$minutes');
    } else {
      buf.write('0');
      buf.write('$minutes');
    }
    buf.write(':');
    buf.write((duration.inSeconds % Duration.secondsPerMinute)
        .toString()
        .padLeft(2, '0'));
    return buf.toString();
  }

  String gameOver(BuildContext context) {
    widget.onStopTimer();
    final levelState = context.read<LevelState>();
    final playerProgress = context.read<PlayerProgress>();
    final audioController = context.read<AudioController>();
    audioController.playSfx(SfxType.congrats);
    levelState.setProgress(curId);

    String message = '';
    String saveHistory = '';
    if (curId == rankX * rankY) {
      message =
          'Congratulations! You managed to fill whole $rankX x $rankY board.';
      saveHistory = 'You managed to fill whole $rankX x $rankY board.';
    } else {
      message =
          'Game over! You managed to visit $curId squares (out of ${rankX * rankY} possible) on $rankX x $rankY board.';
      saveHistory =
          'You managed to visit $curId squares (out of ${rankX * rankY} possible) on $rankX x $rankY board.';
    }
    if (isClosedTour()) {
      message += ' Congratulations! Your tour is a closed tour.';
      saveHistory += ' Your tour is a closed tour.';
    }
    playerProgress.setHistoryReached(
        '${formattedTime(DateTime.now().difference(widget.startOfPlay))} $saveHistory');
    levelState.evaluate();
    return message;
  }

  bool isClosedTour() {
    if (curId == rankX * rankY) {
      final x = lastPos[0];
      final y = lastPos[1];
      final movePattern = obtainMovePattern(x, y);
      for (final move in movePattern) {
        if (fieldArr[move[1]][move[0]] == 1) {
          return true;
        }
      }
    }
    return false;
  }
}
