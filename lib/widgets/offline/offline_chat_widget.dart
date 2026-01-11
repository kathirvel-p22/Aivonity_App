import 'package:flutter/material.dart';
import '../../services/offline/offline_manager.dart';
import '../../design_system/design_system.dart';
import 'offline_indicator.dart';

/// Chat widget that works offline with cached messages
class OfflineChatWidget extends StatefulWidget {
  final String conversationId;
  final String? vehicleId;

  const OfflineChatWidget({
    super.key,
    required this.conversationId,
    this.vehicleId,
  });

  @override
  State<OfflineChatWidget> createState() => _OfflineChatWidgetState();
}

class _OfflineChatWidgetState extends State<OfflineChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final OfflineManager _offlineManager = OfflineManager();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      final messagesData = await _offlineManager.getOfflineChatMessages(
        conversationId: widget.conversationId,
        limit: 100,
      );

      setState(() {
        _messages = messagesData
            .map((data) => ChatMessage.fromJson(data))
            .toList();
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load messages: $e')));
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: widget.conversationId,
      content: text,
      senderType: MessageSenderType.user,
      timestamp: DateTime.now(),
      isOffline: _offlineManager.isOffline,
    );

    // Add message to UI immediately
    setState(() {
      _messages.insert(0, message);
      _messageController.clear();
    });

    // Store message for offline access and sync
    try {
      await _offlineManager.storeChatMessageOffline(message.toJson());

      // If offline, add a pending response placeholder
      if (_offlineManager.isOffline) {
        final pendingResponse = ChatMessage(
          id: '${message.id}_response',
          conversationId: widget.conversationId,
          content:
              'I\'m currently offline, but I\'ll respond when connection is restored. Your message has been saved.',
          senderType: MessageSenderType.assistant,
          timestamp: DateTime.now(),
          isOffline: true,
          isPending: true,
        );

        setState(() {
          _messages.insert(0, pendingResponse);
        });

        await _offlineManager.storeChatMessageOffline(pendingResponse.toJson());
      } else {
        // If online, simulate AI response (in real app, this would call the AI service)
        await _simulateAIResponse(message);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
    }

    _scrollToBottom();
  }

  Future<void> _simulateAIResponse(ChatMessage userMessage) async {
    // Simulate AI processing delay
    await Future.delayed(const Duration(seconds: 1));

    final response = ChatMessage(
      id: '${userMessage.id}_ai_response',
      conversationId: widget.conversationId,
      content: _generateAIResponse(userMessage.content),
      senderType: MessageSenderType.assistant,
      timestamp: DateTime.now(),
      isOffline: false,
    );

    setState(() {
      _messages.insert(0, response);
    });

    await _offlineManager.storeChatMessageOffline(response.toJson());
  }

  String _generateAIResponse(String userMessage) {
    // Simple response generation based on keywords
    final message = userMessage.toLowerCase();

    if (message.contains('fuel') || message.contains('gas')) {
      return 'Based on your vehicle data, your current fuel level is 68%. You have approximately 340 miles of range remaining.';
    } else if (message.contains('maintenance') || message.contains('service')) {
      return 'Your next scheduled maintenance is due in 2,450 miles. I can help you find nearby service centers when you\'re ready.';
    } else if (message.contains('performance') || message.contains('engine')) {
      return 'Your vehicle\'s performance metrics look good. Engine efficiency is at 92% and all systems are operating normally.';
    } else if (message.contains('location') || message.contains('where')) {
      return 'I can help you with location-based services. Would you like me to find nearby service centers or charging stations?';
    } else {
      return 'I understand you\'re asking about "$userMessage". While I have access to your cached vehicle data offline, I can provide more detailed assistance when we\'re back online.';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Offline indicator
        const OfflineCapabilityIndicator(
          featureName: 'chat',
          requiredActions: ['view_history', 'compose'],
        ),

        // Messages list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: AivonitySpacing.paddingMD,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(_messages[index]);
                  },
                ),
        ),

        // Message input
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.senderType == MessageSenderType.user;
    final theme = Theme.of(context);

    return Container(
      margin: AivonitySpacing.verticalSM,
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary,
              child: Icon(
                Icons.smart_toy,
                color: theme.colorScheme.onPrimary,
                size: 16,
              ),
            ),
            AivonitySpacing.hGapSM,
          ],

          Flexible(
            child: Container(
              padding: AivonitySpacing.paddingMD,
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: isUser
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isUser
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  AivonitySpacing.vGapXS,

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTimestamp(message.timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isUser
                              ? theme.colorScheme.onPrimary.withValues(alpha:0.7)
                              : theme.colorScheme.onSurfaceVariant.withValues(alpha:
                                  0.7,
                                ),
                        ),
                      ),

                      if (message.isOffline) ...[
                        AivonitySpacing.hGapXS,
                        Icon(
                          message.isPending ? Icons.schedule : Icons.wifi_off,
                          size: 12,
                          color: isUser
                              ? theme.colorScheme.onPrimary.withValues(alpha:0.7)
                              : theme.colorScheme.onSurfaceVariant.withValues(alpha:
                                  0.7,
                                ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (isUser) ...[
            AivonitySpacing.hGapSM,
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.secondary,
              child: Icon(
                Icons.person,
                color: theme.colorScheme.onSecondary,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: AivonitySpacing.paddingMD,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: _offlineManager.isOffline
                    ? 'Type a message (offline mode)'
                    : 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: AivonitySpacing.paddingMD,
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),

          AivonitySpacing.hGapMD,

          FloatingActionButton(
            mini: true,
            onPressed: _sendMessage,
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// Chat message model
class ChatMessage {
  final String id;
  final String conversationId;
  final String content;
  final MessageSenderType senderType;
  final DateTime timestamp;
  final bool isOffline;
  final bool isPending;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.senderType,
    required this.timestamp,
    this.isOffline = false,
    this.isPending = false,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['message_id'] ?? json['id'],
      conversationId: json['conversation_id'],
      content: json['content'],
      senderType: MessageSenderType.values.firstWhere(
        (type) => type.toString() == 'MessageSenderType.${json['sender_type']}',
        orElse: () => MessageSenderType.user,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      isOffline: json['is_offline'] ?? false,
      isPending: json['is_pending'] ?? false,
      metadata: json['metadata_json'] != null
          ? Map<String, dynamic>.from(json['metadata_json'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': id,
      'conversation_id': conversationId,
      'content': content,
      'sender_type': senderType.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'sync_status': isOffline ? 0 : 1,
      'metadata_json': {
        'is_offline': isOffline,
        'is_pending': isPending,
        ...?metadata,
      },
    };
  }
}

enum MessageSenderType { user, assistant }

