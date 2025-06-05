import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

class BalanceSummary extends StatelessWidget {
  const BalanceSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Balance',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBalanceCard(
                context,
                'You owe',
                '\$0.00',
                Colors.red,
              ),
              _buildBalanceCard(
                context,
                'You are owed',
                '\$0.00',
                Colors.green,
              ),
              _buildBalanceCard(
                context,
                'Settled',
                '\$0.00',
                Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    String title,
    String amount,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
