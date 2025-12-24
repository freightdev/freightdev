import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../services/message_service.dart';

// Message Service Provider
final messageServiceProvider = Provider<MessageService>((ref) => MessageService());

// Conversations List Provider
final conversationsProvider = FutureProvider.family<List<Conversation>, ConversationFilters>(
  (ref, filters) async {
    final messageService = ref.watch(messageServiceProvider);
    return await messageService.getConversations(
      search: filters.search,
      page: filters.page,
      limit: filters.limit,
    );
  },
);

// Single Conversation Provider
final conversationProvider = FutureProvider.family<Conversation, String>((ref, conversationId) async {
  final messageService = ref.watch(messageServiceProvider);
  return await messageService.getConversation(conversationId);
});

// Messages List Provider
final messagesProvider = FutureProvider.family<List<Message>, MessageFilters>((ref, filters) async {
  final messageService = ref.watch(messageServiceProvider);
  return await messageService.getMessages(
    conversationId: filters.conversationId,
    page: filters.page,
    limit: filters.limit,
  );
});

// Unread Count Provider
final unreadCountProvider = FutureProvider<int>((ref) async {
  final messageService = ref.watch(messageServiceProvider);
  return await messageService.getUnreadCount();
});

// Conversation Filters State
class ConversationFilters {
  final String? search;
  final int page;
  final int limit;

  const ConversationFilters({
    this.search,
    this.page = 1,
    this.limit = 50,
  });

  ConversationFilters copyWith({
    String? search,
    int? page,
    int? limit,
  }) {
    return ConversationFilters(
      search: search ?? this.search,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

// Message Filters State
class MessageFilters {
  final String conversationId;
  final int page;
  final int limit;

  const MessageFilters({
    required this.conversationId,
    this.page = 1,
    this.limit = 50,
  });

  MessageFilters copyWith({
    String? conversationId,
    int? page,
    int? limit,
  }) {
    return MessageFilters(
      conversationId: conversationId ?? this.conversationId,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

// Selected Conversation State
final selectedConversationProvider = StateProvider<String?>((ref) => null);
