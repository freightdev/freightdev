import '../models/message.dart';
import 'api_client.dart';

class MessageService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Conversation>> getConversations({
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final response = await _apiClient.get('/conversations', queryParameters: queryParams);
    final data = response.data['data'] as List;
    return data.map((json) => Conversation.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Conversation> getConversation(String id) async {
    final response = await _apiClient.get('/conversations/$id');
    return Conversation.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Conversation> createConversation({
    required String name,
    required ConversationType type,
    required List<String> participantIds,
  }) async {
    final response = await _apiClient.post(
      '/conversations',
      data: {
        'name': name,
        'type': type.name,
        'participant_ids': participantIds,
      },
    );
    return Conversation.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Message>> getMessages({
    required String conversationId,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    final response = await _apiClient.get(
      '/conversations/$conversationId/messages',
      queryParameters: queryParams,
    );
    final data = response.data['data'] as List;
    return data.map((json) => Message.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Message> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final response = await _apiClient.post(
      '/conversations/$conversationId/messages',
      data: {'content': content},
    );
    return Message.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> markAsRead(String conversationId, String messageId) async {
    await _apiClient.patch(
      '/conversations/$conversationId/messages/$messageId/read',
    );
  }

  Future<void> markConversationAsRead(String conversationId) async {
    await _apiClient.patch('/conversations/$conversationId/read');
  }

  Future<int> getUnreadCount() async {
    final response = await _apiClient.get('/conversations/unread-count');
    return response.data['count'] as int;
  }

  Future<void> deleteMessage(String conversationId, String messageId) async {
    await _apiClient.delete('/conversations/$conversationId/messages/$messageId');
  }

  Future<void> deleteConversation(String conversationId) async {
    await _apiClient.delete('/conversations/$conversationId');
  }
}
