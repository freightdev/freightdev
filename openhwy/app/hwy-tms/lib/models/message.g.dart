// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      senderName: json['sender_name'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['is_read'] as bool? ?? false,
    );

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'id': instance.id,
      'conversation_id': instance.conversationId,
      'sender_id': instance.senderId,
      'sender_name': instance.senderName,
      'content': instance.content,
      'timestamp': instance.timestamp.toIso8601String(),
      'is_read': instance.isRead,
    };

ConversationParticipant _$ConversationParticipantFromJson(
        Map<String, dynamic> json) =>
    ConversationParticipant(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );

Map<String, dynamic> _$ConversationParticipantToJson(
        ConversationParticipant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'status': instance.status,
      'avatar_url': instance.avatarUrl,
    };

Conversation _$ConversationFromJson(Map<String, dynamic> json) => Conversation(
      id: json['id'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$ConversationTypeEnumMap, json['type']),
      participants: (json['participants'] as List<dynamic>)
          .map((e) =>
              ConversationParticipant.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastMessage: json['last_message'] == null
          ? null
          : Message.fromJson(json['last_message'] as Map<String, dynamic>),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$ConversationToJson(Conversation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$ConversationTypeEnumMap[instance.type]!,
      'participants': instance.participants,
      'last_message': instance.lastMessage,
      'unread_count': instance.unreadCount,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$ConversationTypeEnumMap = {
  ConversationType.direct: 'direct',
  ConversationType.group: 'group',
};
