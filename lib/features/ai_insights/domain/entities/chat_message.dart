import 'package:equatable/equatable.dart';

enum MessageSender {
  user,
  assistant,
}

enum MessageType {
  text,
  textWithChart,
  textWithTable,
  textWithActions,
  error,
}

enum MessageStatus {
  sending,
  sent,
  error,
}

class ChatMessage extends Equatable {
  final String id;
  final MessageSender sender;
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata; // For storing query results, etc.
  final MessageType type;
  final MessageStatus status;
  final List<String>? followUpSuggestions;

  const ChatMessage({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
    this.metadata,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    this.followUpSuggestions,
  });

  @override
  List<Object?> get props => [id, sender, content, timestamp, metadata, type, status, followUpSuggestions];

  ChatMessage copyWith({
    String? id,
    MessageSender? sender,
    String? content,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    MessageType? type,
    MessageStatus? status,
    List<String>? followUpSuggestions,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      type: type ?? this.type,
      status: status ?? this.status,
      followUpSuggestions: followUpSuggestions ?? this.followUpSuggestions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'type': type.name,
      'status': status.name,
      'followUpSuggestions': followUpSuggestions,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      sender: MessageSender.values.firstWhere(
        (e) => e.name == json['sender'],
      ),
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
      type: json['type'] != null
          ? MessageType.values.firstWhere(
              (e) => e.name == json['type'],
              orElse: () => MessageType.text,
            )
          : MessageType.text,
      status: json['status'] != null
          ? MessageStatus.values.firstWhere(
              (e) => e.name == json['status'],
              orElse: () => MessageStatus.sent,
            )
          : MessageStatus.sent,
      followUpSuggestions: json['followUpSuggestions'] != null
          ? List<String>.from(json['followUpSuggestions'] as List)
          : null,
    );
  }
}
