import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/voice_interaction_provider.dart';
import '../../../core/services/gemini_ai_service.dart';
import '../../../core/services/simple_gemini_service.dart';
import '../../../core/services/actionable_ai_service.dart';

/// Multilingual AI Chat Screen with Gemini AI integration
class MultilingualAIChatScreen extends ConsumerStatefulWidget {
  const MultilingualAIChatScreen({super.key});

  @override
  ConsumerState<MultilingualAIChatScreen> createState() =>
      _MultilingualAIChatScreenState();
}

class _MultilingualAIChatScreenState
    extends ConsumerState<MultilingualAIChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;

  bool _isTyping = false;
  String _selectedLanguage = 'en';
  bool _voiceEnabled = true;
  List<String> _suggestions = [];
  final List<ChatMessage> _conversationHistory = [];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeChat();

    // Listen for voice input results
    ref.listenManual(voiceInteractionProvider, (previous, next) {
      if (next.recognizedText != null &&
          next.recognizedText!.isNotEmpty &&
          (previous?.recognizedText != next.recognizedText)) {
        // New voice input recognized, send it to AI
        _sendMessage(next.recognizedText!);
      }
    });
  }

  void _setupAnimations() {
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _typingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _typingAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _initializeChat() async {
    // Initialize Gemini AI services with default API key
    await GeminiAIService.instance.initialize();
    await SimpleGeminiService.instance.initialize();

    // Generate initial suggestions
    _generateSuggestions('');
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceInteractionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AIVONITY Helper Assistant'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // Language selector
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: _changeLanguage,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'en', child: Text('English')),
              const PopupMenuItem(value: 'es', child: Text('Español')),
              const PopupMenuItem(value: 'fr', child: Text('Français')),
              const PopupMenuItem(value: 'de', child: Text('Deutsch')),
              const PopupMenuItem(value: 'it', child: Text('Italiano')),
              const PopupMenuItem(value: 'pt', child: Text('Português')),
              const PopupMenuItem(value: 'ja', child: Text('日本語')),
              const PopupMenuItem(value: 'ko', child: Text('한국어')),
              const PopupMenuItem(value: 'zh', child: Text('中文')),
            ],
          ),

          // Voice toggle
          IconButton(
            icon: Icon(_voiceEnabled ? Icons.mic : Icons.mic_off),
            onPressed: () => setState(() => _voiceEnabled = !_voiceEnabled),
            tooltip: 'Toggle Voice',
          ),

          // Test API Key
          IconButton(
            icon: const Icon(Icons.check_circle),
            onPressed: _testApiKey,
            tooltip: 'Test API Key',
          ),

          // API Key settings
          IconButton(
            icon: const Icon(Icons.key),
            onPressed: _showApiKeyDialog,
            tooltip: 'Configure API Key',
          ),

          // Clear chat
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearChat,
            tooltip: 'Clear Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: _buildChatMessages(),
          ),

          // Suggestions
          if (_suggestions.isNotEmpty) _buildSuggestions(),

          // Message input area
          _buildMessageInput(voiceState),
        ],
      ),
    );
  }

  Widget _buildChatMessages() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _conversationHistory.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isTyping && index == _conversationHistory.length) {
          return _buildTypingIndicator();
        }

        final message = _conversationHistory[index];
        final isUser = message.role.name == 'user';

        return _buildMessageBubble(message, isUser);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft:
                isUser ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight:
                isUser ? const Radius.circular(4) : const Radius.circular(16),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2),
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isUser
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
              ),
            ),
            if (message.language != 'en') ...[
              const SizedBox(height: 4),
              Text(
                'Language: ${message.language.toUpperCase()}',
                style: TextStyle(
                  color: isUser
                      ? Colors.white.withValues(alpha: 0.7)
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: const Radius.circular(4),
            bottomRight: const Radius.circular(16),
          ),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _typingAnimation,
              builder: (context, child) {
                return Row(
                  children: List.generate(3, (index) {
                    final delay = index * 0.2;
                    final animation =
                        (_typingAnimation.value - delay).clamp(0.0, 1.0);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 4,
                      height: 4 + (animation * 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                );
              },
            ),
            const SizedBox(width: 8),
            Text(
              'AI is thinking...',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(
                suggestion,
                style: const TextStyle(fontSize: 12),
              ),
              onPressed: () => _sendMessage(suggestion),
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageInput(VoiceInteractionState voiceState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Voice input button
          if (_voiceEnabled)
            IconButton(
              icon: Icon(
                voiceState.isListening ? Icons.mic : Icons.mic_none,
                color: voiceState.isListening
                    ? Colors.red
                    : Theme.of(context).colorScheme.primary,
              ),
              onPressed: voiceState.isListening ? null : _startVoiceInput,
              tooltip: 'Voice Input',
            ),

          // Text input field
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText:
                    'Chat with Gemini AI about navigation, traffic, vehicle help, or anything...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: _sendMessage,
            ),
          ),

          // Send button
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => _sendMessage(_messageController.text),
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  void _changeLanguage(String languageCode) {
    setState(() => _selectedLanguage = languageCode);
    GeminiAIService.instance.setLanguage(languageCode);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Language changed to ${languageCode.toUpperCase()}'),
      ),
    );
  }

  void _clearChat() {
    setState(() {
      _conversationHistory.clear();
    });
    GeminiAIService.instance.clearHistory();
    // Note: SimpleGeminiService doesn't have a clearHistory method

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat history cleared')),
    );
  }

  void _testApiKey() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Testing API key...')),
    );

    try {
      final isWorking = await GeminiAIService.instance.testApiKey();
      if (isWorking) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ API key is working correctly!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ API key test failed. Check the logs for details.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ API key test error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showApiKeyDialog() {
    final TextEditingController apiKeyController = TextEditingController();
    final currentStatus = GeminiAIService.getApiKeyStatus();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configure Gemini API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current status: $currentStatus\n\n'
              'Enter your Gemini API key to enable AI chat functionality.\n\n'
              'Get your API key from: https://makersuite.google.com/app/apikey',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'AIzaSy...',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final apiKey = apiKeyController.text.trim();
              if (apiKey.isNotEmpty) {
                await GeminiAIService.configureApiKey(apiKey);
                SimpleGeminiService.configureApiKey(apiKey);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'API key configured successfully. Status: ${GeminiAIService.getApiKeyStatus()}',
                    ),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _startVoiceInput() async {
    final voiceNotifier = ref.read(voiceInteractionProvider.notifier);
    await voiceNotifier.startVoiceInput();

    // The voice interaction provider will handle the result
    // We'll listen to state changes in the build method
  }

  void _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Add user message to local history
    final userMessage = ChatMessage(
      role: MessageRole.user,
      content: message,
      timestamp: DateTime.now(),
      language: _selectedLanguage,
    );

    setState(() {
      _conversationHistory.add(userMessage);
      _isTyping = true;
    });
    _messageController.clear();

    try {
      // Check if this is a specific actionable command (navigation, traffic, emergency)
      final actionResult =
          await ActionableAIService.instance.parseAndExecuteAction(
        message,
        context,
      );

      // Only use actionable commands for specific navigation/traffic/emergency requests
      // For general conversation, always use Gemini AI for real-time chat
      final isNavigationCommand = message.toLowerCase().contains('navigate') ||
          message.toLowerCase().contains('go to') ||
          message.toLowerCase().contains('take me to') ||
          message.toLowerCase().contains('find route') ||
          message.toLowerCase().contains('directions') ||
          message.toLowerCase().contains('traffic') ||
          message.toLowerCase().contains('accident') ||
          message.toLowerCase().contains('road closure') ||
          message.toLowerCase().contains('emergency') ||
          message.toLowerCase().contains('hospital') ||
          message.toLowerCase().contains('police') ||
          message.toLowerCase().contains('towing');

      if (actionResult.executed &&
          actionResult.message != null &&
          isNavigationCommand) {
        // Action was executed for navigation/traffic/emergency, show the result message
        final actionMessage = ChatMessage(
          role: MessageRole.assistant,
          content: actionResult.message!,
          timestamp: DateTime.now(),
          language: _selectedLanguage,
        );

        setState(() {
          _conversationHistory.add(actionMessage);
          _isTyping = false;
        });

        // Handle navigation if route is specified
        if (actionResult.route != null) {
          _navigateToRoute(actionResult.route!, actionResult.parameters);
        }
        // Handle location actions directly (no route needed)
        else if (actionResult.action == AIAction.location &&
            actionResult.parameters != null) {
          final searchType = actionResult.parameters!['searchType'] as String?;
          final traffic = actionResult.parameters!['traffic'] as bool? ?? false;
          final emergency =
              actionResult.parameters!['emergency'] as bool? ?? false;
          if (searchType != null) {
            _handleLocationSearch(
              searchType,
              traffic: traffic,
              emergency: emergency,
            );
          }
        }

        // Generate new suggestions
        _generateSuggestions(message);

        // Scroll to bottom
        _scrollToBottom();
        return;
      }

      // For all other messages, use Gemini AI for real-time intelligent chat
      final aiResponse = await GeminiAIService.instance.sendMessage(
        message,
        language: _selectedLanguage,
      );

      // Add AI response to local history
      final aiMessage = ChatMessage(
        role: MessageRole.assistant,
        content: aiResponse.message,
        timestamp: DateTime.now(),
        language: aiResponse.language,
      );

      setState(() {
        _conversationHistory.add(aiMessage);
      });

      // Generate new suggestions based on the conversation
      _generateSuggestions(message);

      // Scroll to bottom
      _scrollToBottom();
    } catch (e) {
      // Add error message to conversation
      final errorMessage = ChatMessage(
        role: MessageRole.assistant,
        content:
            'I apologize, but I\'m having trouble processing your request right now. Please try again.',
        timestamp: DateTime.now(),
        language: _selectedLanguage,
      );

      setState(() {
        _conversationHistory.add(errorMessage);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isTyping = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _navigateToRoute(String route, Map<String, dynamic>? parameters) {
    // Use Navigator for navigation (MaterialApp routes)
    if (parameters != null && parameters.containsKey('searchType')) {
      // Handle location search - open external maps
      final searchType = parameters['searchType'] as String;
      final traffic = parameters['traffic'] as bool? ?? false;
      final emergency = parameters['emergency'] as bool? ?? false;
      _handleLocationSearch(searchType, traffic: traffic, emergency: emergency);
    } else {
      // Regular navigation
      Navigator.pushNamed(context, route);
    }
  }

  void _handleLocationSearch(
    String searchType, {
    bool traffic = false,
    bool emergency = false,
  }) async {
    try {
      // Debug logging
      print(
        'Google Maps Debug - SearchType: $searchType, Traffic: $traffic, Emergency: $emergency',
      );

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission is required to find nearby places.',
              ),
            ),
          );
          return;
        }
      }

      // Get current position
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      print(
        'Google Maps Debug - Current position: ${position.latitude}, ${position.longitude}',
      );

      String url;
      String successMessage;

      // Create simpler, more reliable Google Maps URLs
      if (emergency) {
        // Search for hospitals near current location
        url = 'https://maps.google.com/maps?q=hospital+near+me';
        successMessage =
            'Opening Google Maps to find hospitals and emergency services near you';
      } else if (traffic && searchType.contains('traffic+to+')) {
        // Extract destination and create directions with traffic
        final destination =
            searchType.replaceFirst('traffic+to+', '').replaceAll('+', ' ');
        url =
            'https://maps.google.com/maps?saddr=My+Location&daddr=$destination&dirflg=d';
        successMessage =
            'Opening Google Maps with driving directions and traffic to $destination';
      } else if (traffic) {
        // Show traffic around current location
        url =
            'https://maps.google.com/maps?q=${position.latitude},${position.longitude}&layer=t';
        successMessage =
            'Opening Google Maps with traffic layer around your location';
      } else if (searchType.contains('+directions')) {
        // Navigation command like "downtown+directions"
        final destination =
            searchType.replaceAll('+directions', '').replaceAll('+', ' ');
        url =
            'https://maps.google.com/maps?saddr=My+Location&daddr=$destination';
        successMessage = 'Opening Google Maps with directions to $destination';
      } else if (searchType.contains('+to+')) {
        // Route search
        final parts = searchType.split('+to+');
        if (parts.length == 2) {
          final destination = parts[1].replaceAll('+', ' ');
          url =
              'https://maps.google.com/maps?saddr=My+Location&daddr=$destination';
          successMessage =
              'Opening Google Maps with directions to $destination';
        } else {
          final searchQuery = searchType.replaceAll('+', ' ');
          url = 'https://maps.google.com/maps?q=$searchQuery';
          successMessage = 'Opening Google Maps to search for $searchQuery';
        }
      } else {
        // Regular search near current location
        final searchQuery = searchType.replaceAll('+', ' ');
        url = 'https://maps.google.com/maps?q=$searchQuery+near+me';
        successMessage = 'Opening Google Maps to find $searchQuery near you';
      }

      // Debug logging for URL
      print('Google Maps Debug - Generated URL: $url');

      // Try to launch the URL
      try {
        final uri = Uri.parse(url);
        print('Google Maps Debug - Parsed URI: $uri');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          // Fallback: try opening Google Maps app directly
          final fallbackUri = Uri.parse(
            'geo:${position.latitude},${position.longitude}?q=$searchType',
          );
          if (await canLaunchUrl(fallbackUri)) {
            await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(successMessage),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          } else {
            // Final fallback: open Google Maps website without specific location
            final webUri = Uri.parse('https://maps.google.com/');
            if (await canLaunchUrl(webUri)) {
              await launchUrl(webUri, mode: LaunchMode.externalApplication);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening Google Maps website'),
                  backgroundColor: Colors.blue,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Unable to open Google Maps. Please check your internet connection and try again.',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      } catch (urlError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening Google Maps: ${urlError.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to access location services: ${e.toString()}'),
        ),
      );
    }
  }

  void _generateSuggestions(String context) async {
    try {
      final suggestions =
          await GeminiAIService.instance.generateSuggestions(context);
      setState(() => _suggestions = suggestions);
    } catch (e) {
      // Use default suggestions on error - general conversational topics
      setState(
        () => _suggestions = [
          'Tell me about yourself',
          'What\'s on your mind today?',
          'Need help with navigation?',
          'Want to chat about anything?',
          'How can I assist you?',
        ],
      );
    }
  }
}
