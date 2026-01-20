import 'package:flutter/material.dart';

class CombatOverlay extends StatelessWidget {
  final List<String> combatLog;
  final List<String> turnOrder;
  final int currentTurnIndex;
  final bool isActive;

  const CombatOverlay({
    super.key,
    required this.combatLog,
    required this.turnOrder,
    required this.currentTurnIndex,
    required this.isActive,
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
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCurrent ? Colors.amber : Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                        border: isCurrent ? Border.all(color: Colors.white, width: 2) : null,
                      ),
                      child: Text(
                        e.value.length > 8 ? e.value.substring(0, 8) : e.value,
                        style: TextStyle(
                          color: isCurrent ? Colors.black : Colors.white,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),

        // Combat Log (Right Side)
        Positioned(
          top: 80,
          right: 16,
          bottom: 16,
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
                    reverse: true, // Newest at bottom
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
