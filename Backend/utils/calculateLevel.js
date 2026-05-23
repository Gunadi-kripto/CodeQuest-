function calculateLevel(totalXp = 0) {
  const xp = Number(totalXp) || 0;

  const milestones = [0, 100, 500, 800, 1200, 2000, 3000];

  for (let i = 0; i < milestones.length - 1; i++) {
    const next = milestones[i + 1];

    if (xp < next) {
      return i + 1;
    }
  }

  const extraXp = xp - 3000;
  const extraLevel = Math.floor(extraXp / 1000);

  return 7 + extraLevel;
}

module.exports = calculateLevel;