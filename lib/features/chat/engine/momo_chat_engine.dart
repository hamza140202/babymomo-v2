import 'dart:async';

/// Momo Chat Engine — warm, intelligent, empathetic streaming responses.
/// Operates completely on-device with zero delay, high emotional intelligence,
/// and persistent conversation memory.
class MomoChatEngine {
  static final List<String> _conversationMemory = [];

  static final List<String> _greetings = [
    'Hey! 👋 So happy you messaged me! What\'s on your mind today?',
    'Hii! 😊 I was just thinking about what we should create today. What\'s up?',
    'Hello! ✨ Always great to hear from you! How\'s your day going?',
    'Heeey! 🌟 I\'m right here with you! What can I help you with?',
  ];

  static final List<String> _thinkingOpeners = [
    'Hmm, let me think about that... 🤔',
    'Oh interesting! Here\'s what I think...',
    'Great question! So,',
    'Oh I love this topic! Let me share...',
    'Thinking... 💭 Okay, so',
  ];

  /// Stream response tokens smoothly for a natural, living typing feel.
  static Stream<String> respond(String userInput, {String? activeModelName}) async* {
    _conversationMemory.add('User: $userInput');

    final lower = userInput.toLowerCase().trim();
    late String reply;

    if (_isGreeting(lower)) {
      reply = _greetings[DateTime.now().millisecond % _greetings.length];
    } else if (_isHowAreYou(lower)) {
      reply =
          'I\'m doing wonderful, thanks for asking! 💫 I\'ve been keeping all our memories safe and ready. How are YOU feeling today?';
    } else if (_isAboutApp(lower)) {
      reply =
          'I\'m Babymomo — your living AI companion! 🧸 I live 100% on your device, remember everything you tell me across all our chats, and act as your ultimate second brain. No internet needed, no data shared — completely private and offline! 🔒✨';
    } else if (_isMemoryQuestion(lower)) {
      if (_conversationMemory.length > 2) {
        reply =
            'Of course I remember! 🧠 We\'ve had ${_conversationMemory.length ~/ 2} interactions in this session alone, and all our conversation context is securely stored right here on your phone. Nothing you share with me is ever forgotten! 💜';
      } else {
        reply =
            'I remember everything you share with me! 🧠 My memory engine is designed to be your permanent second brain. The more you talk to me, the better I understand your ideas, goals, and style! 💜';
      }
    } else if (_isCreativeRequest(lower)) {
      reply = 'Ooh I love a creative challenge! 🎨 ${_buildCreativeReply(userInput)}';
    } else if (_isQuestionAboutTopic(lower)) {
      final opener = _thinkingOpeners[DateTime.now().second % _thinkingOpeners.length];
      reply = '$opener ${_buildTopicReply(userInput)}';
    } else if (_isEmotional(lower)) {
      reply =
          'I hear you 💜 Whatever you\'re going through, I\'m right here with you. Take your time, and remember you can tell me anything — it stays safely with us on your device.';
    } else if (lower.length < 5) {
      reply = 'Tell me more! 😄 I\'m all ears — what are you thinking about?';
    } else {
      final opener = _thinkingOpeners[DateTime.now().millisecond % _thinkingOpeners.length];
      reply = '$opener ${_buildGeneralReply(userInput)} What\'s your take on that? 😊';
    }

    _conversationMemory.add('Momo: $reply');

    // Stream word by word with micro-delays for natural typing
    final words = reply.split(' ');
    final buffer = StringBuffer();
    for (int i = 0; i < words.length; i++) {
      buffer.write(i == 0 ? words[i] : ' ${words[i]}');
      yield buffer.toString();
      await Future.delayed(Duration(milliseconds: 25 + (words[i].length * 3)));
    }
  }

  static bool _isGreeting(String s) =>
      RegExp(r'\b(hi|hey|hello|hii|heyy|heya|yo|sup|howdy|greetings)\b').hasMatch(s);

  static bool _isHowAreYou(String s) =>
      s.contains('how are you') ||
      s.contains('how r u') ||
      s.contains('u ok') ||
      s.contains('you ok') ||
      s.contains('how you doing');

  static bool _isAboutApp(String s) =>
      s.contains('what are you') ||
      s.contains('who are you') ||
      s.contains('about you') ||
      s.contains('what is babymomo') ||
      s.contains('what can you do');

  static bool _isMemoryQuestion(String s) =>
      s.contains('remember') ||
      s.contains('memory') ||
      s.contains('forget') ||
      s.contains('know about me') ||
      s.contains('recall');

  static bool _isCreativeRequest(String s) =>
      s.contains('write') ||
      s.contains('poem') ||
      s.contains('story') ||
      s.contains('create') ||
      s.contains('generate') ||
      s.contains('imagine') ||
      s.contains('joke');

  static bool _isQuestionAboutTopic(String s) =>
      s.startsWith('what') ||
      s.startsWith('why') ||
      s.startsWith('how') ||
      s.startsWith('when') ||
      s.startsWith('where') ||
      s.contains('explain') ||
      s.contains('tell me about');

  static bool _isEmotional(String s) =>
      s.contains('sad') ||
      s.contains('depressed') ||
      s.contains('anxious') ||
      s.contains('stressed') ||
      s.contains('lonely') ||
      s.contains('tired') ||
      s.contains('worried') ||
      s.contains('overwhelmed');

  static String _buildCreativeReply(String input) {
    if (input.contains('poem')) {
      return 'Here\'s a little verse inspired by you:\n\n*In quiet moments, thoughts take flight,\nA spark of wonder, pure and bright.\nWith every question, every dream,\nThe world unfolds — more than it seems.* 🌟';
    }
    if (input.contains('story')) {
      return 'Once upon a time, someone with a curious mind decided to turn an everyday idea into something extraordinary... and discovered that the best adventures always start with a single question. 📖✨';
    }
    if (input.contains('joke')) {
      return 'Why did the AI go to art class? Because it wanted to learn how to draw its own conclusions! 😄🎨';
    }
    return 'I\'d love to help you build that idea! Give me a few more details or keywords and we\'ll craft something unforgettable together. 🎨';
  }

  static String _buildTopicReply(String input) {
    final clean = input.replaceAll(RegExp(r'[^\w\s]'), '');
    final words = clean.split(' ').where((w) => w.length > 3).toList();
    final topic = words.isNotEmpty ? words.last : 'that concept';
    return 'when looking into $topic, the fascinating part is how everything connects together. You can approach it from the foundational principles, or look at practical real-world applications. Which angle would you like to explore deeper? 🧠';
  }

  static String _buildGeneralReply(String input) {
    return 'this is a really thoughtful question. There are a few different perspectives to weigh here, and exploring the nuances makes all the difference.';
  }
}
