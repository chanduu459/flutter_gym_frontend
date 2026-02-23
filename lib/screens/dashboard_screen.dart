import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../widgets/app_drawer.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardViewModelProvider);
    final dashboardViewModel = ref.read(dashboardViewModelProvider.notifier);

    if (dashboardState.isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('Dashboard'),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () => dashboardViewModel.refreshDashboard(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Expiry Check Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: const Text(
                        'Run Expiry Check',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => dashboardViewModel.runExpiryCheck(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        'Run',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 19),

              // Stats Grid
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 19,
                mainAxisSpacing: 19,
                shrinkWrap: true,
                childAspectRatio: 1.9,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Active Members Card
                  _StatCard(
                    title: 'Active Members',
                    value: '${dashboardState.stats?.activeMembers ?? 0}',
                    subtitle: 'Total active memberships',
                    icon: Icons.people,
                    color: Colors.blue,
                  ),

                  // Expiring Card
                  _StatCard(
                    title: 'Expiring (7 days)',
                    value: '${dashboardState.stats?.expiringSubscriptions ?? 0}',
                    subtitle: 'Subscriptions ending soon',
                    icon: Icons.calendar_today,
                    color: Colors.orange,
                  ),

                  // Expired Card
                  _StatCard(
                    title: 'Expired',
                    value: '${dashboardState.stats?.expiredSubscriptions ?? 0}',
                    subtitle: 'Inactive memberships',
                    icon: Icons.person_off,
                    color: Colors.red,
                  ),

                  // Monthly Revenue Card
                  _RevenueCard(
                    title: 'Monthly Revenue',
                    value: dashboardState.stats?.monthlyRevenue ?? '\$0',
                    subtitle: dashboardState.stats?.renewalRate ?? '0%',
                    renewalText: 'renewal',
                    color: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Revenue Trend Chart
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Revenue Trend',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _RevenueTrendChart(
                      data: dashboardState.stats?.revenueTrend ?? [],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Membership Breakdown Pie Chart
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MembershipPieChart(
                      breakdown: dashboardState.stats?.membershipBreakdown,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Expiring Soon (Next 7 Days)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if ((dashboardState.expiringSubscriptions?.isEmpty ?? true))
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.calendar_month,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No subscriptions expiring in the next 7 days',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: List.generate(
                          dashboardState.expiringSubscriptions?.length ?? 0,
                          (index) {
                            final subscription =
                                dashboardState.expiringSubscriptions![index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _SubscriptionTile(
                                subscription: subscription,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final String renewalText;
  final Color color;

  const _RevenueCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.renewalText,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.attach_money, color: color, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.green, size: 14),
              const SizedBox(width: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                renewalText,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RevenueTrendChart extends StatelessWidget {
  final List<RevenueData> data;

  const _RevenueTrendChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Text(
            'No revenue data available',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
      );
    }

    // Find max value for scaling - ensure double type
    final maxValue = data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    final maxYValue = maxValue * 1.1; // Add 10% padding at top
    final intervalValue = maxYValue / 4;

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          maxY: maxYValue,
          minY: 0,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: intervalValue,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300] ?? Colors.grey,
                strokeWidth: 0.5,
              );
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              left: BorderSide(color: Colors.grey[300] ?? Colors.grey, width: 1),
              bottom: BorderSide(color: Colors.grey[300] ?? Colors.grey, width: 1),
            ),
          ),
          barGroups: List.generate(
            data.length,
            (index) {
              final item = data[index];
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: item.amount, // amount is already a double
                    color: Colors.blue.shade400,
                    width: 16,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxYValue,
                      color: Colors.grey[100],
                    ),
                  ),
                ],
                showingTooltipIndicators: [],
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < data.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        data[index].month,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '\$${value.toInt()}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                    ),
                  );
                },
                interval: intervalValue,
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipRoundedRadius: 8,
              tooltipMargin: 8,
              tooltipPadding: const EdgeInsets.all(8),
            ),
          ),
        ),
      ),
    );
  }
}

class _MembershipPieChart extends StatelessWidget {
  final MembershipBreakdown? breakdown;

  const _MembershipPieChart({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final active = breakdown?.active ?? 0;
    final expiring = breakdown?.expiring ?? 0;
    final expired = breakdown?.expired ?? 0;
    final total = active + expiring + expired;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 180,
          child: CustomPaint(
            painter: PieChartPainter(
              active: active,
              expiring: expiring,
              expired: expired,
              total: total,
            ),
            size: const Size(200, 200),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(
              color: Colors.blue,
              label: 'Active',
              value: active,
            ),
            const SizedBox(width: 24),
            _LegendItem(
              color: Colors.orange,
              label: 'Expiring',
              value: expiring,
            ),
            const SizedBox(width: 24),
            _LegendItem(
              color: Colors.red,
              label: 'Expired',
              value: expired,
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black),
        ),
      ],
    );
  }
}

class _SubscriptionTile extends StatelessWidget {
  final ExpiringSubscription subscription;

  const _SubscriptionTile({required this.subscription});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subscription.memberName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subscription.email,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            subscription.phone,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class PieChartPainter extends CustomPainter {
  final int active;
  final int expiring;
  final int expired;
  final int total;

  PieChartPainter({
    required this.active,
    required this.expiring,
    required this.expired,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 80.0;

    if (total == 0) {
      // Draw empty pie chart
      final paint = Paint()
        ..color = Colors.grey[300]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15;

      canvas.drawCircle(center, radius, paint);
      return;
    }

    double startAngle = -3.14159 / 2;

    // Draw Active
    final activePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15;

    final activeSweep = (active / total) * 2 * 3.14159;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      activeSweep,
      false,
      activePaint,
    );
    startAngle += activeSweep;

    // Draw Expiring
    final expiringPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15;

    final expiringSweep = (expiring / total) * 2 * 3.14159;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      expiringSweep,
      false,
      expiringPaint,
    );
    startAngle += expiringSweep;

    // Draw Expired
    final expiredPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      (expired / total) * 2 * 3.14159,
      false,
      expiredPaint,
    );
  }

  @override
  bool shouldRepaint(PieChartPainter oldDelegate) => false;
}




