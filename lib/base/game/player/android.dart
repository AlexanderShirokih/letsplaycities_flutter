import 'dart:math';

import 'package:lets_play_cities/base/auth.dart';
import 'package:lets_play_cities/base/data.dart';

import 'user.dart';
import 'surrender_exception.dart';
import '../game_facade.dart';

/// Represents logic of Android player.
/// [PlayerData] model class that contains info about user.
/// [PictureSource] represents android's picture.
class Android extends User {
  static const _kAndroidAvatarPath = "assets/images/android_big.png";
  static const _kDefaultAndroidUserId = -2;

  final GameFacade _gameFacade;

  /// Count of moves before Android surrenders
  int _estimatedMoves;

  Android(
    this._gameFacade,
    String androidName,
  )   : _estimatedMoves = _calculateEstimatedMoves(_gameFacade.difficultyIndex),
        super(
          PlayerData(
            name: androidName,
            canReceiveMessages: false,
            picture: const AssetPictureSource(_kAndroidAvatarPath),
          ),
          ClientAccountInfo.basic(androidName, _kDefaultAndroidUserId),
        );

  @override
  Future<City> onCreateWord(String firstChar) async {
    await Future.delayed(Duration(milliseconds: 1500));

    final word = await _gameFacade.getRandomWord(firstChar);

    if (_estimatedMoves-- <= 0 || word.isEmpty)
      throw SurrenderException(this, false);

    return City(word, this);
  }

  static int _calculateEstimatedMoves(int difficultyIndex) {
    var estimatedMoves = (20.0 + difficultyIndex.toDouble() / 3.0 * 70).toInt();
    return (estimatedMoves * (1.0 + Random().nextDouble() * 0.35)).toInt();
  }
}