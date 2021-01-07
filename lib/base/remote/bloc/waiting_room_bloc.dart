import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:pedantic/pedantic.dart';
import 'package:equatable/equatable.dart';

import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/remote/account.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/client/remote_game_client.dart';

part 'waiting_room_event.dart';

part 'waiting_room_state.dart';

/// BLoC used to create game connection
class WaitingRoomBloc extends Bloc<WaitingRoomEvent, WaitingRoomState> {
  final RemoteGameClient _gameClient;
  final Credential _ownerCredentials;

  WaitingRoomBloc(this._gameClient, this._ownerCredentials)
      : assert(_gameClient != null),
        assert(_ownerCredentials != null),
        super(WaitingRoomInitial());

  @override
  Future<Function> close() {
    return _gameClient.disconnect().whenComplete(() => super.close());
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    if (error is ConnectionException) {
      add(CancelEvent());
      add(OnConnectionFailedEvent());
    } else {
      super.onError(error, stackTrace);
    }
  }

  @override
  Stream<WaitingRoomState> mapEventToState(WaitingRoomEvent event) async* {
    if (event is ConnectEvent) {
      yield* _startConnection();
    } else if (event is CancelEvent) {
      yield* _stopConnection();
    } else if (event is OnConnectionFailedEvent) {
      yield WaitingRoomConnectionError();
    } else if (event is PlayEvent) {
      yield* _play(event.opponent);
    } else if (event is StartGameEvent) {
      yield StartGameState(event.config);
      yield WaitingRoomInitial();
    }
  }

  Stream<WaitingRoomState> _startConnection() async* {
    yield WaitingRoomConnectingState(ConnectionStage.awaitingConnection);
    await _gameClient.connect();

    yield WaitingRoomConnectingState(ConnectionStage.authorization);
    try {
      await _gameClient.logIn(_ownerCredentials);
    } on AuthorizationException catch (e) {
      yield* _stopConnection();
      yield WaitingRoomAuthorizationFailed(e.description);
      return;
    }
    yield WaitingRoomConnectingState(ConnectionStage.done);

    add(PlayEvent(null));
  }

  Stream<WaitingRoomState> _stopConnection() async* {
    yield WaitingRoomInitial();
    await _gameClient.disconnect();
  }

  Stream<WaitingRoomState> _play(BaseProfileInfo opponent) async* {
    yield WaitingForOpponentsState();

    unawaited(_gameClient.play(opponent).then((GameConfig config) {
      add(StartGameEvent(config));
    }).catchError((error, stack) {
      if (state is! WaitingRoomInitial) {
        add(CancelEvent());
        add(OnConnectionFailedEvent());
      }
    }, test: (err) => err is ConnectionException));
  }
}