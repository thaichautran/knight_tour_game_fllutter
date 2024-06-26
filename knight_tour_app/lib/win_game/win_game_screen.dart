// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:basic/player_progress/persistence/memory_player_progress_persistence.dart';
import 'package:basic/player_progress/player_progress.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../game_internals/score.dart';
import '../style/my_button.dart';
import '../style/palette.dart';
import '../style/responsive_screen.dart';

class WinGameScreen extends StatelessWidget {
  final Score score;

  const WinGameScreen({
    super.key,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final playerProgress = context.read<PlayerProgress>();
    final reversedHistory = playerProgress.history.reversed.toList();
    const gap = SizedBox(height: 10);

    return Scaffold(
      backgroundColor: palette.backgroundPlaySession,
      body: ResponsiveScreen(
        squarishMainArea: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            gap,
            const Center(
              child: Text(
                'Achievements!',
                style: TextStyle(fontSize: 40, fontFamily: 'Permanent Marker'),
              ),
            ),
            gap,
            const SizedBox(height: 10),
            Container(
              height: MediaQuery.of(context).size.height * 0.7,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: reversedHistory.length,
                itemBuilder: (context, index) {
                  final move = reversedHistory[index];
                  return Container(
                    padding: EdgeInsets.only(top: 10, bottom: 10),
                    child: Text(
                      '${index + 1}) $move',
                      style: index == 0
                          ? TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                          : TextStyle(fontSize: 18),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        rectangularMenuArea: MyButton(
          onPressed: () {
            GoRouter.of(context).go('/play');
          },
          child: const Text('Continue'),
        ),
      ),
    );
  }
}
