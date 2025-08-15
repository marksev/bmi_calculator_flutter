import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const BmiApp());

class BmiApp extends StatelessWidget {
  const BmiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BMI Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D6CDF)),
        scaffoldBackgroundColor: const Color(0xFFEAF0F4), // soft blue/grey like screenshot
      ),
      home: const BmiScreen(),
    );
  }
}

class BmiScreen extends StatefulWidget {
  const BmiScreen({super.key});
  @override
  State<BmiScreen> createState() => _BmiScreenState();
}

class _BmiScreenState extends State<BmiScreen> {
  // Controllers
  final heightCtrl = TextEditingController();
  final weightCtrl = TextEditingController();

  // Units
  String heightUnit = 'cm'; // cm | ft
  String weightUnit = 'kg'; // kg | lb

  // Result
  double bmi = 0.0;
  String category = '—';
  String differenceText = '—';

  // Helpers
  double? _parseD(String s) =>
      double.tryParse(s.trim().replaceAll(',', '.'));

  double _toMeters(double h, String unit) {
    if (unit == 'cm') return h / 100.0;
    // feet to meters (assuming user enters whole feet, not ft+in)
    return h * 0.3048;
  }

  double _toKg(double w, String unit) {
    if (unit == 'kg') return w;
    return w * 0.45359237; // lb -> kg
  }

  String _bmiCategory(double v) {
    if (v < 16.0) return 'Very Severely Underweight';
    if (v < 17.0) return 'Severely Underweight';
    if (v < 18.5) return 'Underweight';
    if (v < 25.0) return 'Normal';
    if (v < 30.0) return 'Overweight';
    if (v < 35.0) return 'Obese Class I';
    if (v < 40.0) return 'Obese Class II';
    return 'Obese Class III';
  }

  /// How far the value is from the nearest bound of the “Normal” range.
  String _differenceToNormal(double v) {
    const low = 18.5, high = 25.0;
    if (v == 0) return '—';
    if (v < low) return '-${(low - v).toStringAsFixed(1)}';
    if (v > high) return '+${(v - high).toStringAsFixed(1)}';
    return '0.0';
  }

  void _calculate() {
    final h = _parseD(heightCtrl.text) ?? 0;
    final w = _parseD(weightCtrl.text) ?? 0;

    final m = _toMeters(h, heightUnit);
    final kg = _toKg(w, weightUnit);

    if (m <= 0 || kg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid height and weight')),
      );
      setState(() {
        bmi = 0.0;
        category = '—';
        differenceText = '—';
      });
      return;
    }

    final value = kg / (m * m);
    setState(() {
      bmi = value;
      category = _bmiCategory(value);
      differenceText = _differenceToNormal(value);
    });
  }

  @override
  void dispose() {
    heightCtrl.dispose();
    weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: const Text('BMI Calculator',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: const [
          // icons to mimic screenshot (no actions)
          Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.redo)),
          Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.more_vert)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          const SizedBox(height: 4),
          // Headings
          _sectionHeader(context, 'Age', trailing: null),
          const Divider(height: 20),
          _sectionHeader(context, 'Height',
              trailing: _UnitPicker(
                value: heightUnit,
                items: const ['cm', 'ft'],
                onChanged: (v) => setState(() => heightUnit = v),
              )),
          const SizedBox(height: 8),
          _boxedField(
            controller: heightCtrl,
            hint: 'Enter height',
            inputType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const Divider(height: 28),

          _sectionHeader(context, 'Weight',
              trailing: _UnitPicker(
                value: weightUnit,
                items: const ['kg', 'lb'],
                onChanged: (v) => setState(() => weightUnit = v),
              )),
          const SizedBox(height: 8),
          _boxedField(
            controller: weightCtrl,
            hint: 'Enter weight',
            inputType: const TextInputType.numberWithOptions(decimal: true),
          ),

          const SizedBox(height: 16),
          _infoBanner(),

          const SizedBox(height: 16),

          // Gauge Card
          Card(
            elevation: 0,
            color: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 18, 12, 20),
              child: Column(
                children: [
                  // Gender row (decorative like screenshot)
                  Row(
                    children: const [
                      Icon(Icons.female, color: Colors.teal, size: 24),
                      SizedBox(width: 8),
                      Icon(Icons.male, color: Colors.black26, size: 24),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Gauge + BMI number
                  SizedBox(
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(double.infinity, 200),
                          painter: _BmiGaugePainter(value: bmi),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'BMI',
                              style: TextStyle(
                                  color: Colors.grey.shade700, fontSize: 14),
                            ),
                            Text(
                              bmi.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: cs.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Category / Difference row
                  Row(
                    children: [
                      Expanded(
                        child: _pair(
                          title: 'Category',
                          value: category,
                        ),
                      ),
                      Expanded(
                        child: _pair(
                          title: 'Difference',
                          value: differenceText,
                          alignRight: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Table (categories)
          Card(
            elevation: 0,
            color: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _rowHeader(context, 'Category', 'Difference'),
                  const Divider(),
                  _row(context, 'Very Severely Underweight', '≤ 15.9'),
                  _row(context, 'Severely Underweight', '16.0 – 16.9'),
                  _row(context, 'Underweight', '17.0 – 18.4'),
                  _row(context, 'Normal', '18.5 – 24.9'),
                  _row(context, 'Overweight', '25.0 – 29.9'),
                  _row(context, 'Obese Class I', '30.0 – 34.9'),
                  _row(context, 'Obese Class II', '35.0 – 39.9'),
                  _row(context, 'Obese Class III', '≥ 40.0'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Continue button (calculates)
          FilledButton(
            onPressed: _calculate,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'CONTINUE',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---- UI helpers ----

  Widget _sectionHeader(BuildContext c, String title, {Widget? trailing}) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(c)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700, color: Colors.black87),
        ),
        const Spacer(),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _boxedField({
    required TextEditingController controller,
    required String hint,
    required TextInputType inputType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
      ],
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade300, width: 1.5),
        ),
      ),
    );
  }

  Widget _pair({required String title, required String value, bool alignRight = false}) {
    final txt = Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
    return txt;
  }

  Widget _rowHeader(BuildContext c, String l, String r) {
    return Row(
      children: [
        Expanded(
            child: Text(l,
                style: Theme.of(c)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700))),
        Expanded(
            child: Text(r,
                textAlign: TextAlign.right,
                style: Theme.of(c)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700))),
      ],
    );
  }

  Widget _row(BuildContext c, String l, String r) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(l, style: const TextStyle(fontSize: 16))),
          Expanded(
              child: Text(r,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _infoBanner() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD8D9FF),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Color(0xFF4F5BD5)),
              SizedBox(width: 6),
              Text(
                'Why do we need this information?',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: Color(0xFF4F5BD5)),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            'Your height and weight help us calculate your BMI and provide personalized health recommendations.',
          ),
        ],
      ),
    );
  }
}

