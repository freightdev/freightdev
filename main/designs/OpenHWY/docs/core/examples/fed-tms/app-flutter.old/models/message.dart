import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'message.g.dart';

enum ConversationType {
  @JsonValue('direct')
  direct,
  @JsonValue('group')
  group,
}

@JsonSerializable()
class Message extends Equatable {
  final String id;
  @JsonKey(name: 'conversation_id')
  final String conversationId;
  @JsonKey(name: 'sender_id')
  final String senderId;
  @JsonKey(name: 'sender_name')
  final String senderName;
  final String content;
  final DateTime timestamp;
  @JsonKey(name: 'is_read')
  final bool isRead;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        content,
        timestamp,
      ];

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? content,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

@JsonSerializable()
class ConversationParticipant extends Equatable {
  final String id;
  final String name;
  final String status;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  const ConversationParticipant({
    required this.id,
    required this.name,
    required this.status,
    this.avatarUrl,
  });

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) =>
      _$ConversationParticipantFromJson(json);
  Map<String, dynamic> toJson() => _$ConversationParticipantToJson(this);

  @override
  List<Object?> get props => [id, name, status];
}

@JsonSerializable()
class Conversation extends Equatable {
  final String id;
  final String name;
  final ConversationType type;
  final List<ConversationParticipant> participants;
  @JsonKey(name: 'last_message')
  final Message? lastMessage;
  @JsonKey(name: 'unread_count')
  final int unreadCount;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    required this.name,
    required this.type,
    required this.participants,
    this.lastMessage,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);
  Map<String, dynamic> toJson() => _$ConversationToJson(this);

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        participants,
        unreadCount,
      ];

  Conversation copyWith({
    String? id,
    String? name,
    ConversationType? type,
    List<ConversationParticipant>? participants,
    Message? lastMessage,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
