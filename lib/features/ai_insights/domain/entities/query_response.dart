import 'package:equatable/equatable.dart';
import 'chat_message.dart';

class QueryResponse extends Equatable {
  final String content;
  final MessageType type;
  final Map<String, dynamic>? data;
  final List<String>? followUpSuggestions;

  const QueryResponse({
    required this.content,
    this.type = MessageType.text,
    this.data,
    this.followUpSuggestions,
  });

  @override
  List<Object?> get props => [content, type, data, followUpSuggestions];

  QueryResponse copyWith({
    String? content,
    MessageType? type,
    Map<String, dynamic>? data,
    List<String>? followUpSuggestions,
  }) {
    return QueryResponse(
      content: content ?? this.content,
      type: type ?? this.type,
      data: data ?? this.data,
      followUpSuggestions: followUpSuggestions ?? this.followUpSuggestions,
    );
  }
}
