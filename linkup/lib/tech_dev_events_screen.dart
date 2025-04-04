import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'u_event_details.dart';

class TechDevEventsScreen extends StatelessWidget {
  const TechDevEventsScreen({super.key});

  bool _isInCurrentMonth(String dateStr) {
    try {
      final now = DateTime.now();
      DateTime date;
      if (RegExp(r'^\d{2}-\d{2}$').hasMatch(dateStr)) {
        date = DateFormat('MM-dd').parse(dateStr);
        date = DateTime(now.year, date.month, date.day);
      } else {
        date = DateFormat('yyyy-MM-dd').parse(dateStr);
      }
      return date.month == now.month && date.year == now.year;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tech & Development Events"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No Tech & Development events found."));
          }

          final events = snapshot.data!.docs
              .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id; // ✅ Add document ID to the event map
            return data;
          })
              .where((event) =>
          (event['category'] as String?)?.trim().toLowerCase() ==
              'tech & development'.toLowerCase() &&
              event['date'] != null &&
              _isInCurrentMonth(event['date']))
              .toList();


          if (events.isEmpty) {
            return const Center(child: Text("No Tech events in this month."));
          }

          return ListView.builder(
            itemCount: events.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final event = events[index];
              final imageUrl = event['imageUrl'] ?? '';
              final title = event['eventName'] ?? 'Untitled';
              final date = event['date'] ?? '';
              final venue = event['venue'] ?? '';

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UserEventDetailsScreen(event: event)),
                  );
                },
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                          imageUrl,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                            : Image.asset(
                          'assets/march.png',
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 5),
                            Text(date, style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text(venue, style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
