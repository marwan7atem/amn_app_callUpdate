import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/car_driver_status_service.dart';

class CarStatusScreen extends StatefulWidget {
  const CarStatusScreen({super.key});

  @override
  State<CarStatusScreen> createState()  => _CarStatusScreenState();
}

class _CarStatusScreenState extends State<CarStatusScreen> {
  @override
  void initState() {
    super.initState();
    _recordCarStatus();
  }

  Future<void> _recordCarStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await CarDriverStatusService.saveCarStatus(
      userId: user.uid,
      carHealthPercent: 80,
      fuelLevelPercent: 62,
      fuelRangeKm: 245,
      engineTempC: 90,
      tirePressurePsi: {'FL': 34, 'FR': 34, 'RL': 34, 'RR': 34},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Car Status',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _SectionTitle('CAR STATUS'),
          SizedBox(height: 12),
          _CarStatusGrid(),
          SizedBox(height: 18),
          _SectionTitle('DRIVER STATUS'),
          SizedBox(height: 12),
          _DriverStatusGrid(),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }
}

class _CarStatusGrid extends StatelessWidget {
  const _CarStatusGrid();

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        children: const [
          Row(
            children: [
              Expanded(
                child: _MiniMetricCard(
                  title: 'Car Health',
                  bottomLabel: 'STABLE',
                  progress: 0.80,
                  progressColor: Color(0xFF2ECC71),
                  rightWidget: _SparkLine(color: Color(0xFF2ECC71)),
                ),
              ),
              SizedBox(width: 12),
              Expanded(child: _FuelCard()),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _TirePressureCard()),
              SizedBox(width: 12),
              Expanded(child: _EngineTempCard()),
            ],
          ),
        ],
      ),
    );
  }
}

class _DriverStatusGrid extends StatelessWidget {
  const _DriverStatusGrid();

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        children: const [
          Row(
            children: [
              Expanded(
                child: _MiniMetricCard(
                  title: 'Driver Attentiveness',
                  bottomLabel: 'FOCUSED',
                  subLabel: 'Distracted Moments: 3',
                  progress: 0.92,
                  progressColor: Color(0xFFF5C542),
                  rightWidget: _SparkLine(color: Color(0xFFF5C542)),
                ),
              ),
              SizedBox(width: 12),
              Expanded(child: _DrivingBehaviorCard()),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _FatigueCard()),
              SizedBox(width: 12),
              Expanded(child: _LastTripCard()),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetricCard extends StatelessWidget {
  final String title;
  final String bottomLabel;
  final String? subLabel;
  final double progress;
  final Color progressColor;
  final Widget rightWidget;

  const _MiniMetricCard({
    required this.title,
    required this.bottomLabel,
    required this.progress,
    required this.progressColor,
    required this.rightWidget,
    this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _RingProgress(
                progress: progress,
                color: progressColor,
                size: 48,
                strokeWidth: 6,
              ),
              const SizedBox(width: 10),
              Expanded(child: rightWidget),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            bottomLabel,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subLabel != null) ...[
            const SizedBox(height: 2),
            Text(
              subLabel!,
              style: const TextStyle(color: Colors.black54, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}

class _FuelCard extends StatelessWidget {
  const _FuelCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Fuel Level',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10),
          _BarMeter(value: 0.62, color: Color(0xFF2ECC71)),
          SizedBox(height: 10),
          Text(
            'Range: 245 km',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EngineTempCard extends StatelessWidget {
  const _EngineTempCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Engine Temperature',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10),
          Text(
            '90°C',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'NORMAL',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          _SparkLine(color: Color(0xFF2ECC71)),
        ],
      ),
    );
  }
}

class _TirePressureCard extends StatelessWidget {
  const _TirePressureCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Tire Pressure',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10),
          _TireBars(),
          SizedBox(height: 10),
          Text(
            'ALL GOOD',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrivingBehaviorCard extends StatelessWidget {
  const _DrivingBehaviorCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Driving Behavior Score',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '84',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Med',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          _RiskBar(),
          SizedBox(height: 10),
          Text(
            'Last reset: 2 hours ago',
            style: TextStyle(color: Colors.black54, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _FatigueCard extends StatelessWidget {
  const _FatigueCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Fatigue Level',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
          _RingProgress(
            progress: 0.35,
            color: Color(0xFF2ECC71),
            size: 56,
            strokeWidth: 7,
          ),
          SizedBox(height: 10),
          Text(
            'LOW',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _LastTripCard extends StatelessWidget {
  const _LastTripCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Last Trip Summary',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Distance: 18.4 km',
            style: TextStyle(color: Colors.black54, fontSize: 11),
          ),
          SizedBox(height: 6),
          Text(
            'Duration: 32 min',
            style: TextStyle(color: Colors.black54, fontSize: 11),
          ),
          SizedBox(height: 6),
          Text(
            'Harsh braking: 1',
            style: TextStyle(color: Colors.black54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _RingProgress extends StatelessWidget {
  final double progress;
  final Color color;
  final double size;
  final double strokeWidth;

  const _RingProgress({
    required this.progress,
    required this.color,
    required this.size,
    required this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: strokeWidth,
            backgroundColor: Colors.black12,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Text(
            '$pct%',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarMeter extends StatelessWidget {
  final double value;
  final Color color;

  const _BarMeter({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 10,
        color: Colors.black12,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0, 1),
            child: Container(color: color),
          ),
        ),
      ),
    );
  }
}

class _SparkLine extends StatelessWidget {
  final Color color;
  const _SparkLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: CustomPaint(
        painter: _SparkLinePainter(color: color),
        child: Container(),
      ),
    );
  }
}

class _SparkLinePainter extends CustomPainter {
  final Color color;
  const _SparkLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.2,
        size.height * 0.2,
        size.width * 0.4,
        size.height * 0.55,
      )
      ..quadraticBezierTo(
        size.width * 0.6,
        size.height * 0.9,
        size.width * 0.8,
        size.height * 0.35,
      )
      ..quadraticBezierTo(
        size.width * 0.9,
        size.height * 0.2,
        size.width,
        size.height * 0.5,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TireBars extends StatelessWidget {
  const _TireBars();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _OneTireBar(label: 'FL', value: 0.85)),
        SizedBox(width: 8),
        Expanded(child: _OneTireBar(label: 'FR', value: 0.75)),
        SizedBox(width: 8),
        Expanded(child: _OneTireBar(label: 'RL', value: 0.80)),
        SizedBox(width: 8),
        Expanded(child: _OneTireBar(label: 'RR', value: 0.78)),
      ],
    );
  }
}

class _OneTireBar extends StatelessWidget {
  final String label;
  final double value;

  const _OneTireBar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 36,
            color: Colors.black12,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: value.clamp(0, 1),
                child: Container(color: const Color(0xFF2ECC71)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 10),
        ),
      ],
    );
  }
}

class _RiskBar extends StatelessWidget {
  const _RiskBar();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _BarMeter(value: 0.70, color: Color(0xFF2ECC71)),
        SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Safe', style: TextStyle(color: Colors.black54, fontSize: 10)),
            Text(
              'Moderate',
              style: TextStyle(color: Colors.black54, fontSize: 10),
            ),
            Text(
              'Risky',
              style: TextStyle(color: Colors.black54, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}
