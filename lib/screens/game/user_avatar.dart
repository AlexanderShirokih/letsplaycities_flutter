import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/base/repositories/game_service_events.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Creates circular user avatar with border around it.
class UserAvatar extends StatelessWidget {
  static const _kImagePlaceholder = "assets/images/player_big.png";

  final int _userId;
  final CrossAxisAlignment alignment;
  final ImageProvider imageProvider;
  final Function onPressed;

  UserAvatar({
    @required User user,
    @required this.onPressed,
    Key key,
  })  : imageProvider = _getProviderByPictureSource(user.playerData.picture),
        alignment = _getAlignmentByPosition(user.position),
        _userId = user.id,
        super(key: key);

  @override
  Widget build(BuildContext rootContext) => StreamBuilder<Map<User, bool>>(
        stream: rootContext
            .repository<GameServiceEventsRepository>()
            .getUserSwitches(),
        builder: (context, snapshot) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: alignment,
          children: [
            Container(
              width: 70.0,
              height: 70.0,
              child: FlatButton(
                onPressed: onPressed,
                color: Colors.white,
                padding: EdgeInsets.zero,
                child: _buildImage(
                  imageProvider,
                  const AssetImage(_kImagePlaceholder),
                ),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: snapshot.hasData &&
                            snapshot.data.entries
                                .any((u) => u.value && u.key.id == _userId)
                        ? Theme.of(context).primaryColorDark
                        : Colors.white,
                    width: 5.0,
                  ),
                ),
              ),
            ),
            SizedBox(height: 4.0),
            Text(
              snapshot.hasData
                  ? snapshot.data.keys
                      .singleWhere((user) => user.id == _userId)
                      .info
                  : "--",
            ),
          ],
        ),
      );

  static ImageProvider _getProviderByPictureSource(PictureSource source) {
    if (source is AssetPictureSource) {
      return AssetImage(source.assetName);
    }
    if (source is NetworkPictureSource) {
      return NetworkImage(source.pictureURL);
    }
    // PlaceholderImageSource
    return AssetImage(_kImagePlaceholder);
  }

  static CrossAxisAlignment _getAlignmentByPosition(Position position) =>
      (position == Position.LEFT)
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end;
}

Widget _buildImage(ImageProvider target, ImageProvider placeholder) =>
    (target is AssetImage)
        ? Image(image: target)
        : FadeInImage(image: target, placeholder: placeholder);
