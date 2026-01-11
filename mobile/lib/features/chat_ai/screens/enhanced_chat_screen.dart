import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/voice_interaction_provider.dart';
import '../widgets/voice_interaction_widget.dart';
import '../../../core/models/chat_models.dart';

/// Enhanced AIVONITY Chat Screen with Voice Integration
/// AI-powered chat interface with comprehensive voice capabilities
class EnhancedChatScreen extends ConsumerStatefulWidget {
  const EnhancedChatScreen({super.key});

  @override
  ConsumerState<EnhancedChatScreen> createState() => _EnhancedChatScreenState();
}

class _EnhancedChatScreenState extends ConsumerState<EnhancedChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _isTyping = false;
  late AnimationController _typingController;

  final List<String> _quickSuggestions = [
    'Check vehicle health',
    'Schedule maintenance',
    'Find service centers',
    'Fuel efficiency tips',
    'Troubleshoot issues',
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _addWelcomeMessage();
  }

  void _setupAnimations() {
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(
        ChatMessage(
          id: 'welcome',
          content:
              'Hello! I\'m your AI vehicle assistant. How can I help you today? You can type your message or use voice input.',
          isUser: false,
          timestamp: DateTime.now(),
          type: MessageType.text,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceInteractionProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Voice status indicator
          if (voiceState.isListening || voiceState.isSpeaking)
            _buildVoiceStatusBar(voiceState),

          // Quick Suggestions (show only when no messages from user)
          if (_messages.length == 1) _buildQuickSuggestions(),

          // Messages List
          Expanded(child: _buildMessagesList()),

          // Typing Indicator
          if (_isTyping) _buildTypingIndicator(),

          // Input Area
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Assistant',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Consumer(
                builder: (context, ref, child) {
                  final voiceState = ref.watch(voiceInteractionProvider);
                  String status = 'Online';
                  Color statusColor = Colors.green;

                  if (voiceState.isListening) {
                    status = 'Listening...';
                    statusColor = Colors.orange;
                  } else if (voiceState.isSpeaking) {
                    status = 'Speaking...';
                    statusColor = Colors.blue;
                  } else if (voiceState.isProcessing) {
                    status = 'Processing...';
                    statusColor = Colors.purple;
                  }

                  return Text(
                    status,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: statusColor),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showChatOptions(),
        ),
      ],
    );
  }

  Widget _buildVoiceStatusBar(VoiceInteractionState voiceState) {
    String statusText = '';
    Color backgroundColor = Colors.transparent;
    IconData icon = Icons.mic;

    if (voiceState.isListening) {
      statusText = 'Listening... Tap to stop';
      backgroundColor = Colors.red.withValues(alpha:0.1);
      icon = Icons.mic;
    } else if (voiceState.isSpeaking) {
      statusText = 'Speaking... Tap to stop';
      backgroundColor = Colors.blue.withValues(alpha:0.1);
      icon = Icons.volume_up;
    } else if (voiceState.isProcessing) {
      statusText = 'Processing your voice input...';
      backgroundColor = Colors.purple.withValues(alpha:0.1);
      icon = Icons.hourglass_empty;
    }

    if (voiceState.recognizedText != null &&
        voiceState.recognizedText!.isNotEmpty) {
      statusText += '\n"${voiceState.recognizedText}"';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha:0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (voiceState.error != null)
            const Icon(
              Icons.error,
              color: Colors.red,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildQuickSuggestions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick suggestions:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color:
                      Theme.of(context).colorScheme.onSurface.withValues(alpha:0.7),
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickSuggestions.map((suggestion) {
              return GestureDetector(
                onTap: () => _sendMessage(suggestion),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha:0.3),
                    ),
                  ),
                  child: Text(
                    suggestion,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: message.isUser
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: message.isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
                border: message.isUser
                    ? null
                    : Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha:0.2),
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: message.isUser
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: message.isUser
                                  ? Colors.white.withValues(alpha:0.7)
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha:0.5),
                            ),
                      ),
                      if (!message.isUser) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _speakMessage(message.content),
                          child: Icon(
                            Icons.volume_up,
                            size: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha:0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha:0.1),
              child: Icon(
                Icons.person,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha:0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedBuilder(
      animation: _typingController,
      builder: (context, child) {
        final animationValue = (_typingController.value + (index * 0.2)) % 1.0;
        return Transform.scale(
          scale: 0.5 + (0.5 * (1 - (animationValue - 0.5).abs() * 2)),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha:
                    0.3 + (0.7 * (1 - (animationValue - 0.5).abs() * 2)),
                  ),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Voice Input Button
            VoiceInteractionWidget(
              onVoiceInput: (text) {
                if (text.isNotEmpty) {
                  _sendMessage(text);
                }
              },
              onVoiceStart: () {
                // Optional: Show voice listening UI
              },
              onVoiceStop: () {
                // Optional: Hide voice listening UI
              },
            ),

            const SizedBox(width: 12),

            // Text Input
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (text) => _sendMessage(text),
              ),
            ),

            const SizedBox(width: 12),

            // Send Button
            GestureDetector(
              onTap: () => _sendMessage(_messageController.text),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: text.trim(),
          isUser: true,
          timestamp: DateTime.now(),
          type: MessageType.text,
        ),
      );
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();
    _typingController.repeat();

    // Simulate AI response
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(
            ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              content: _generateAIResponse(text),
              isUser: false,
              timestamp: DateTime.now(),
              type: MessageType.text,
            ),
          );
        });
        _typingController.stop();
        _scrollToBottom();
      }
    });
  }

  String _generateAIResponse(String userMessage) {
    final message = userMessage.toLowerCase();

    if (message.contains('health') || message.contains('check')) {
      return '''🚗 **Vehicle Health Status**

Your vehicle is performing excellently!

**Overall Health: 92%** ✅
• Engine: 95% - Excellent condition
• Brakes: 94% - Recently serviced
• Tires: 89% - Check pressure soon

**Next Maintenance: 2,500 miles**

Would you like me to schedule an appointment?''';
    } else if (message.contains('maintenance') || message.contains('service')) {
      return '''🔧 **Maintenance Recommendations**

Based on your vehicle's current status:

**Due Soon:**
• Oil change (2,500 miles)
• Tire rotation (1,200 miles)

**Upcoming:**
• Brake inspection (8,000 miles)
• Air filter replacement (10,000 miles)

**Service Centers Near You:**
📍 Tesla Service Center - 2.3 miles
📍 AutoCare Plus - 4.1 miles
📍 Premium Motors - 5.8 miles

Would you like to book an appointment?''';
    } else if (message.contains('fuel') || message.contains('efficiency')) {
      return '''⛽ **Fuel Efficiency Report**

Your current average: **32.5 MPG** (Above average! 🎉)

**Top Tips to Improve Further:**
• Maintain steady speeds (60-70 mph optimal)
• Keep tires inflated to 35 PSI
• Remove excess weight from trunk
• Use cruise control on highways
• Plan trips to avoid heavy traffic

**This Week's Performance:**
Monday: 34.2 MPG ⬆️
Tuesday: 31.8 MPG ⬇️
Wednesday: 33.1 MPG ⬆️

Your eco-driving score: **8.5/10** 🌱''';
    } else if (message.contains('problem') ||
        message.contains('issue') ||
        message.contains('trouble')) {
      return '''🔍 **Diagnostic Assistant**

I'm here to help troubleshoot! To provide the best assistance, please tell me:

**1. What type of issue?**
• Warning lights on dashboard
• Unusual sounds (grinding, squeaking)
• Performance problems
• Electrical issues (charging)

**2. When does it occur?**
• During startup
• While driving
• When braking
• All the time

**3. Recent changes?**
• New symptoms after service
• Weather-related
• Gradual onset

The more details you provide, the better I can help diagnose the issue! 🔧''';
    } else if (message.contains('book') ||
        message.contains('appointment') ||
        message.contains('schedule')) {
      return '''📅 **Service Scheduling**

I can help you book an appointment! Here are available slots:

**This Week:**
• Thursday, Dec 14 - 2:00 PM, 4:30 PM
• Friday, Dec 15 - 10:00 AM, 1:30 PM

**Next Week:**
• Monday, Dec 18 - 9:00 AM, 1:00 PM, 5:00 PM
• Tuesday, Dec 19 - 11:00 AM, 2:30 PM

**Recommended Services:**
✅ Oil Change (\$45)
✅ Tire Rotation (\$25)
⚠️ Brake Inspection (Free)

**Estimated Time:** 1.5 hours
**Total Cost:** ~\$70

Which time works best for you?''';
    } else if (message.contains('find') ||
        message.contains('locate') ||
        message.contains('where')) {
      return '''📍 **Service Center Locator**

**Nearest Locations:**

🏢 **Tesla Service Center**
📍 123 Main St, Downtown
⭐ 4.8/5 (156 reviews)
🕒 Open until 7 PM
📞 (555) 123-4567

🏢 **AutoCare Plus**
📍 456 Oak Ave, Midtown
⭐ 4.6/5 (189 reviews)
🕒 Open until 6 PM
📞 (555) 987-6543

🏢 **Premium Motors**
📍 789 Pine Rd, Uptown
⭐ 4.7/5 (267 reviews)
🕒 Open until 8 PM
📞 (555) 456-7890

Would you like directions to any of these locations?''';
    } else {
      return '''🤖 **AIVONITY AI Assistant**

I understand you're asking about "${userMessage.length > 50 ? "${userMessage.substring(0, 50)}..." : userMessage}"

I'm specialized in helping with:
• 🚗 Vehicle health monitoring & diagnostics
• 🔧 Maintenance scheduling & reminders  
• 🛠️ Troubleshooting & problem solving
• 📍 Finding service centers & booking appointments
• ⛽ Fuel efficiency & eco-driving tips
• 📊 Performance analytics & insights

**Try asking:**
• "How's my vehicle health?"
• "Schedule my next oil change"
• "Why is my check engine light on?"
• "Find service centers near me"

How can I help you with your vehicle today? 🚙''';
    }
  }

  void _speakMessage(String text) {
    final voiceNotifier = ref.read(voiceInteractionProvider.notifier);
    voiceNotifier.speakResponse(text);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showChatOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('Clear Chat'),
              onTap: () {
                Navigator.pop(context);
                _clearChat();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_voice),
              title: const Text('Voice Settings'),
              onTap: () {
                Navigator.pop(context);
                // Show voice settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help'),
              onTap: () {
                Navigator.pop(context);
                _showHelp();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
    });
    _addWelcomeMessage();
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Assistant Help'),
        content: const Text(
          'I can help you with:\n\n'
          '• Vehicle health monitoring\n'
          '• Maintenance scheduling\n'
          '• Troubleshooting issues\n'
          '• Finding service centers\n'
          '• Fuel efficiency tips\n'
          '• General vehicle questions\n\n'
          'Just type your question or use voice input by tapping the microphone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

