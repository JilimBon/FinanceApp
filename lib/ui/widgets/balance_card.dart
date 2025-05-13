import 'package:flutter/material.dart';

class BalanceCard extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final Color valueColor;
  final String label;
  final bool showMinus;
  final String? customValue;
  const BalanceCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.valueColor,
    required this.label,
    this.showMinus = true,
    this.customValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: valueColor),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                customValue ??
                  ((showMinus && value > 0 && valueColor == Colors.red ? '-' : '') +
                  value.abs().toStringAsFixed(0) + ' ₽'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'RobotoMono',
                      color: valueColor,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: valueColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}