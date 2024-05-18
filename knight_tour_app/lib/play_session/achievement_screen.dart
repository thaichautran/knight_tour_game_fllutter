// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:basic/player_progress/persistence/local_storage_player_progress_persistence.dart';
import 'package:basic/player_progress/persistence/memory_player_progress_persistence.dart';
import 'package:basic/player_progress/persistence/player_progress_persistence.dart';
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

class AchievementScreen extends StatefulWidget {
  const AchievementScreen({
    super.key,
  });
  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
  List<String> reversedHistory = [];

  @override
  void initState() {
    super.initState();
    final store = LocalStoragePlayerProgressPersistence();

    store.getHistory().then((history) {
      setState(() {
        reversedHistory = history.reversed.toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
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
                      style: TextStyle(fontSize: 20),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        rectangularMenuArea: MyButton(
          onPressed: () {
            GoRouter.of(context).pop();
          },
          child: const Text('Back'),
        ),
      ),
    );
  }
}
