import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:lets_play_cities/remote/auth.dart';

part 'user_actions_event.dart';

part 'user_actions_state.dart';

/// BLoC for managing user actions like friends management
class UserActionsBloc extends Bloc<UserActionsEvent, UserActionsState> {
  final ApiRepository _apiRepository;

  UserActionsBloc(this._apiRepository) : super(UserActionsInitial());

  @override
  Stream<UserActionsState> mapEventToState(UserActionsEvent event) async* {
    if (event is UserEvent) {
      if (event.undoable) {
        yield UserActionConfirmationState(event);
      } else {
        yield* _doActionsSafely(event);
      }
      return;
    }

    if (event is UserActionConfirmedEvent) {
      yield* _doActionsSafely(event.sourceEvent);
    } else {
      throw 'Bad state: event "$event" is unsupported!';
    }
  }

  Stream<UserActionsState> _doActionsSafely(UserEvent sourceEvent) {
    return _doActions(sourceEvent).transform(
        StreamTransformer<UserActionsState, UserActionsState>.fromHandlers(
      handleError: (e, s, sink) {
        sink.add(UserActionErrorState(e, s));
      },
    ));
  }

  Stream<UserActionsState> _doActions(UserEvent sourceEvent) async* {
    final target = sourceEvent.target;
    yield UserProcessingActionState();

    switch (sourceEvent.action) {
      case UserUserAction.addToFriends:
        await _apiRepository.sendNewFriendshipRequest(target);
        break;
      case UserUserAction.removeFromFriends:
      case UserUserAction.cancelRequest:
        await _apiRepository.deleteFriend(target);
        break;
      case UserUserAction.acceptRequest:
        await _apiRepository.sendFriendRequestAcceptance(target, true);
        break;
      case UserUserAction.declineRequest:
        await _apiRepository.sendFriendRequestAcceptance(target, false);
        break;
      case UserUserAction.banUser:
        await _apiRepository.addToBanlist(target);
        break;
      case UserUserAction.unbanUser:
        await _apiRepository.removeFromBanlist(target);
        break;
    }

    yield UserActionDoneState(sourceEvent);
  }
}
