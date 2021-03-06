import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/base/data/word_result.dart';
import 'package:lets_play_cities/remote/models.dart';

/// Base class for all messages received from server
abstract class ServerMessage extends Equatable {
  const ServerMessage();

  @override
  List<Object?> get props => [];
}

/// Indicates that client was connected to server
class ConnectedMessage extends ServerMessage {}

/// Indicates that connection between client and server has stopped.
class DisconnectedMessage extends ServerMessage {}

/// First message after successful connection.
class LoggedInMessage extends ServerMessage {
  /// Contains latest actual version of client application
  final int newerBuild;

  const LoggedInMessage({required this.newerBuild});

  @override
  List<Object> get props => [newerBuild];
}

/// First message if user was forbidden.
class BannedMessage extends ServerMessage {
  /// Ban reason
  final String? banReason;

  const BannedMessage({this.banReason});

  @override
  List<Object?> get props => [banReason];
}

/// Indicates that the battle has started
class JoinMessage extends ServerMessage {
  /// `true` if opponent wants to receive messages from user.
  final bool canReceiveMessages;

  /// `true` if you should make first move in the game.
  final bool youStarter;

  /// Opponent account info
  final ProfileInfo opponent;

  const JoinMessage({
    required this.canReceiveMessages,
    required this.youStarter,
    required this.opponent,
  });

  @override
  List<Object> get props => [canReceiveMessages, youStarter, opponent];
}

/// Indicates an word validation result or input work from another opponents
class WordMessage extends ServerMessage {
  /// Word type (validation result or incoming word)
  final WordResult result;

  /// The word
  final String word;

  /// Owner ID
  final int ownerId;

  const WordMessage({
    required this.result,
    required this.word,
    required this.ownerId,
  });

  @override
  List<Object> get props => [result, word, ownerId];
}

/// Describes message received from another user
class ChatMessage extends ServerMessage {
  final String message;
  final int ownerId;

  const ChatMessage({
    required this.message,
    required this.ownerId,
  });

  @override
  List<Object> get props => [message, ownerId];
}

/// Indicates that move time has gone
class TimeoutMessage extends ServerMessage {}

/// Friend mod request result types
enum InviteResultType {
  /// Opponents now playing with another user
  busy,

  /// Opponent declines the request
  denied,

  /// User is not found or unreachable
  noUser,

  /// Opponent is not friend to sender
  notFriend,
}

/// Response from users invitation request
class InvitationResponseMessage extends ServerMessage {
  /// Target opponent login (may be `null`)
  final String? login;

  /// Target opponent ID (may be `null`)
  final int? oppId;

  /// Request type
  final InviteResultType result;

  const InvitationResponseMessage({
    required this.login,
    required this.oppId,
    required this.result,
  });

  @override
  List<Object?> get props => [login, oppId, result];
}
