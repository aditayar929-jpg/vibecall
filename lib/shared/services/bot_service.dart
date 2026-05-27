import 'dart:math';

/// Bot matching service — simulates real users for single-user experience.
///
/// When no real users are available, bots appear as matches with
/// realistic profiles, animated avatars, and chat responses.
class BotService {
  static final Random _random = Random();

  // ─── Bot Girl Profiles ──────────────────────────────────────
  static final List<Map<String, dynamic>> _botProfiles = [
    {
      'name': 'Aisha',
      'age': 22,
      'city': 'Mumbai',
      'bio': 'Love dancing & travel',
      'avatar': 'https://i.pravatar.cc/300?img=1',
      'interests': ['Dance', 'Travel', 'Music', 'Photography'],
    },
    {
      'name': 'Priya',
      'age': 24,
      'city': 'Delhi',
      'bio': 'Foodie & adventure seeker',
      'avatar': 'https://i.pravatar.cc/300?img=5',
      'interests': ['Cooking', 'Travel', 'Fitness', 'Fashion'],
    },
    {
      'name': 'Sneha',
      'age': 21,
      'city': 'Bangalore',
      'bio': 'Tech geek by day, dancer by night',
      'avatar': 'https://i.pravatar.cc/300?img=9',
      'interests': ['Tech', 'Dance', 'Gaming', 'Music'],
    },
    {
      'name': 'Ananya',
      'age': 23,
      'city': 'Pune',
      'bio': 'Bookworm with a wild side',
      'avatar': 'https://i.pravatar.cc/300?img=16',
      'interests': ['Reading', 'Yoga', 'Coffee', 'Art'],
    },
    {
      'name': 'Riya',
      'age': 20,
      'city': 'Jaipur',
      'bio': 'Living my best life',
      'avatar': 'https://i.pravatar.cc/300?img=20',
      'interests': ['Fashion', 'Travel', 'Photography', 'Music'],
    },
    {
      'name': 'Kavya',
      'age': 25,
      'city': 'Hyderabad',
      'bio': 'Singer & dreamer',
      'avatar': 'https://i.pravatar.cc/300?img=23',
      'interests': ['Music', 'Movies', 'Coffee', 'Nature'],
    },
    {
      'name': 'Meera',
      'age': 22,
      'city': 'Chennai',
      'bio': 'Classical dancer',
      'avatar': 'https://i.pravatar.cc/300?img=25',
      'interests': ['Dance', 'Art', 'Yoga', 'Nature'],
    },
    {
      'name': 'Tanya',
      'age': 21,
      'city': 'Kolkata',
      'bio': 'Cat mom & artist',
      'avatar': 'https://i.pravatar.cc/300?img=31',
      'interests': ['Art', 'Pets', 'Coffee', 'Photography'],
    },
    {
      'name': 'Nisha',
      'age': 23,
      'city': 'Ahmedabad',
      'bio': 'Gym freak & foodie',
      'avatar': 'https://i.pravatar.cc/300?img=32',
      'interests': ['Fitness', 'Cooking', 'Travel', 'Sports'],
    },
    {
      'name': 'Divya',
      'age': 24,
      'city': 'Chandigarh',
      'bio': 'Fashion designer in making',
      'avatar': 'https://i.pravatar.cc/300?img=44',
      'interests': ['Fashion', 'Art', 'Travel', 'Photography'],
    },
    {
      'name': 'Pooja',
      'age': 22,
      'city': 'Lucknow',
      'bio': 'Shayari lover',
      'avatar': 'https://i.pravatar.cc/300?img=45',
      'interests': ['Reading', 'Music', 'Movies', 'Coffee'],
    },
    {
      'name': 'Simran',
      'age': 20,
      'city': 'Amritsar',
      'bio': 'Punjabi kudi with big dreams',
      'avatar': 'https://i.pravatar.cc/300?img=47',
      'interests': ['Dance', 'Travel', 'Fitness', 'Music'],
    },
    {
      'name': 'Isha',
      'age': 26,
      'city': 'Noida',
      'bio': 'Startup life',
      'avatar': 'https://i.pravatar.cc/300?img=48',
      'interests': ['Tech', 'Coffee', 'Travel', 'Photography'],
    },
    {
      'name': 'Sakshi',
      'age': 21,
      'city': 'Indore',
      'bio': 'Singer & night owl',
      'avatar': 'https://i.pravatar.cc/300?img=49',
      'interests': ['Music', 'Movies', 'Cooking', 'Nature'],
    },
    {
      'name': 'Aditi',
      'age': 23,
      'city': 'Bhopal',
      'bio': 'Wanderlust',
      'avatar': 'https://i.pravatar.cc/300?img=50',
      'interests': ['Travel', 'Photography', 'Nature', 'Yoga'],
    },
  ];

