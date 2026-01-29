/// Turn Actions Model - D&D 5e action economy tracking
class TurnActions {
  bool actionUsed;
  bool bonusActionUsed;
  int movementRemaining;
  bool reactionUsed;

  TurnActions({
    this.actionUsed = false,
    this.bonusActionUsed = false,
    this.movementRemaining = 6,
    this.reactionUsed = false,
  });

  factory TurnActions.fromJson(Map<String, dynamic> json) => TurnActions(
        actionUsed: json['actionUsed'] ?? false,
        bonusActionUsed: json['bonusActionUsed'] ?? false,
        movementRemaining: json['movementRemaining'] ?? 6,
        reactionUsed: json['reactionUsed'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'actionUsed': actionUsed,
        'bonusActionUsed': bonusActionUsed,
        'movementRemaining': movementRemaining,
        'reactionUsed': reactionUsed,
      };

  bool get hasActionsRemaining =>
      !actionUsed || !bonusActionUsed || movementRemaining > 0;
}
