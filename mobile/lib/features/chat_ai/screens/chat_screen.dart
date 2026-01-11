import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/voice_interaction_widget.dart';
import '../providers/voice_interaction_provider.dart';

// Ensure we have fallback for missing types if any dependencies are broken deeper in the chain
// but try to use the imported ones first.

/// Advanced Glassmorphic Chat Screen
/// Features:
/// - Staggered message animations
/// - Glassmorphism effects (Blur + transparency)
/// - Voice interaction integration
/// - Smart suggestions
/// - Dynamic gradients
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  // Animation controllers
  late AnimationController _backgroundController;

  // Premium Theme Constants
  static const Color _primaryColor = Color(0xFF6366F1);
  static const Color _accentColor = Color(0xFFC084FC);
  static const Color _secondaryColor = Color(0xFFEC4899);

  // Gradients
  static const LinearGradient _bgGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient _bubbleGradient = LinearGradient(
    colors: [_primaryColor, _secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);

    _addIntroduction();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  void _addIntroduction() {
    // Initial staggered messages
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _addMessage(
            ChatMessage(text: "Hello! I'm Aivonity AI.", isUser: false),);
      }
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _addMessage(ChatMessage(
            text:
                "I'm connected to your vehicle's telemetry system. How can I assist you today?",
            isUser: false,),);
      }
    });
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    HapticFeedback.lightImpact();

    _addMessage(ChatMessage(text: text.trim(), isUser: true));
    _messageController.clear();
    setState(() => _isTyping = true);

    // Simulate AI thinking and response
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _generateResponse(text);
      }
    });
  }

  void _generateResponse(String input) {
    setState(() => _isTyping = false);

    String response;
    final lower = input.toLowerCase();

    if (lower.contains('diagnose') || lower.contains('health')) {
      response =
          'Running full diagnostics...\n\n✅ Engine Systems: Optimal\n✅ Battery Voltage: 14.2V (Good)\n⚠️ Tire Pressure: Rear Left Low (28 PSI)\n\nRecommendation: Inflate rear left tire to 35 PSI.';
    } else if (lower.contains('maintenance') || lower.contains('service')) {
      response =
          'Based on your mileage (42,500 km), you are due for Service B.\n\n• Oil Change\n• Brake Fluid Check\n• Cabin Filter Replacement\n\nWould you like me to schedule this at your preferred center?';
    } else if (lower.contains('weather') || lower.contains('temperature')) {
      response =
          'Current outside temperature is 72°F. Rain is expected in 45 minutes on your current route. Wipers are in auto mode.';
    } else {
      response =
          "I can help with diagnostics, maintenance scheduling, navigation, and vehicle controls. Try asking 'Check vehicle health' or 'Find nearest charging station'.";
    }

    _addMessage(ChatMessage(text: response, isUser: false));

    // Optional: Speak response via provider
    try {
      ref.read(voiceInteractionProvider.notifier).speakResponse(response);
    } catch (e) {
      // Ignore provider errors if service not ready
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // Small delay to allow list to render new item size
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceInteractionProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildGlassAppBar(),
      body: Stack(
        children: [
          // Animated Background
          Container(decoration: const BoxDecoration(gradient: _bgGradient)),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) {
                return CustomPaint(
                  painter: BackgroundMeshPainter(
                      animation: _backgroundController.value,),
                );
              },
            ),
          ),

          // Main Chat Area
          Column(
            children: [
              SizedBox(
                  height: kToolbarHeight + MediaQuery.of(context).padding.top,),

              // Voice Status Bar (conditionally shown)
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                child: (voiceState.isListening || voiceState.isSpeaking)
                    ? _buildVoiceStatusBar(voiceState)
                    : const SizedBox.shrink(),
              ),

              // Messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return MessageBubble(
                      message: _messages[index],
                      isLast: index == _messages.length - 1,
                    );
                  },
                ),
              ),

              // Typing Indicator
              if (_isTyping)
                const Padding(
                  padding: EdgeInsets.only(left: 20, bottom: 10),
                  child: TypingIndicator(),
                ),

              // Input Area
              _buildGlassInputArea(),
            ],
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildGlassAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.black.withValues(alpha:0.2),
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              gradient: _bubbleGradient,
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.auto_awesome, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Aivonity AI',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: Colors.greenAccent, shape: BoxShape.circle,),
                  ),
                  const SizedBox(width: 4),
                  const Text('Online',
                      style: TextStyle(fontSize: 12, color: Colors.white70),),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildVoiceStatusBar(VoiceInteractionState state) {
    return Container(
      width: double.infinity,
      color: _primaryColor.withValues(alpha:0.2),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(state.isListening ? Icons.mic : Icons.volume_up,
              color: Colors.white, size: 16,),
          const SizedBox(width: 8),
          Text(
            state.isListening ? 'Listening...' : 'Speaking...',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500,),
          ),
          if (state.recognizedText?.isNotEmpty == true)
            Flexible(
                child: Text(' : ${state.recognizedText}',
                    style: const TextStyle(color: Colors.white70),
                    overflow: TextOverflow.ellipsis,),),
        ],
      ),
    );
  }

  Widget _buildGlassInputArea() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withValues(alpha:0.7),
            border:
                Border(top: BorderSide(color: Colors.white.withValues(alpha:0.1))),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 10,
            top: 10,
            left: 16,
            right: 16,
          ),
          child: Row(
            children: [
              // Voice Widget
              VoiceInteractionWidget(
                onVoiceInput: (text) {
                  _messageController.text = text;
                  _sendMessage(text);
                },
              ),
              const SizedBox(width: 10),

              // Text Field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha:0.3),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white.withValues(alpha:0.1)),
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10,),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Send Button
              GestureDetector(
                onTap: () => _sendMessage(_messageController.text),
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: const BoxDecoration(
                    gradient: _bubbleGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20,),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated Message Bubble
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isLast;

  const MessageBubble({super.key, required this.message, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        final clampedValue = value.clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, 20 * (1 - clampedValue)),
          child: Opacity(
            opacity: clampedValue,
            child: Align(
              alignment:
                  message.isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,),
                decoration: BoxDecoration(
                  gradient: message.isUser
                      ? const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFFC084FC)],)
                      : LinearGradient(colors: [
                          const Color(0xFF334155).withValues(alpha:0.9),
                          const Color(0xFF334155).withValues(alpha:0.8),
                        ],),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: message.isUser
                        ? const Radius.circular(20)
                        : const Radius.circular(5),
                    bottomRight: message.isUser
                        ? const Radius.circular(5)
                        : const Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 15, height: 1.4,),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                          color: Colors.white.withValues(alpha:0.5), fontSize: 10,),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }
}

/// Typing Indicator with Wave Animation
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200),)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF334155).withValues(alpha:0.8),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
          bottomLeft: Radius.circular(5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final double value = _controller.value;
              final double offset = index * 0.2;
              final double opacity =
                  (1.0 - (value - offset).abs()).clamp(0.2, 1.0);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:opacity),
                  shape: BoxShape.circle,
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser})
      : timestamp = DateTime.now();
}

/// Custom Background Painter for subtle mesh effect
class BackgroundMeshPainter extends CustomPainter {
  final double animation;
  BackgroundMeshPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha:0.03)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    // Draw some curved lines
    path.moveTo(0, size.height * 0.2);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * (0.2 + 0.1 * animation),
      size.width,
      size.height * 0.3,
    );

    path.moveTo(0, size.height * 0.6);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * (0.6 - 0.1 * animation),
      size.width,
      size.height * 0.7,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

