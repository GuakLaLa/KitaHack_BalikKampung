import 'package:flutter/material.dart';

class FloodAlertDialog extends StatelessWidget {
  final int daysUntilFlood; // e.g., 3
  final List<String> checklist;

  const FloodAlertDialog({
    Key? key,
    required this.daysUntilFlood,
    this.checklist = const [
      'Important documents',
      'Medication',
      'Drinking water',
      'Phone & power bank',
    ],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.red,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'ALERT!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'The flood is coming !',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'Bring along your important items and stay away from the area within the time!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 20),

            // Countdown circle with inner red ring
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.red, width: 6),
              ),
              child: Center(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.red, width: 4), // inner ring
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$daysUntilFlood',
                          style: TextStyle(
                            fontSize: 60,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'days',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Checklist
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Checklist',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: checklist
                  .map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• ', style: TextStyle(color: Colors.white)),
                            Expanded(
                              child: Text(
                                item,
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),

            SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Got it', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
