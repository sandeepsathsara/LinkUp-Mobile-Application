import 'package:flutter/material.dart';

class EventDetailsScreen extends StatelessWidget {
  final Map<String, String> event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Event Details'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 15.0),
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/profile.jpg'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                event['image']!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              event['title']!,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: const [
                Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                SizedBox(width: 5),
                Text(
                  '05 March 2025\n08:00 - 12:00',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: const [
                Icon(Icons.location_on, size: 16, color: Colors.red),
                SizedBox(width: 5),
                Text(
                  'Colombo, Sri Lanka\nBMICH',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Text(
              'About',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              "Science Cite is delighted to welcome you to the International Conference on Cloud Computing and Services Science at Colombo, Sri Lanka on 05th - 06th Mar 2025. It's our pleasure to have a platform with all the field's leading scientists, outstanding researchers, academic people, and industrialists from national and international locations. All attendees and the domain will benefit from the discussions at conferences, seminars, workshops, symposia, and other related events. In addition, we offer a platform for all academicians to display their research and ideas and explore speaking opportunities.\n\nIn addition to being united by a common goal - to provide information exchange and advance the fields. This conference will help you all make new connections, gain recognition and receive feedback to help you grow personally and professionally. Our goal is to create a motivating atmosphere and to discuss solutions, future strategies, and trends. Therefore, we look forward to your participation which means gaining immense exposure and helping people.",
              style: TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Free',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    // Implement registration action
                  },
                  child: const Text(
                    'Register',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