/// Simple semicircular gauge with colored ranges and a pointer for current BMI.
/// Ranges: Underweight 16–18.5 (blue), Normal 18.5–25 (green), Overweight 25–40 (red).
class _BmiGaugePainter extends CustomPainter {
  _BmiGaugePainter({required this.value});

  final double value;

  static const double min = 16.0;
  static const double max = 40.0;

  // Convert BMI to angle (start at 180°, end at 0°)
  double _angleFor(double v) {
    final clamped = v.isNaN ? min : v.clamp(min, max);
    final t = (clamped - min) / (max - min); // 0..1
    return math.pi - (math.pi * t); // pi..0
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final center = Offset(w / 2, size.height * 0.95);
    final radius = math.min(w * 0.8, size.height * 1.7) / 2;

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    // Draw colored arcs
    void arc(double startDeg, double sweepDeg, Color color) {
      final rect =
          Rect.fromCircle(center: center, radius: radius);
      final start = startDeg * (math.pi / 180);
      final sweep = sweepDeg * (math.pi / 180);
      final p = base..color = color;
      canvas.drawArc(rect, start, sweep, false, p);
    }

    // Map BMI breakpoints to degrees (180 -> 0)
    double degFor(double v) => 180 - ((v - min) / (max - min)) * 180;

    // Segments: [16..18.5] blue, [18.5..25] green, [25..40] red
    arc(180, degFor(18.5) - 180, const Color(0xFF3A86FF)); // Underweight
    arc(degFor(18.5), degFor(25.0) - degFor(18.5), const Color(0xFF80C980)); // Normal
    arc(degFor(25.0), degFor(40.0) - degFor(25.0), const Color(0xFFFF9B9B)); // Overweight+

    // Tick labels (16, 18.5, 25, 40)
    final textPainter = (String s) {
      final tp = TextPainter(
        text: TextSpan(
            text: s,
            style:
                const TextStyle(fontSize: 12, color: Colors.black54)),
        textDirection: TextDirection.ltr,
      )..layout();
      return tp;
    };

    void label(double v, String s, double rOff) {
      final a = _angleFor(v);
      final pos = Offset(
        center.dx + (radius + rOff) * math.cos(a),
        center.dy + (radius + rOff) * math.sin(a),
      );
      final tp = textPainter(s);
      canvas.save();
      canvas.translate(pos.dx - tp.width / 2, pos.dy - tp.height / 2);
      tp.paint(canvas, Offset.zero);
      canvas.restore();
    }

    label(18.5, '18.5', 14);
    label(25.0, '25.0', 14);
    label(16.0, '16.0', 14);
    label(40.0, '40.0', 14);

    // Section titles “Underweight / Normal / Overweight”
    void title(String s, double midVal) {
      final a = _angleFor(midVal);
      final r2 = radius - 28;
      final pos = Offset(
        center.dx + r2 * math.cos(a),
        center.dy + r2 * math.sin(a),
      );
      final tp = TextPainter(
        text: TextSpan(
            text: s,
            style:
                const TextStyle(fontSize: 14, color: Colors.black54)),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(pos.dx - tp.width / 2, pos.dy - tp.height / 2);
      tp.paint(canvas, Offset.zero);
      canvas.restore();
    }

    title('Underweight', (16 + 18.5) / 2);
    title('Normal', (18.5 + 25.0) / 2);
    title('Overweight', (25.0 + 40.0) / 2);

    // Pointer
    final angle = _angleFor(value == 0 ? 16 : value);
    final pointerLen = 10.0;
    final pointerCenter =
        Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
    final p = Paint()..color = const Color(0xFF2D6CDF);
    canvas.drawCircle(pointerCenter, 10, p);
  }

  @override
  bool shouldRepaint(covariant _BmiGaugePainter oldDelegate) =>
      oldDelegate.value != value;
}

class _UnitPicker extends StatelessWidget {
  const _UnitPicker(
      {required this.value, required this.items, required this.onChanged});
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: value,
      underline: const SizedBox.shrink(),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (v) => onChanged(v ?? value),
    );
  }
}
