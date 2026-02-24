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

    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final padding = isSmallScreen ? 12.0 : 16.0;

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
        title: Text(
          'Dashboard',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 16 : 18,
          ),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.black, size: isSmallScreen ? 20 : 24),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black, size: isSmallScreen ? 20 : 24),
            onPressed: () => dashboardViewModel.refreshDashboard(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Expiry Check Button
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(padding),
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
                    Icon(Icons.notifications, color: Colors.blue, size: isSmallScreen ? 20 : 24),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Expanded(
                      child: Text(
                        'Run Expiry Check',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => dashboardViewModel.runExpiryCheck(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 16,
                          vertical: isSmallScreen ? 8 : 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        'Run',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 11 : 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),

              // Stats Grid - Responsive
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - (isSmallScreen ? 12 : 16)) / 2;
                  final cardHeight = cardWidth * 0.85; // Adjusted ratio

                  return Wrap(
                    spacing: isSmallScreen ? 12 : 16,
                    runSpacing: isSmallScreen ? 12 : 16,
                    children: [
                      // Active Members Card
                      SizedBox(
                        width: cardWidth,
                        height: cardHeight,
                        child: _StatCard(
                          title: 'Active Members',
                          value: '${dashboardState.stats?.activeMembers ?? 0}',
                          subtitle: 'Total active memberships',
                          icon: Icons.people,
                          color: Colors.blue,
                          isSmallScreen: isSmallScreen,
                        ),
                      ),

                      // Expiring Card
                      SizedBox(
                        width: cardWidth,
                        height: cardHeight,
                        child: _StatCard(
                          title: 'Expiring (7 days)',
                          value: '${dashboardState.stats?.expiringSubscriptions ?? 0}',
                          subtitle: 'Subscriptions ending soon',
                          icon: Icons.calendar_today,
                          color: Colors.orange,
                          isSmallScreen: isSmallScreen,
                        ),
                      ),

                      // Expired Card
                      SizedBox(
                        width: cardWidth,
                        height: cardHeight,
                        child: _StatCard(
                          title: 'Expired',
                          value: '${dashboardState.stats?.expiredSubscriptions ?? 0}',
                          subtitle: 'Inactive memberships',
                          icon: Icons.person_off,
                          color: Colors.red,
                          isSmallScreen: isSmallScreen,
                        ),
                      ),

                      // Monthly Revenue Card
                      SizedBox(
                        width: cardWidth,
                        height: cardHeight,
                        child: _RevenueCard(
                          title: 'Monthly Revenue',
                          value: dashboardState.stats?.monthlyRevenue ?? '\$0',
                          subtitle: dashboardState.stats?.renewalRate ?? '0%',
                          renewalText: 'renewal',
                          color: Colors.green,
                          isSmallScreen: isSmallScreen,
                        ),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),

              // Revenue Trend Chart
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
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
                    Text(
                      'Revenue Trend',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    _RevenueTrendChart(
                      data: dashboardState.stats?.revenueTrend ?? [],
                      isSmallScreen: isSmallScreen,
                    ),
                  ],
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),

              // Membership Breakdown Pie Chart
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
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
                      isSmallScreen: isSmallScreen,
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 20),
                    Text(
                      'Expiring Soon (Next 7 Days)',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    if ((dashboardState.expiringSubscriptions?.isEmpty ?? true))
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 16 : 24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.calendar_month,
                                size: isSmallScreen ? 36 : 48,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: isSmallScreen ? 8 : 12),
                              Text(
                                'No subscriptions expiring in the next 7 days',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: isSmallScreen ? 12 : 14,
                                ),
                              ),
                            ],
                          ),
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
                              padding: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
                              child: _SubscriptionTile(
                                subscription: subscription,
                                isSmallScreen: isSmallScreen,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 24),
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
  final bool isSmallScreen;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 10 : 14),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isSmallScreen ? 4 : 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 20 : 28,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: isSmallScreen ? 4 : 8),
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: isSmallScreen ? 18 : 24),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 4 : 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: isSmallScreen ? 9 : 11,
              color: Colors.grey,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
  final bool isSmallScreen;

  const _RevenueCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.renewalText,
    required this.color,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 10 : 14),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isSmallScreen ? 4 : 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 20 : 28,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: isSmallScreen ? 4 : 8),
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.attach_money, color: color, size: isSmallScreen ? 18 : 24),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 4 : 8),
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.green, size: isSmallScreen ? 12 : 14),
              SizedBox(width: isSmallScreen ? 2 : 4),
              Flexible(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: isSmallScreen ? 1 : 2),
              Text(
                renewalText,
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 12,
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
  final bool isSmallScreen;

  const _RevenueTrendChart({
    required this.data,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: isSmallScreen ? 200 : 250,
        child: Center(
          child: Text(
            'No revenue data available',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: isSmallScreen ? 12 : 14,
            ),
          ),
        ),
      );
    }

    // Find max value for scaling - ensure double type
    final maxValue = data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    final maxYValue = maxValue * 1.1; // Add 10% padding at top
    final intervalValue = maxYValue / 4;

    return SizedBox(
      height: isSmallScreen ? 200 : 250,
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
                    width: isSmallScreen ? 12 : 16,
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
                      padding: EdgeInsets.only(top: isSmallScreen ? 4 : 8),
                      child: Text(
                        data[index].month,
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                          fontSize: isSmallScreen ? 9 : 11,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
                reservedSize: isSmallScreen ? 20 : 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: isSmallScreen ? 35 : 45,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '\$${value.toInt()}',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                      fontSize: isSmallScreen ? 8 : 10,
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
              tooltipPadding: EdgeInsets.all(isSmallScreen ? 6 : 8),
            ),
          ),
        ),
      ),
    );
  }
}

