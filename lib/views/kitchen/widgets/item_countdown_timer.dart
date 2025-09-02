// lib/views/kitchen/widgets/item_countdown_timer.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ItemCountdownTimer extends HookWidget {
  final Duration preparationTime;
  final Timestamp orderCreatedAt;

  const ItemCountdownTimer({
    super.key,
    required this.preparationTime,
    required this.orderCreatedAt,
  });

  @override
  Widget build(BuildContext context) {
    final elapsedTime = useState(Duration.zero);

    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        elapsedTime.value = DateTime.now().difference(orderCreatedAt.toDate());
      });
      return timer.cancel;
    }, [orderCreatedAt]);

    final totalSeconds = preparationTime.inSeconds;
    final elapsedSeconds = elapsedTime.value.inSeconds;
    final progress = totalSeconds > 0
        ? (elapsedSeconds / totalSeconds).clamp(0.0, 1.0)
        : 1.0;

    final remainingSeconds = (totalSeconds - elapsedSeconds).clamp(
      0,
      totalSeconds,
    );
    final remainingTime =
        '${remainingSeconds ~/ 60}:${(remainingSeconds % 60).toString().padLeft(2, '0')}';

    return SizedBox(
      width: 90, // Re-added with a smaller, consistent width
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.8
                    ? Colors.red
                    : (progress > 0.5 ? Colors.orange : Colors.green),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            remainingTime,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