  // ─── Chat Responses ─────────────────────────────────────────
  static final List<List<String>> _chatScripts = [
    // Script 1 — Friendly
    [
      "Heyy! How are you? 😊",
      "Oh nice! Where are you from?",
      "That's cool! I love that place",
      "Haha you're funny 😂",
      "What do you do for fun?",
      "Oh that's interesting!",
      "I love music too! What kind?",
      "Nice taste 🎵",
      "Do you travel a lot?",
      "We should totally meet sometime 😄",
    ],
    // Script 2 — Flirty
    [
      "Hey handsome 😘",
      "You look cute!",
      "Haha really? Tell me more",
      "I like your vibe ✨",
      "What's your favorite movie?",
      "Oh I love that one!",
      "You have good taste 😊",
      "Where do you hang out usually?",
      "Maybe we can go together sometime",
      "I'd love that 💕",
    ],
    // Script 3 — Curious
    [
      "Hi! 👋",
      "So what brings you here?",
      "Same here! Looking for new people",
      "That's awesome! What's your passion?",
      "Wow that's so cool!",
      "I'm into music and art",
      "Do you play any instruments?",
      "No way! I play guitar too 🎸",
      "We should jam together sometime 😄",
      "That would be so fun!",
    ],
    // Script 4 — Chill
    [
      "Hey! What's up?",
      "Not much, just chilling 😌",
      "Same here lol",
      "What's your go-to comfort food?",
      "Ooh good choice! I love pizza too 🍕",
      "Movie or series?",
      "Nice! What are you watching these days?",
      "I've been binging that too!",
      "No spoilers please 😂",
      "Haha my lips are sealed 🤐",
    ],
    // Script 5 — Energetic
    [
      "HEYY!! 🎉",
      "How's your day going?",
      "Mine's been amazing!",
      "I went to this cool cafe today",
      "You should totally check it out!",
      "The coffee was ☕🤌",
      "Do you like coffee?",
      "We should go together sometime!",
      "I know all the best spots 😎",
      "It's a date then! 😉",
    ],
  ];

  // ─── Get a random bot profile ───────────────────────────────
  static Map<String, dynamic> getRandomBot({String genderFilter = 'All'}) {
    final bot = Map<String, dynamic>.from(
      _botProfiles[_random.nextInt(_botProfiles.length)],
    );
    bot['uid'] = 'bot_${DateTime.now().millisecondsSinceEpoch}';
    bot['isBot'] = true;
    return bot;
  }

  // ─── Get a random chat script ───────────────────────────────
  static List<String> getRandomChatScript() {
    return List<String>.from(
      _chatScripts[_random.nextInt(_chatScripts.length)],
    );
  }

  // ─── Simulate typing delay ──────────────────────────────────
  static Duration getTypingDelay() {
    return Duration(seconds: 2 + _random.nextInt(4));
  }

  // ─── Simulate call duration before "disconnect" ─────────────
  static Duration getCallDuration() {
    return Duration(seconds: 15 + _random.nextInt(45));
  }

  // ─── Get "next bot" after skip ──────────────────────────────
  static Map<String, dynamic> getNextBot({
    required String excludeName,
    String genderFilter = 'All',
  }) {
    final available = _botProfiles.where((b) => b['name'] != excludeName).toList();
    final bot = Map<String, dynamic>.from(
      available[_random.nextInt(available.length)],
    );
    bot['uid'] = 'bot_${DateTime.now().millisecondsSinceEpoch}';
    bot['isBot'] = true;
    return bot;
  }

  // ─── Simulate "online" users count ──────────────────────────
  static int getSimulatedOnlineCount() {
    // Random between 30-150 to make it feel alive
    return 30 + _random.nextInt(120);
  }

  // ─── Bot reaction messages (during call) ────────────────────
  static final List<String> _reactions = [
    "😂", "😊", "❤️", "😍", "🥰", "✨", "💕", "😘", "🙈", "🎉",
  ];

  static String getRandomReaction() {
    return _reactions[_random.nextInt(_reactions.length)];
  }
}