class _MembershipPieChart extends StatelessWidget {
  final MembershipBreakdown? breakdown;
  final bool isSmallScreen;

  const _MembershipPieChart({
    required this.breakdown,
    this.isSmallScreen = false,
  });

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
          height: isSmallScreen ? 140 : 180,
          child: CustomPaint(
            painter: PieChartPainter(
              active: active,
              expiring: expiring,
              expired: expired,
              total: total,
              isSmallScreen: isSmallScreen,
            ),
            size: Size(isSmallScreen ? 160 : 200, isSmallScreen ? 160 : 200),
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: isSmallScreen ? 12 : 20,
          runSpacing: isSmallScreen ? 8 : 12,
          children: [
            _LegendItem(
              color: Colors.blue,
              label: 'Active',
              value: active,
              isSmallScreen: isSmallScreen,
            ),
            _LegendItem(
              color: Colors.orange,
              label: 'Expiring',
              value: expiring,
              isSmallScreen: isSmallScreen,
            ),
            _LegendItem(
              color: Colors.red,
              label: 'Expired',
              value: expired,
              isSmallScreen: isSmallScreen,
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
  final bool isSmallScreen;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isSmallScreen ? 10 : 12,
          height: isSmallScreen ? 10 : 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: isSmallScreen ? 4 : 8),
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 10 : 12,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

class _SubscriptionTile extends StatelessWidget {
  final ExpiringSubscription subscription;
  final bool isSmallScreen;

  const _SubscriptionTile({
    required this.subscription,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 12 : 14,
            ),
          ),
          SizedBox(height: isSmallScreen ? 2 : 4),
          Text(
            subscription.email,
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: isSmallScreen ? 2 : 4),
          Text(
            subscription.phone,
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 12,
              color: Colors.grey[600],
            ),
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
  final bool isSmallScreen;

  PieChartPainter({
    required this.active,
    required this.expiring,
    required this.expired,
    required this.total,
    this.isSmallScreen = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = isSmallScreen ? 60.0 : 80.0;

    if (total == 0) {
      // Draw empty pie chart
      final paint = Paint()
        ..color = Colors.grey[300]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSmallScreen ? 12 : 15;

      canvas.drawCircle(center, radius, paint);
      return;
    }

    double startAngle = -3.14159 / 2;

    // Draw Active
    final activePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSmallScreen ? 12 : 15;

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
      ..strokeWidth = isSmallScreen ? 12 : 15;

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
      ..strokeWidth = isSmallScreen ? 12 : 15;

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




