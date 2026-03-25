import 'package:flutterapp/model/message.dart';

class ChatThreadState {
  final int conversationId;
  final List<Message> messages;
  final bool initialLoaded;
  final bool loadingInitial;
  final bool loadingOlder;
  final bool hasMoreOlder;
  final String? errorMessage;

  const ChatThreadState({
    required this.conversationId,
    required this.messages,
    required this.initialLoaded,
    required this.loadingInitial,
    required this.loadingOlder,
    required this.hasMoreOlder,
    required this.errorMessage,
  });

  bool get isLoadingInitial => loadingInitial && messages.isEmpty;

  bool get isEmpty => initialLoaded && messages.isEmpty && !loadingInitial;

  bool get canLoadOlder =>
      initialLoaded && hasMoreOlder && !loadingOlder && messages.isNotEmpty;
}