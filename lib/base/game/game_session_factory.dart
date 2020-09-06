import 'package:flutter/material.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/users.dart';

import '../game_session.dart';
import 'game_mode.dart';
import 'handlers.dart';
import 'management.dart';

class GameSessionFactory {
  static GameSession createForGameMode({
    @required GameMode mode,
    @required ExclusionsService exclusions,
    @required DictionaryService dictionary,
    @required OnUserInputAccepted onUserInputAccepted,
    @required int timeLimit,
  }) {
    final usersList = UsersList.forGameMode(mode, dictionary);

    final localGameProcessorsStack = [
      TrustedEventsInterceptor(),
      FirstLetterChecker(),
      ExclusionsChecker(exclusions),
      DatabaseChecker(dictionary),
      LocalEndpoint(dictionary, () => onUserInputAccepted()),
    ];

    return GameSession(
        usersList: usersList,
        eventChannel: ProcessingEventChannel(localGameProcessorsStack),
        timeLimit: timeLimit);
  }
}