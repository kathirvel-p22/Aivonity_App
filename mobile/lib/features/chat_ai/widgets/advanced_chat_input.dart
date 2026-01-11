import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/enhanced_voice_input_widget.dart';
import '../widgets/language_selector_widget.dart';

/// Advanced Chat Input Widget
/// Sophisticated input interface with voice, attachments, suggestions, and rich formatting
class AdvancedChatInput extends ConsumerStatefulWidget {
  final Function(String)? onSendMessage;
  final Function(String)? onVoiceInput;
  final VoidCallback? onAttachment;
  final bool showVoiceButton;
  final bool showAttachmentButton;
  final bool showLanguageSelector;
  final bool showSuggestions;
  final List<String> suggestions;
  final String? placeholder;
  final int maxLines;

  const AdvancedChatInput({
    super.key,
    this.onSendMessage,
    this.onVoiceInput,
    this.onAttachment,
    this.showVoiceButton = true,
    this.showAttachmentButton = true,
    this.showLanguageSelector = true,
    this.showSuggestions = true,
    this.suggestions = const [],
    this.placeholder,
    this.maxLines = 5,
  });

  @override
  ConsumerState<AdvancedChatInput> createState() => _AdvancedChatInputState();
}

class _AdvancedChatInputState extends ConsumerState<AdvancedChatInput>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late AnimationController _expandController;
  late AnimationController _sendButtonController;
  late Animation<double> _expandAnimation;
  late Animation<double> _sendButtonAnimation;

  bool _isExpanded = false;
  bool _showSuggestions = false;
  List<String> _filteredSuggestions = [];

  final List<String> _defaultSuggestions = [
    'Check vehicle health',
    'Schedule maintenance',
    'Find service centers',
    'Fuel efficiency tips',
    'Troubleshoot issues',
    'Battery status',
    'Tire pressure',
    'Engine diagnostics',
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupListeners();
  }

  void _setupAnimations() {
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _expandAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    ),);

    _sendButtonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sendButtonController,
      curve: Curves.elasticOut,
    ),);
  }

  void _setupListeners() {
    _textController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;

    if (hasText && !_sendButtonController.isCompleted) {
      _sendButtonController.forward();
    } else if (!hasText && _sendButtonController.isCompleted) {
      _sendButtonController.reverse();
    }

    _updateSuggestions();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _expandController.forward();
      setState(() {
        _isExpanded = true;
        _showSuggestions = widget.showSuggestions;
      });
    } else {
      _expandController.reverse();
      setState(() {
        _isExpanded = false;
        _showSuggestions = false;
      });
    }
  }

  void _updateSuggestions() {
    final query = _textController.text.toLowerCase();
    final allSuggestions = widget.suggestions.isNotEmpty
        ? widget.suggestions
        : _defaultSuggestions;

    setState(() {
      _filteredSuggestions = query.isEmpty
          ? allSuggestions.take(4).toList()
          : allSuggestions
              .where((suggestion) => suggestion.toLowerCase().contains(query))
              .take(4)
              .toList();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _expandController.dispose();
    _sendButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Suggestions
            if (_showSuggestions && _filteredSuggestions.isNotEmpty)
              _buildSuggestions(),

            // Main input area
            _buildInputArea(),

            // Expanded features
            AnimatedBuilder(
              animation: _expandAnimation,
              builder: (context, child) {
                return SizeTransition(
                  sizeFactor: _expandAnimation,
                  child: _buildExpandedFeatures(),
                );
              },
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
        itemCount: _filteredSuggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _filteredSuggestions[index];
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(suggestion),
              onPressed: () => _selectSuggestion(suggestion),
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha:0.1),
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary.withValues(alpha:0.3),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Voice input button
          if (widget.showVoiceButton)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: EnhancedVoiceInputWidget(
                onVoiceInput: (text) {
                  _textController.text = text;
                  widget.onVoiceInput?.call(text);
                },
              ),
            ),

          // Text input field
          Expanded(child: _buildTextField()),

          const SizedBox(width: 8),

          // Send button
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildTextField() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: widget.maxLines * 24.0,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _focusNode.hasFocus
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withValues(alpha:0.3),
          width: _focusNode.hasFocus ? 2 : 1,
        ),
      ),
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        maxLines: null,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: widget.placeholder ??
              'Type your message or ask about your vehicle...',
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.5),
              ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          suffixIcon: _buildTextFieldActions(),
        ),
        onSubmitted: _sendMessage,
      ),
    );
  }

  Widget? _buildTextFieldActions() {
    if (!_isExpanded) return null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Attachment button
        if (widget.showAttachmentButton)
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: widget.onAttachment,
            iconSize: 20,
          ),

        // Formatting button
        IconButton(
          icon: const Icon(Icons.format_bold),
          onPressed: _showFormattingOptions,
          iconSize: 20,
        ),
      ],
    );
  }

  Widget _buildSendButton() {
    return AnimatedBuilder(
      animation: _sendButtonAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _sendButtonAnimation.value,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withValues(alpha:0.8),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha:0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _textController.text.trim().isNotEmpty
                    ? () => _sendMessage(_textController.text)
                    : null,
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpandedFeatures() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Language selector
          if (widget.showLanguageSelector)
            const LanguageSelectorWidget(compact: true),

          const Spacer(),

          // Quick actions
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _buildQuickActionButton(
          Icons.health_and_safety,
          'Health Check',
          () => _insertQuickText('Check my vehicle health'),
        ),
        _buildQuickActionButton(
          Icons.build,
          'Maintenance',
          () => _insertQuickText('Schedule maintenance'),
        ),
        _buildQuickActionButton(
          Icons.location_on,
          'Service Centers',
          () => _insertQuickText('Find service centers near me'),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    IconData icon,
    String tooltip,
    VoidCallback onTap,
  ) {
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        child: Material(
          color: Theme.of(context).colorScheme.primary.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                icon,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectSuggestion(String suggestion) {
    _textController.text = suggestion;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    _focusNode.requestFocus();
  }

  void _insertQuickText(String text) {
    final currentText = _textController.text;
    final newText = currentText.isEmpty ? text : '$currentText $text';

    _textController.text = newText;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: newText.length),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    widget.onSendMessage?.call(text.trim());
    _textController.clear();
    _focusNode.unfocus();

    // Haptic feedback
    HapticFeedback.lightImpact();
  }

  void _showFormattingOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => _buildFormattingSheet(),
    );
  }

  Widget _buildFormattingSheet() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Text Formatting',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFormattingChip(
                  '**Bold**', () => _insertFormatting('**', '**'),),
              _buildFormattingChip(
                  '_Italic_', () => _insertFormatting('_', '_'),),
              _buildFormattingChip('`Code`', () => _insertFormatting('`', '`')),
              _buildFormattingChip(
                  '• Bullet', () => _insertFormatting('• ', ''),),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Quick Templates',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...['Vehicle Issue Report', 'Maintenance Request', 'Service Feedback']
              .map((template) => ListTile(
                    title: Text(template),
                    onTap: () {
                      Navigator.pop(context);
                      _insertTemplate(template);
                    },
                  ),),
        ],
      ),
    );
  }

  Widget _buildFormattingChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _insertFormatting(String prefix, String suffix) {
    final selection = _textController.selection;
    final text = _textController.text;

    if (selection.isValid) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$prefix$selectedText$suffix',
      );

      _textController.text = newText;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(
            offset: selection.start +
                prefix.length +
                selectedText.length +
                suffix.length,),
      );
    }
  }

  void _insertTemplate(String template) {
    String templateText = '';

    switch (template) {
      case 'Vehicle Issue Report':
        templateText = '''**Issue Description:**
What problem are you experiencing?

**When did it start:**
When did you first notice this issue?

**Frequency:**
How often does this happen?

**Additional Details:**
Any other relevant information?''';
        break;
      case 'Maintenance Request':
        templateText = '''**Service Type:**
What type of maintenance do you need?

**Preferred Date:**
When would you like to schedule this?

**Special Requirements:**
Any specific requests or concerns?''';
        break;
      case 'Service Feedback':
        templateText = '''**Service Center:**
Which service center did you visit?

**Service Date:**
When was the service performed?

**Rating:**
How would you rate the service? (1-5 stars)

**Comments:**
Additional feedback or suggestions?''';
        break;
    }

    _textController.text = templateText;
    _focusNode.requestFocus();
  }
}

