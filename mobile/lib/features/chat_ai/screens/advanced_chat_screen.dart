import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/advanced_typing_indicator.dart';
import '../widgets/advanced_chat_input.dart';
import '../widgets/multilingual_message_widget.dart';
import '../widgets/language_selector_widget.dart';
import '../providers/multilingual_chat_provider.dart';
import '../../../core/services/multilingual_ai_chat_service.dart';

/// Advanced Chat Screen
/// Sophisticated chat interface with all advanced UI components integrated
class AdvancedChatScreen extends ConsumerStatefulWidget {
  const AdvancedChatScreen({super.key});

  @override
  ConsumerState<AdvancedChatScreen> createState() => _AdvancedChatScreenState();
}

class _AdvancedChatScreenState extends ConsumerState<AdvancedChatScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  bool _showScrollToBottom = false;
  bool _isAtBottom = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupScrollListener();
    _addWelcomeMessage();
  }

  void _setupAnimations() {
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeInOut,
    ),);
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final isAtBottom = _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100;

      if (isAtBottom != _isAtBottom) {
        setState(() {
          _isAtBottom = isAtBottom;
          _showScrollToBottom = !isAtBottom;
        });

        if (_showScrollToBottom) {
          _fabController.forward();
        } else {
          _fabController.reverse();
        }
      }
    });
  }

  void _addWelcomeMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Add welcome message if no messages exist
      final messages = ref.read(chatMessagesProvider);
      if (messages.isEmpty) {
        // This would typically be handled by the provider
        // For now, we'll just ensure the UI is ready
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(multilingualChatProvider);
    final messages = ref.watch(chatMessagesProvider);
    final isLoading = ref.watch(isMultilingualChatLoadingProvider);
    final error = ref.watch(multilingualChatErrorProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Error banner
          if (error != null) _buildErrorBanner(error),

          // Chat messages
          Expanded(
            child: Stack(
              children: [
                _buildMessagesList(messages, isLoading),
                _buildScrollToBottomFab(),
              ],
            ),
          ),

          // Chat input
          AdvancedChatInput(
            onSendMessage: _sendMessage,
            onVoiceInput: _handleVoiceInput,
            onAttachment: _handleAttachment,
            suggestions: _getContextualSuggestions(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final currentLanguage = ref.watch(currentLanguageProvider);
    final availableLanguages = ref.watch(availableLanguagesProvider);

    final language = availableLanguages.firstWhere(
      (lang) => lang.code == currentLanguage,
      orElse: () => availableLanguages.first,
    );

    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      title: Row(
        children: [
          Hero(
            tag: 'ai_avatar',
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withValues(alpha:0.7),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.primary.withValues(alpha:0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AIVONITY Assistant',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Online',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      language.flag,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      language.code.split('-').first.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.language),
          onPressed: _showLanguageSettings,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'clear',
              child: ListTile(
                leading: Icon(Icons.clear_all),
                title: Text('Clear Chat'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.download),
                title: Text('Export Chat'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings),
                title: Text('Chat Settings'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
          onSelected: _handleMenuAction,
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.red.withValues(alpha:0.1),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(multilingualChatProvider.notifier).clearError();
            },
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(
      List<MultilingualChatMessage> messages, bool isLoading,) {
    if (messages.isEmpty && !isLoading) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: messages.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length && isLoading) {
          return const ContextualTypingIndicator(
            context: TypingContext.thinking,
          );
        }

        final message = messages[index];
        return MultilingualMessageWidget(
          key: ValueKey(message.id),
          message: message,
          showLanguageIndicator: true,
          showTranslationOption: true,
          showConfidence: true,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Hero(
            tag: 'empty_state_icon',
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withValues(alpha:0.7),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to AIVONITY Assistant',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'I\'m here to help with your vehicle needs.\nAsk me anything about maintenance, diagnostics, or service!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withValues(alpha:0.7),
                ),
          ),
          const SizedBox(height: 32),
          _buildQuickStartSuggestions(),
        ],
      ),
    );
  }

  Widget _buildQuickStartSuggestions() {
    final suggestions = [
      'Check my vehicle health',
      'Schedule maintenance',
      'Find service centers',
      'Fuel efficiency tips',
    ];

    return Column(
      children: [
        Text(
          'Try asking:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((suggestion) {
            return ActionChip(
              label: Text(suggestion),
              onPressed: () => _sendMessage(suggestion),
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha:0.1),
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary.withValues(alpha:0.3),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildScrollToBottomFab() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.small(
          onPressed: _scrollToBottom,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
        ),
      ),
    );
  }

  void _sendMessage(String message) {
    ref.read(multilingualChatProvider.notifier).sendMessage(message);
    _scrollToBottom();
  }

  void _handleVoiceInput(String text) {
    // Voice input is already handled by the input widget
    // Additional processing can be done here if needed
  }

  void _handleAttachment() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => _buildAttachmentSheet(),
    );
  }

  Widget _buildAttachmentSheet() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Attach Content',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            children: [
              _buildAttachmentOption(
                Icons.photo_camera,
                'Camera',
                () => _handleAttachmentType('camera'),
              ),
              _buildAttachmentOption(
                Icons.photo_library,
                'Gallery',
                () => _handleAttachmentType('gallery'),
              ),
              _buildAttachmentOption(
                Icons.description,
                'Document',
                () => _handleAttachmentType('document'),
              ),
              _buildAttachmentOption(
                Icons.location_on,
                'Location',
                () => _handleAttachmentType('location'),
              ),
              _buildAttachmentOption(
                Icons.qr_code_scanner,
                'QR Code',
                () => _handleAttachmentType('qr'),
              ),
              _buildAttachmentOption(
                Icons.directions_car,
                'Vehicle Info',
                () => _handleAttachmentType('vehicle'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption(
      IconData icon, String label, VoidCallback onTap,) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  void _handleAttachmentType(String type) {
    // Handle different attachment types
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type attachment feature coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<String> _getContextualSuggestions() {
    // Return contextual suggestions based on conversation history
    return [
      'Check vehicle health',
      'Schedule maintenance',
      'Find service centers',
      'Fuel efficiency tips',
      'Battery status',
      'Tire pressure check',
    ];
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showLanguageSettings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Language & Voice Settings',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: const LanguageSelectorWidget(
                      showAutoDetect: true,
                      compact: false,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'clear':
        _showClearConfirmation();
        break;
      case 'export':
        _exportChat();
        break;
      case 'settings':
        _showChatSettings();
        break;
    }
  }

  void _showClearConfirmation() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text(
            'Are you sure you want to clear all messages? This action cannot be undone.',),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(multilingualChatProvider.notifier).clearConversation();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _exportChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chat export feature coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showChatSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chat settings feature coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

