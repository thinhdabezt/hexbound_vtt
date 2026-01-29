import 'package:flutter/material.dart';
import '../models/turn_actions.dart';

class CombatOverlay extends StatelessWidget {
  final List<String> combatLog;
  final List<String> turnOrder;
  final Map<String, int> initiativeRolls;
  final int currentTurnIndex;
  final bool isActive;
  final TurnActions? currentActions;
  final VoidCallback? onUseAction;
  final VoidCallback? onUseBonusAction;
  final VoidCallback? onEndTurn;

  const CombatOverlay({
    super.key,
    required this.combatLog,
    required this.turnOrder,
    this.initiativeRolls = const {},
    required this.currentTurnIndex,
    required this.isActive,
    this.currentActions,
    this.onUseAction,
    this.onUseBonusAction,
    this.onEndTurn,
  });

  @override
  Widget build(BuildContext context) {
    if (!isActive) return const SizedBox.shrink();

    return Stack(
      children: [
        // Initiative Tracker (Top Center)
        Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("⚔️ ", style: TextStyle(fontSize: 18)),
                  ...turnOrder.asMap().entries.map((e) {
                    final isCurrent = e.key == currentTurnIndex;
                    final roll = initiativeRolls[e.value];
                    final displayName = e.value.length > 8 ? e.value.substring(0, 8) : e.value;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCurrent ? Colors.amber : Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                        border: isCurrent ? Border.all(color: Colors.white, width: 2) : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              color: isCurrent ? Colors.black : Colors.white,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (roll != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              "($roll)",
                              style: TextStyle(
                                color: isCurrent ? Colors.black54 : Colors.white54,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),

        // Action Bar (Bottom Center)
        if (currentActions != null)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionButton(
                      icon: "⚔️",
                      label: "Action",
                      isUsed: currentActions!.actionUsed,
                      onTap: currentActions!.actionUsed ? null : onUseAction,
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: "⚡",
                      label: "Bonus",
                      isUsed: currentActions!.bonusActionUsed,
                      onTap: currentActions!.bonusActionUsed ? null : onUseBonusAction,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: currentActions!.movementRemaining > 0 ? Colors.blue[700] : Colors.grey[700],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Text("🦶", style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 4),
                          Text(
                            "${currentActions!.movementRemaining}",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: onEndTurn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("End Turn"),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Combat Log (Right Side)
        Positioned(
          top: 80,
          right: 16,
          bottom: 80,
          width: 280,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white24)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.history, color: Colors.white70, size: 18),
                      SizedBox(width: 8),
                      Text("Combat Log", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: combatLog.length,
                    reverse: true,
                    itemBuilder: (context, index) {
                      final logIndex = combatLog.length - 1 - index;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          combatLog[logIndex],
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String icon;
  final String label;
  final bool isUsed;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isUsed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isUsed ? Colors.grey[700] : Colors.green[700],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Text(icon, style: TextStyle(fontSize: 16, color: isUsed ? Colors.grey : null)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isUsed ? Colors.grey[400] : Colors.white,
                fontWeight: FontWeight.bold,
                decoration: isUsed ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

