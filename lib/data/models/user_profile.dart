// lib/data/models/user_profile.dart

class UserProfile {
  final String id;
  final String username;
  final String? email;
  final String? avatarUrl;
  final String? bio;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Gamification & Engagement
  final int level;
  final int experience;
  final int totalPlants;
  final int completedGrows;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivity;
  final List<String> achievements;
  final Map<String, dynamic> statistics;
  final Map<String, dynamic> preferences;

  UserProfile({
    required this.id,
    required this.username,
    this.email,
    this.avatarUrl,
    this.bio,
    required this.createdAt,
    required this.updatedAt,
    this.level = 1,
    this.experience = 0,
    this.totalPlants = 0,
    this.completedGrows = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActivity,
    this.achievements = const [],
    this.statistics = const {},
    this.preferences = const {},
  });

  // Experience thresholds for levels
  static int getExperienceForLevel(int level) {
    return (level * 100) + ((level - 1) * 50); // Progressive system
  }

  // Calculate level from experience
  static int getLevelFromExperience(int experience) {
    int level = 1;
    while (experience >= getExperienceForLevel(level + 1)) {
      level++;
    }
    return level;
  }

  // Experience needed for next level
  int get experienceToNextLevel {
    final nextLevel = level + 1;
    return getExperienceForLevel(nextLevel) - experience;
  }

  // Progress to next level (0.0 - 1.0)
  double get levelProgress {
    if (level == 1) {
      return experience / getExperienceForLevel(2).toDouble();
    }

    final currentLevelExp = getExperienceForLevel(level);
    final nextLevelExp = getExperienceForLevel(level + 1);
    final progressExp = experience - currentLevelExp;
    final totalExpNeeded = nextLevelExp - currentLevelExp;

    return (progressExp / totalExpNeeded).clamp(0.0, 1.0);
  }

  // User rank based on experience (for social proof)
  String get rankTitle {
    if (level >= 50) return 'Grow Master';
    if (level >= 30) return 'Expert Grower';
    if (level >= 20) return 'Advanced Grower';
    if (level >= 10) return 'Experienced Grower';
    if (level >= 5) return 'Green Thumb';
    return 'Seed Starter';
  }

  // Days since registration
  int get memberForDays {
    return DateTime.now().difference(createdAt).inDays;
  }

  // Average grow success rate
  double get successRate {
    if (totalPlants == 0) return 0.0;
    return (completedGrows / totalPlants * 100).clamp(0.0, 100.0);
  }

  // Most grown plant type from statistics
  String get favoritePlantType {
    final plantTypes = statistics['plantTypeCount'] as Map<String, dynamic>?;
    if (plantTypes == null || plantTypes.isEmpty) return 'Noch keine';

    String favorite = plantTypes.keys.first;
    int maxCount = 0;

    for (final entry in plantTypes.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        favorite = entry.key;
      }
    }

    return favorite;
  }

  UserProfile copyWith({
    String? username,
    String? email,
    String? avatarUrl,
    String? bio,
    int? level,
    int? experience,
    int? totalPlants,
    int? completedGrows,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActivity,
    List<String>? achievements,
    Map<String, dynamic>? statistics,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfile(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      level: level ?? this.level,
      experience: experience ?? this.experience,
      totalPlants: totalPlants ?? this.totalPlants,
      completedGrows: completedGrows ?? this.completedGrows,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActivity: lastActivity ?? this.lastActivity,
      achievements: achievements ?? this.achievements,
      statistics: statistics ?? this.statistics,
      preferences: preferences ?? this.preferences,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatar_url': avatarUrl,
      'bio': bio,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'level': level,
      'experience': experience,
      'total_plants': totalPlants,
      'completed_grows': completedGrows,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_activity': lastActivity?.toIso8601String(),
      'achievements': achievements,
      'statistics': statistics,
      'preferences': preferences,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      level: json['level'] as int? ?? 1,
      experience: json['experience'] as int? ?? 0,
      totalPlants: json['total_plants'] as int? ?? 0,
      completedGrows: json['completed_grows'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastActivity: json['last_activity'] != null
          ? DateTime.parse(json['last_activity'] as String)
          : null,
      achievements: List<String>.from(json['achievements'] ?? []),
      statistics: Map<String, dynamic>.from(json['statistics'] ?? {}),
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
    );
  }
}

// Achievement System
class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final String category;
  final int requiredValue;
  final String type; // 'count', 'streak', 'milestone'
  final bool isRare;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.category,
    required this.requiredValue,
    required this.type,
    this.isRare = false,
  });

  static List<Achievement> get allAchievements => [
        // Plant Count Achievements
        Achievement(
          id: 'first_plant',
          title: 'Erster Spross',
          description: 'Deine erste Pflanze hinzugefügt',
          iconName: 'eco',
          category: 'Pflanzen',
          requiredValue: 1,
          type: 'count',
        ),
        Achievement(
          id: 'plant_collector',
          title: 'Pflanzen-Sammler',
          description: '10 Pflanzen insgesamt',
          iconName: 'nature',
          category: 'Pflanzen',
          requiredValue: 10,
          type: 'count',
        ),
        Achievement(
          id: 'greenhouse_master',
          title: 'Gewächshaus-Meister',
          description: '50 Pflanzen insgesamt',
          iconName: 'park',
          category: 'Pflanzen',
          requiredValue: 50,
          type: 'count',
          isRare: true,
        ),

        // Completion Achievements
        Achievement(
          id: 'first_harvest',
          title: 'Erste Ernte',
          description: 'Deinen ersten Grow abgeschlossen',
          iconName: 'agriculture',
          category: 'Ernte',
          requiredValue: 1,
          type: 'completed',
        ),
        Achievement(
          id: 'serial_grower',
          title: 'Serien-Grower',
          description: '5 Grows erfolgreich abgeschlossen',
          iconName: 'trending_up',
          category: 'Ernte',
          requiredValue: 5,
          type: 'completed',
        ),
        Achievement(
          id: 'harvest_master',
          title: 'Ernte-Meister',
          description: '25 Grows erfolgreich abgeschlossen',
          iconName: 'workspace_premium',
          category: 'Ernte',
          requiredValue: 25,
          type: 'completed',
          isRare: true,
        ),

        // Streak Achievements
        Achievement(
          id: 'consistent_gardener',
          title: 'Konstanter Gärtner',
          description: '7 Tage Streak',
          iconName: 'local_fire_department',
          category: 'Streak',
          requiredValue: 7,
          type: 'streak',
        ),
        Achievement(
          id: 'dedicated_grower',
          title: 'Hingebungsvoller Grower',
          description: '30 Tage Streak',
          iconName: 'whatshot',
          category: 'Streak',
          requiredValue: 30,
          type: 'streak',
          isRare: true,
        ),

        // Special Achievements
        Achievement(
          id: 'early_adopter',
          title: '🌱 Early Adopter',
          description: 'Einer der ersten GrowTracker-Nutzer',
          iconName: 'stars',
          category: 'Spezial',
          requiredValue: 1,
          type: 'milestone',
          isRare: true,
        ),
        Achievement(
          id: 'diversity_lover',
          title: 'Vielfalt-Liebhaber',
          description: '5 verschiedene Pflanzenarten angebaut',
          iconName: 'diversity_3',
          category: 'Spezial',
          requiredValue: 5,
          type: 'diversity',
        ),
      ];

  static Achievement? getById(String id) {
    try {
      return allAchievements.firstWhere((achievement) => achievement.id == id);
    } catch (e) {
      return null;
    }
  }
}
