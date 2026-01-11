import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../database/database_helper.dart';
import 'fcm_service.dart';

/// Multi-channel communication service supporting push, email, and SMS
class MultiChannelService {
  static final MultiChannelService _instance = MultiChannelService._internal();
  factory MultiChannelService() => _instance;
  MultiChannelService._internal();

  final FCMService _fcmService = FCMService();
  final DatabaseHelper _db = DatabaseHelper();

  // Service configurations
  late SendGridConfig _sendGridConfig;
  late TwilioConfig _twilioConfig;

  bool _isInitialized = false;
  final List<CommunicationChannel> _enabledChannels = [];

  /// Initialize multi-channel service
  Future<void> initialize({
    required SendGridConfig sendGridConfig,
    required TwilioConfig twilioConfig,
  }) async {
    if (_isInitialized) return;

    _sendGridConfig = sendGridConfig;
    _twilioConfig = twilioConfig;

    await _fcmService.initialize();
    _setupEnabledChannels();

    _isInitialized = true;
  }

  /// Send notification through multiple channels
  Future<MultiChannelResult> sendNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationCategory category,
    List<CommunicationChannel> channels = const [CommunicationChannel.push],
    Map<String, dynamic>? data,
  }) async {
    final results = <CommunicationChannel, ChannelResult>{};

    for (final channel in channels) {
      try {
        ChannelResult result = await _sendChannelNotification(
          channel: channel,
          userId: userId,
          title: title,
          message: message,
          category: category,
          data: data,
        );

        results[channel] = result;
      } catch (e) {
        results[channel] = ChannelResult.error(e.toString());
        debugPrint('Failed to send notification via $channel: $e');
      }
    }

    return MultiChannelResult(
      results: results,
      totalChannels: channels.length,
      successfulChannels: results.values.where((r) => r.success).length,
    );
  }

  /// Send email notification
  Future<ChannelResult> sendEmail({
    required String toEmail,
    required String subject,
    required String htmlContent,
    String? textContent,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.sendgrid.com/v3/mail/send'),
        headers: {
          'Authorization': 'Bearer ${_sendGridConfig.apiKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'personalizations': [
            {
              'to': [
                {'email': toEmail},
              ],
              'subject': subject,
            },
          ],
          'from': {
            'email': _sendGridConfig.fromEmail,
            'name': _sendGridConfig.fromName,
          },
          'content': [
            if (textContent != null)
              {'type': 'text/plain', 'value': textContent},
            {'type': 'text/html', 'value': htmlContent},
          ],
        }),
      );

      if (response.statusCode == 202) {
        return ChannelResult.success(
          messageId: response.headers['x-message-id'],
          deliveredAt: DateTime.now(),
        );
      } else {
        return ChannelResult.error(
          'SendGrid API error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      return ChannelResult.error('Email send failed: $e');
    }
  }

  /// Send SMS notification
  Future<ChannelResult> sendSMS({
    required String toPhoneNumber,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://api.twilio.com/2010-04-01/Accounts/${_twilioConfig.accountSid}/Messages.json',
        ),
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('${_twilioConfig.accountSid}:${_twilioConfig.authToken}'))}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': _twilioConfig.fromPhoneNumber,
          'To': toPhoneNumber,
          'Body': message,
        },
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return ChannelResult.success(
          messageId: responseData['sid'],
          deliveredAt: DateTime.now(),
        );
      } else {
        return ChannelResult.error(
          'Twilio API error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      return ChannelResult.error('SMS send failed: $e');
    }
  }

  // Private methods

  void _setupEnabledChannels() {
    _enabledChannels.clear();
    _enabledChannels.add(CommunicationChannel.push);

    if (_sendGridConfig.apiKey.isNotEmpty) {
      _enabledChannels.add(CommunicationChannel.email);
    }

    if (_twilioConfig.accountSid.isNotEmpty &&
        _twilioConfig.authToken.isNotEmpty) {
      _enabledChannels.add(CommunicationChannel.sms);
    }
  }

  Future<ChannelResult> _sendChannelNotification({
    required CommunicationChannel channel,
    required String userId,
    required String title,
    required String message,
    required NotificationCategory category,
    Map<String, dynamic>? data,
  }) async {
    switch (channel) {
      case CommunicationChannel.push:
        await _fcmService.sendLocalNotification(
          title: title,
          body: message,
          category: category,
          data: data,
        );
        return ChannelResult.success(deliveredAt: DateTime.now());

      case CommunicationChannel.email:
        final userEmail = await _getUserEmail(userId);
        if (userEmail == null) {
          return ChannelResult.error('User email not found');
        }

        final htmlContent = _generateDefaultEmailContent(title, message);

        return await sendEmail(
          toEmail: userEmail,
          subject: title,
          htmlContent: htmlContent,
          textContent: message,
        );

      case CommunicationChannel.sms:
        final userPhone = await _getUserPhoneNumber(userId);
        if (userPhone == null) {
          return ChannelResult.error('User phone number not found');
        }

        return await sendSMS(
          toPhoneNumber: userPhone,
          message: '$title: $message',
        );

      case CommunicationChannel.inApp:
        // Store for in-app notification center
        return ChannelResult.success(deliveredAt: DateTime.now());
    }
  }

  Future<String?> _getUserEmail(String userId) async {
    // Load user email from database
    return 'user@example.com'; // Placeholder
  }

  Future<String?> _getUserPhoneNumber(String userId) async {
    // Load user phone number from database
    return '+1234567890'; // Placeholder
  }

  String _generateDefaultEmailContent(String title, String message) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <title>$title</title>
    </head>
    <body style="font-family: Arial, sans-serif; margin: 0; padding: 20px;">
        <div style="max-width: 600px; margin: 0 auto;">
            <h1 style="color: #1976D2;">$title</h1>
            <p style="font-size: 16px; line-height: 1.5;">$message</p>
            <hr style="margin: 20px 0;">
            <p style="font-size: 12px; color: #666;">
                This message was sent from your AIVONITY Vehicle Assistant.
            </p>
        </div>
    </body>
    </html>
    ''';
  }
}

/// Communication channels
enum CommunicationChannel { push, email, sms, inApp }

/// SendGrid configuration
class SendGridConfig {
  final String apiKey;
  final String fromEmail;
  final String fromName;

  SendGridConfig({
    required this.apiKey,
    required this.fromEmail,
    required this.fromName,
  });
}

/// Twilio configuration
class TwilioConfig {
  final String accountSid;
  final String authToken;
  final String fromPhoneNumber;

  TwilioConfig({
    required this.accountSid,
    required this.authToken,
    required this.fromPhoneNumber,
  });
}

/// Channel delivery result
class ChannelResult {
  final bool success;
  final String? messageId;
  final DateTime? deliveredAt;
  final String? errorMessage;

  ChannelResult({
    required this.success,
    this.messageId,
    this.deliveredAt,
    this.errorMessage,
  });

  factory ChannelResult.success({String? messageId, DateTime? deliveredAt}) {
    return ChannelResult(
      success: true,
      messageId: messageId,
      deliveredAt: deliveredAt,
    );
  }

  factory ChannelResult.error(String errorMessage) {
    return ChannelResult(success: false, errorMessage: errorMessage);
  }
}

/// Multi-channel delivery result
class MultiChannelResult {
  final Map<CommunicationChannel, ChannelResult> results;
  final int totalChannels;
  final int successfulChannels;

  MultiChannelResult({
    required this.results,
    required this.totalChannels,
    required this.successfulChannels,
  });

  bool get allSuccessful => successfulChannels == totalChannels;
  bool get anySuccessful => successfulChannels > 0;
  double get successRate =>
      totalChannels > 0 ? successfulChannels / totalChannels : 0.0;
}

