class XpLevelInfo {
  final int level;
  final int currentXp;
  final int nextTargetXp;
  final double progress;
  final String nextLabel;
  final bool isPro;

  XpLevelInfo({
    required this.level,
    required this.currentXp,
    required this.nextTargetXp,
    required this.progress,
    required this.nextLabel,
    required this.isPro,
  });
}

class XpLevelHelper {
  static XpLevelInfo calculate(int totalXp) {
    final int xp = totalXp < 0 ? 0 : totalXp;

    final List<int> milestones = [
      100,
      500,
      800,
      1200,
      2000,
      3000,
    ];

    if (xp >= 3000) {
      return XpLevelInfo(
        level: 7,
        currentXp: xp,
        nextTargetXp: 3000,
        progress: 1.0,
        nextLabel: 'Anda sudah sangat pro dalam CodeQuest',
        isPro: true,
      );
    }

    int previousTarget = 0;

    for (int i = 0; i < milestones.length; i++) {
      final int target = milestones[i];

      if (xp < target) {
        final int level = i + 1;
        final int range = target - previousTarget;
        final int currentRangeXp = xp - previousTarget;
        final int sisaXp = target - xp;

        return XpLevelInfo(
          level: level,
          currentXp: xp,
          nextTargetXp: target,
          progress: (currentRangeXp / range).clamp(0.0, 1.0),
          nextLabel: '$sisaXp XP lagi ke target $target XP',
          isPro: false,
        );
      }

      previousTarget = target;
    }

    return XpLevelInfo(
      level: 7,
      currentXp: xp,
      nextTargetXp: 3000,
      progress: 1.0,
      nextLabel: 'Anda sudah sangat pro dalam CodeQuest',
      isPro: true,
    );
  }
}