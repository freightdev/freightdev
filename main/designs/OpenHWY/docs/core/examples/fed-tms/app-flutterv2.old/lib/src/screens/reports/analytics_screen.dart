import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = '30d';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.roadBlack,
      appBar: AppBar(
        backgroundColor: AppColors.asphaltGray,
        title: const Text(
          'Analytics',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_today, color: AppColors.white),
            color: AppColors.concreteGray,
            onSelected: (value) {
              setState(() => _selectedPeriod = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: '7d',
                child: Text('Last 7 days', style: TextStyle(color: AppColors.white)),
              ),
              const PopupMenuItem(
                value: '30d',
                child: Text('Last 30 days', style: TextStyle(color: AppColors.white)),
              ),
              const PopupMenuItem(
                value: '90d',
                child: Text('Last 90 days', style: TextStyle(color: AppColors.white)),
              ),
              const PopupMenuItem(
                value: '1y',
                child: Text('Last year', style: TextStyle(color: AppColors.white)),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Revenue Overview
            const Text(
              'Revenue',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 16),
            _MetricCard(
              title: 'Total Revenue',
              value: '\$156,450',
              change: '+12.5%',
              isPositive: true,
              trend: [45, 52, 48, 62, 55, 68, 72],
            ),
            const SizedBox(height: 24),

            // Key Metrics Grid
            const Text(
              'Performance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: const [
                _KPICard(
                  title: 'Loads Completed',
                  value: '248',
                  change: '+18',
                  icon: Icons.check_circle,
                  color: AppColors.forestGreen,
                ),
                _KPICard(
                  title: 'Active Loads',
                  value: '34',
                  change: '+5',
                  icon: Icons.local_shipping,
                  color: AppColors.highwayBlue,
                ),
                _KPICard(
                  title: 'Avg Rate/Mile',
                  value: '\$2.85',
                  change: '+\$0.12',
                  icon: Icons.trending_up,
                  color: AppColors.yellowLine,
                ),
                _KPICard(
                  title: 'Total Miles',
                  value: '54.8K',
                  change: '+4.2K',
                  icon: Icons.straighten,
                  color: AppColors.sunrisePurple,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Top Drivers
            const Text(
              'Top Drivers',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 16),
            _TopPerformersCard(
              performers: const [
                {'name': 'John Smith', 'value': '\$28,450', 'loads': 42},
                {'name': 'Jane Doe', 'value': '\$24,200', 'loads': 38},
                {'name': 'Mike Johnson', 'value': '\$21,800', 'loads': 35},
              ],
            ),
            const SizedBox(height: 24),

            // Top Routes
            const Text(
              'Top Routes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 16),
            _TopRoutesCard(
              routes: const [
                {'from': 'Chicago, IL', 'to': 'Dallas, TX', 'loads': 18, 'avg': '\$2,450'},
                {'from': 'LA, CA', 'to': 'Phoenix, AZ', 'loads': 15, 'avg': '\$1,850'},
                {'from': 'Atlanta, GA', 'to': 'Miami, FL', 'loads': 12, 'avg': '\$1,550'},
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final bool isPositive;
  final List<double> trend;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.gradientNight,
        border: Border.all(color: AppColors.borderGray),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textGray,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPositive ? AppColors.forestGreen : AppColors.truckRed)
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 14,
                      color: isPositive ? AppColors.forestGreen : AppColors.truckRed,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      change,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isPositive ? AppColors.forestGreen : AppColors.truckRed,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 40,
            child: _MiniLineChart(data: trend),
          ),
        ],
      ),
    );
  }
}

class _MiniLineChart extends StatelessWidget {
  final List<double> data;

  const _MiniLineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final points = data.asMap().entries.map((entry) {
      final index = entry.key;
      final value = entry.value;
      final x = (index / (data.length - 1)) * 100;
      final y = 100 - ((value / maxValue) * 100);
      return Offset(x, y);
    }).toList();

    return CustomPaint(
      painter: _LineChartPainter(points: points),
      size: Size(MediaQuery.of(context).size.width, 40),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<Offset> points;

  _LineChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.forestGreen
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final point = Offset(
        points[i].dx * size.width / 100,
        points[i].dy * size.height / 100,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _KPICard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final IconData icon;
  final Color color;

  const _KPICard({
    required this.title,
    required this.value,
    required this.change,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.gradientNight,
        border: Border.all(color: AppColors.borderGray),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                change,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.white,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textGray,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopPerformersCard extends StatelessWidget {
  final List<Map<String, dynamic>> performers;

  const _TopPerformersCard({required this.performers});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.gradientNight,
        border: Border.all(color: AppColors.borderGray),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: performers.asMap().entries.map((entry) {
          final index = entry.key;
          final performer = entry.value;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: index < performers.length - 1
                  ? Border(bottom: BorderSide(color: AppColors.borderLight))
                  : null,
            ),
            child: Row(
              children: [
                _RankBadge(rank: index + 1),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        performer['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                      Text(
                        '${performer['loads']} loads',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  performer['value'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forestGreen,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (rank == 1) {
      color = AppColors.yellowLine;
    } else if (rank == 2) {
      color = AppColors.textGray;
    } else {
      color = AppColors.warningOrange;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _TopRoutesCard extends StatelessWidget {
  final List<Map<String, dynamic>> routes;

  const _TopRoutesCard({required this.routes});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.gradientNight,
        border: Border.all(color: AppColors.borderGray),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: routes.map((route) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppColors.forestGreen,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            route['from'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.flag,
                            size: 16,
                            color: AppColors.truckRed,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            route['to'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      route['avg'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.forestGreen,
                      ),
                    ),
                    Text(
                      '${route['loads']} loads',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
