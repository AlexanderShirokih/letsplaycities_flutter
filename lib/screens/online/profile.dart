import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import 'package:lets_play_cities/l18n/localization_service.dart';
import 'package:lets_play_cities/remote/account_manager.dart';
import 'package:lets_play_cities/remote/api_repository.dart';
import 'package:lets_play_cities/remote/model/profile_info.dart';
import 'package:lets_play_cities/screens/common/utils.dart';
import 'package:lets_play_cities/screens/online/banlist.dart';
import 'package:lets_play_cities/screens/online/common_online_widgets.dart';
import 'package:lets_play_cities/screens/online/friends.dart';
import 'package:lets_play_cities/screens/online/history.dart';
import 'package:lets_play_cities/screens/online/network_avatar_building_mixin.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

import 'avatars/avatar_chooser_dialog.dart';

/// Shows user profile
class OnlineProfileView extends StatefulWidget {
  /// Profile owner id. If `null` than current authorized user will be used
  final int targetId;

  const OnlineProfileView({this.targetId, Key key}) : super(key: key);

  @override
  _OnlineProfileViewState createState() => _OnlineProfileViewState();

  /// Creates navigation route for [OnlineProfileView] wrapped in [Scaffold].
  /// [context] must contain [ApiRepository] and [AccountManager] injected
  /// with [RepositoryProvider] in the widget tree.
  static Route createRoute(BuildContext context, {int targetId}) =>
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            title: Text(
              readWithLocalization(
                  context, (l10n) => l10n.online['profile_tab']),
            ),
          ),
          body: MultiRepositoryProvider(
            providers: [
              RepositoryProvider.value(
                value: context.watch<ApiRepository>(),
              ),
              RepositoryProvider.value(
                value: context.watch<AccountManager>(),
              ),
            ],
            child: OnlineProfileView(
              targetId: targetId,
            ),
          ),
        ),
      );
}

