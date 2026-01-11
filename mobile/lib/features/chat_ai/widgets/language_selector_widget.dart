import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/services/multilingual_ai_chat_service.dart';

/// Language Selector Widget
/// Provides language selection interface for multilingual chat
class LanguageSelectorWidget extends ConsumerStatefulWidget {
  final Function(String)? onLanguageChanged;
  final bool showAutoDetect;
  final bool compact;

  const LanguageSelectorWidget({
    super.key,
    this.onLanguageChanged,
    this.showAutoDetect = true,
    this.compact = false,
  });

  @override
  ConsumerState<LanguageSelectorWidget> createState() =>
      _LanguageSelectorWidgetState();
}

class _LanguageSelectorWidgetState
    extends ConsumerState<LanguageSelectorWidget> {
  String _selectedLanguage = 'en-US';
  bool _autoDetectEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final localizationService = LocalizationService.instance;
    _selectedLanguage = localizationService.currentLanguage;
    _autoDetectEnabled = localizationService.autoDetectLanguage;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompactSelector();
    } else {
      return _buildFullSelector();
    }
  }

  Widget _buildCompactSelector() {
    final multilingualService = MultilingualAIChatService.instance;
    final languages = multilingualService.getSupportedLanguages();
    final currentLanguage = languages.firstWhere(
      (lang) => lang.code == _selectedLanguage,
      orElse: () => languages.first,
    );

    return PopupMenuButton<String>(
      itemBuilder: (context) => [
        if (widget.showAutoDetect)
          PopupMenuItem<String>(
            value: 'auto',
            child: Row(
              children: [
                Icon(
                  _autoDetectEnabled
                      ? Icons.auto_awesome
                      : Icons.auto_awesome_outlined,
                  size: 20,
                  color: _autoDetectEnabled ? Colors.blue : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'Auto-detect',
                  style: TextStyle(
                    fontWeight: _autoDetectEnabled ? FontWeight.w600 : null,
                    color: _autoDetectEnabled ? Colors.blue : null,
                  ),
                ),
              ],
            ),
          ),
        if (widget.showAutoDetect) const PopupMenuDivider(),
        ...languages.map((language) => PopupMenuItem<String>(
              value: language.code,
              child: Row(
                children: [
                  Text(language.flag, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          language.nativeName,
                          style: TextStyle(
                            fontWeight: _selectedLanguage == language.code
                                ? FontWeight.w600
                                : null,
                          ),
                        ),
                        Text(
                          language.name,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha:0.6),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedLanguage == language.code)
                    Icon(
                      Icons.check,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),),
      ],
      onSelected: _handleLanguageSelection,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha:0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentLanguage.flag,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 4),
            Text(
              currentLanguage.code.split('-').first.toUpperCase(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullSelector() {
    final multilingualService = MultilingualAIChatService.instance;
    final languages = multilingualService.getSupportedLanguages();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha:0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.language,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Language Settings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Auto-detect toggle
          if (widget.showAutoDetect) ...[
            SwitchListTile(
              title: const Text('Auto-detect language'),
              subtitle: const Text(
                  'Automatically detect the language of your messages',),
              value: _autoDetectEnabled,
              onChanged: _handleAutoDetectToggle,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
          ],

          // Language grid
          Text(
            'Select Language',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final language = languages[index];
              final isSelected = _selectedLanguage == language.code;

              return GestureDetector(
                onTap: () => _handleLanguageSelection(language.code),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary.withValues(alpha:0.1)
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha:0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        language.flag,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              language.nativeName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight:
                                        isSelected ? FontWeight.w600 : null,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              language.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha:0.6),
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleLanguageSelection(String? value) {
    if (value == null) return;

    if (value == 'auto') {
      _handleAutoDetectToggle(!_autoDetectEnabled);
      return;
    }

    setState(() {
      _selectedLanguage = value;
    });

    // Update services
    final localizationService = LocalizationService.instance;
    final multilingualService = MultilingualAIChatService.instance;

    localizationService.setLanguage(value);
    multilingualService.setConversationLanguage(value);

    // Notify parent
    widget.onLanguageChanged?.call(value);

    // Show confirmation
    _showLanguageChangeConfirmation(value);
  }

  void _handleAutoDetectToggle(bool enabled) {
    setState(() {
      _autoDetectEnabled = enabled;
    });

    final localizationService = LocalizationService.instance;
    localizationService.setAutoDetectLanguage(enabled);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled
              ? 'Auto-detect language enabled'
              : 'Auto-detect language disabled',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showLanguageChangeConfirmation(String languageCode) {
    final multilingualService = MultilingualAIChatService.instance;
    final languages = multilingualService.getSupportedLanguages();
    final language = languages.firstWhere(
      (lang) => lang.code == languageCode,
      orElse: () => languages.first,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(language.flag),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Language changed to ${language.nativeName}'),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Test',
          onPressed: () => _testLanguage(languageCode),
        ),
      ),
    );
  }

  void _testLanguage(String languageCode) {
    // Send a test message in the selected language
    final testMessages = {
      'en-US': 'Hello! How can I help you today?',
      'es-ES': '¡Hola! ¿Cómo puedo ayudarte hoy?',
      'fr-FR': 'Bonjour ! Comment puis-je vous aider aujourd\'hui ?',
      'de-DE': 'Hallo! Wie kann ich Ihnen heute helfen?',
      'it-IT': 'Ciao! Come posso aiutarti oggi?',
      'pt-BR': 'Olá! Como posso ajudá-lo hoje?',
      'zh-CN': '你好！今天我可以为您做些什么？',
      'ja-JP': 'こんにちは！今日はどのようにお手伝いできますか？',
      'ko-KR': '안녕하세요! 오늘 어떻게 도와드릴까요?',
    };

    final testMessage = testMessages[languageCode] ?? testMessages['en-US']!;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Language Test'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Test message in selected language:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                testMessage,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Language Status Indicator Widget
class LanguageStatusIndicator extends ConsumerWidget {
  final bool showDetectedLanguage;

  const LanguageStatusIndicator({
    super.key,
    this.showDetectedLanguage = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final multilingualService = MultilingualAIChatService.instance;
    final currentLanguage = multilingualService.currentConversationLanguage;
    final languages = multilingualService.getSupportedLanguages();

    final language = languages.firstWhere(
      (lang) => lang.code == currentLanguage,
      orElse: () => languages.first,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            language.flag,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            language.code.split('-').first.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

