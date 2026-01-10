import 'package:flutter/material.dart';

class FarmScreen extends StatelessWidget {
  const FarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FFF9),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 180,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF00C853), Color(0xFFB2FF59)]),
            ),
            padding: const EdgeInsets.only(top: 60, left: 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("🌾 나의 농장", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildBadge("🐔 0마리"),
                    const SizedBox(width: 8),
                    _buildBadge("🥚 0개 진행 중"),
                  ],
                )
              ],
            ),
          ),
          const Expanded(child: Center(child: Text("아직 달성한 목표가 없어요\n100% 달성하면 닭이 됩니다!", textAlign: TextAlign.center)))
        ],
      ),
    );
  }

  Widget _buildBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withAlpha(77), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}