class _OnlineProfileViewState extends State<OnlineProfileView>
    with NetworkAvatarBuildingMixin {
  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  bool _shouldUpdate = false;

  @override
  Widget build(BuildContext context) => withData<Widget, ApiRepository>(
        context.watch<ApiRepository>(),
        (repo) => RefreshIndicator(
          onRefresh: () async => setState(() {
            _shouldUpdate = true;
          }),
          child: Stack(
            children: [
              Positioned.fill(
                child: FutureBuilder<ProfileInfo>(
                  future: repo.getProfileInfo(widget.targetId, _shouldUpdate),
                  builder: (context, snap) {
                    if (snap.hasData) {
                      _shouldUpdate = false;
                      return _buildProfileView(
                          snap.data.friendshipStatus == FriendshipStatus.owner,
                          context,
                          snap.data);
                    } else if (snap.hasError) {
                      return showError(context, snap.error.toString());
                    } else {
                      return showLoadingWidget(context);
                    }
                  },
                ),
              ),
              if (_isOwner())
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0, right: 24.0),
                    child: FloatingActionButton.extended(
                      onPressed: () => context
                          .read<AccountManager>()
                          .signOut()
                          .then((_) => Navigator.of(context).pop()),
                      icon: FaIcon(FontAwesomeIcons.signOutAlt),
                      label: buildWithLocalization(
                        context,
                        (l10n) => Text(l10n.online['sign_out']),
                      ),
                    ),
                  ),
                )
            ],
          ),
        ),
      );

  Widget _buildProfileView(
          bool isOwner, BuildContext context, ProfileInfo data) =>
      buildWithLocalization(
        context,
        (l10n) => ListView(
          children: [
            ..._buildTopBlock(isOwner, data, context, l10n),
            ..._buildIdBlock(data, context),
            ..._buildActionsBlock(isOwner, data, context, l10n),
            ..._buildNavigationBlock(isOwner, data, context, l10n),
            ..._buildRelatedHistoryBlock(isOwner, data, context, l10n),
          ],
        ),
      );

  Iterable<Widget> _buildTopBlock(bool isOwner, ProfileInfo data,
      BuildContext context, LocalizationService l10n) sync* {
    yield Container(
      padding: EdgeInsets.all(28.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            child: InkWell(
              onTap: isOwner
                  ? () => showDialog(
                        context: context,
                        builder: (_) => RepositoryProvider.value(
                          value: context.watch<AccountManager>(),
                          child: AvatarChooserDialog(l10n),
                        ),
                      )
                  : null,
              child:
                  buildAvatar(data.userId, data.login, data.pictureUrl, 60.0),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 28.0, top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.login,
                  style: Theme.of(context).textTheme.headline6,
                  overflow: TextOverflow.fade,
                ),
                const SizedBox(height: 12.0),
                _showOnlineStatus(isOwner, l10n, data),
                ..._showRole(l10n, data),
              ],
            ),
          ),
        ],
      ),
    );
    yield const Divider(height: 18.0, thickness: 1.0);
  }

  Iterable<Widget> _buildActionsBlock(bool isOwner, ProfileInfo data,
      BuildContext context, LocalizationService l10n) sync* {
    if (isOwner) return;
    yield Container(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _getFriendshipButton(data, context, l10n),
          _getFriendRequestButton(data, context, l10n),
        ],
      ),
    );
    yield const Divider(height: 18.0, thickness: 1.0);
  }

  Iterable<Widget> _buildIdBlock(ProfileInfo data, BuildContext context) sync* {
    yield Container(
      alignment: Alignment.center,
      child: Text(
        'ID ${data.userId}',
        style: Theme.of(context).textTheme.caption.copyWith(fontSize: 16.0),
      ),
    );
    yield const Divider(height: 18.0, thickness: 1.0);
  }

  Iterable<Widget> _buildNavigationBlock(bool isOwner, ProfileInfo data,
      BuildContext context, LocalizationService l10n) sync* {
    if (!isOwner) return;
    yield _buildNavigationButton(FaIcon(FontAwesomeIcons.userFriends),
        l10n.online['friends_tab'], () => OnlineFriendsScreen());
    yield _buildNavigationButton(FaIcon(FontAwesomeIcons.history),
        l10n.online['history_tab'], () => OnlineHistoryScreen());
    yield _buildNavigationButton(FaIcon(FontAwesomeIcons.userSlash),
        l10n.online['blacklist_tab'], () => OnlineBanlistScreen());
    yield const Divider(height: 18.0, thickness: 1.0);
  }

  Widget _buildNavigationButton(
          Widget icon, String label, Widget Function() destinationScreen) =>
      ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => MultiRepositoryProvider(
              providers: [
                RepositoryProvider.value(
                  value: context.watch<ApiRepository>(),
                ),
                RepositoryProvider.value(
                  value: context.watch<AccountManager>(),
                ),
              ],
              child: Scaffold(
                appBar: AppBar(
                  title: Text(label),
                ),
                body: destinationScreen(),
              ),
            ),
          ),
        ),
        leading: icon,
        title: Text(label),
      );

  Widget _createButton(String label, void Function() onPressed) => RaisedButton(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
        shape: _createRoundedBorder(),
        onPressed: onPressed,
        color: Theme.of(context).primaryColor,
        child: Text(label),
      );

  Widget _getFriendshipButton(
      ProfileInfo data, BuildContext context, LocalizationService l10n) {
    switch (data.friendshipStatus) {
      case FriendshipStatus.notFriends:
        return _createButton(l10n.online['add_to_friend'], () {
          //TODO: Add to friends
        });
      case FriendshipStatus.friends:
        return _createButton(l10n.online['remove_from_friends'], () {
          //TODO: Remove from friends
        });

      case FriendshipStatus.inputRequest:
        return _createButton(l10n.online['cancel_friendship_request'], () {
          //TODO: Cancel request
        });
      case FriendshipStatus.outputRequest:
        return _AcceptOrDeclineButton(l10n);
      default:
        throw ('Can\'t show friendship button for itself');
    }
  }

  Widget _getFriendRequestButton(
          ProfileInfo data, BuildContext context, LocalizationService l10n) =>
      _createButton(
        l10n.online['invite'],
        () {
          // TODO: Handle invite button
        },
      );

  ShapeBorder _createRoundedBorder() => RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0), side: BorderSide.none);

  Iterable<Widget> _showRole(LocalizationService l10n, ProfileInfo data) sync* {
    switch (data.role) {
      case Role.banned:
        yield const SizedBox(height: 10.0);
        yield Text(l10n.online['banned']);
        break;
      case Role.admin:
        yield const SizedBox(height: 10.0);
        yield Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.userLock),
            const SizedBox(width: 8.0),
            Text(l10n.online['admin']),
          ],
        );
        break;
      case Role.regular:
        break;
    }
  }

  Widget _showOnlineStatus(
      bool isOwner, LocalizationService l10n, ProfileInfo data) {
    bool _isOnline(ProfileInfo info) =>
        DateTime.now().difference(info.lastVisitDate) < Duration(minutes: 10) ||
        isOwner;

    return (_isOnline(data))
        ? Row(
            children: [
              FaIcon(
                FontAwesomeIcons.solidCircle,
                color: Colors.green,
                size: 12.0,
              ),
              const SizedBox(width: 6.0),
              Text(l10n.online['title']),
            ],
          )
        : Text(
            _getDate(l10n, data.lastVisitDate),
            style: Theme.of(context)
                .textTheme
                .bodyText2
                .copyWith(fontStyle: FontStyle.italic),
          );
  }

  Iterable<Widget> _buildRelatedHistoryBlock(bool isOwner, ProfileInfo data,
      BuildContext context, LocalizationService l10n) sync* {
    if (isOwner) return;
    yield Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        l10n.online['battle_history'],
        style: Theme.of(context).textTheme.headline6,
      ),
    );
    yield OnlineHistoryScreen(targetId: widget.targetId, embedded: true);
    yield const Divider(height: 18.0, thickness: 1.0);
  }

  String _getDate(LocalizationService l10n, DateTime date) {
    final baseFormat = l10n.online['last_online'].toString();
    final now = DateTime.now();

    switch (now.day - date.day) {
      case 0:
        return baseFormat.format([_timeFormat.format(date)]);
      case 1:
        return baseFormat.format([
          l10n.online['yesterday'].toString().format([_timeFormat.format(date)])
        ]);
      default:
        return baseFormat.format([_dateFormat.format(date)]);
    }
  }

  bool _isOwner() =>
      widget.targetId == null ||
      widget.targetId ==
          context
              .read<AccountManager>()
              .getLastSignedInAccount()
              .credential
              .userId;
}

class _AcceptOrDeclineButton extends StatefulWidget {
  final LocalizationService l10n;

  const _AcceptOrDeclineButton(this.l10n);

  @override
  __AcceptOrDeclineButtonState createState() =>
      __AcceptOrDeclineButtonState(l10n);
}

class __AcceptOrDeclineButtonState extends State<_AcceptOrDeclineButton> {
  final List<String> _values;

  int _selected = 0;

  __AcceptOrDeclineButtonState(LocalizationService l10n)
      : _values = [
          l10n.online['accept_friendship_request'],
          l10n.online['decline_friendship_request']
        ];

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.only(left: 10.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          color: Theme.of(context).primaryColor,
        ),
        child: DropdownButton(
            value: _selected,
            elevation: 5,
            items: [0, 1]
                .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      _values[e],
                      style: Theme.of(context).textTheme.bodyText1,
                    )))
                .toList(),
            onChanged: (newValue) => setState(() {
                  _selected = newValue;
                  // TODO: Accept or decline
                })),
      );
}