import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditEventScreen extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> eventData;

  const EditEventScreen({
    super.key,
    required this.eventId,
    required this.eventData,
  });

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final TextEditingController eventNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final TextEditingController venueController = TextEditingController();
  final TextEditingController linkController = TextEditingController();
  final TextEditingController paymentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize the controllers with data from the event
    eventNameController.text = widget.eventData['eventName'] ?? '';
    descriptionController.text = widget.eventData['description'] ?? '';
    dateController.text = widget.eventData['date'] ?? '';
    timeController.text = widget.eventData['time'] ?? '';
    venueController.text = widget.eventData['venue'] ?? '';
    linkController.text = widget.eventData['registrationLink'] ?? '';
    paymentController.text = widget.eventData['payment'] ?? '';
  }

  @override
  void dispose() {
    eventNameController.dispose();
    descriptionController.dispose();
    dateController.dispose();
    timeController.dispose();
    venueController.dispose();
    linkController.dispose();
    paymentController.dispose();
    super.dispose();
  }

  Future<void> _updateEvent() async {
    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .update({
        'eventName': eventNameController.text.trim(),
        'description': descriptionController.text.trim(),
        'date': dateController.text.trim(),
        'time': timeController.text.trim(),
        'venue': venueController.text.trim(),
        'registrationLink': linkController.text.trim(),
        'payment': paymentController.text.trim(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event updated successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update Error: $e')),
      );
    }
  }

  Widget _buildTextField(
      TextEditingController controller,
      String hint,
      IconData icon, {
        bool isMultiLine = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: isMultiLine ? 3 : 1,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Light background for modern look
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Event',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage('assets/profile.jpg'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upload Image Section (if you plan to allow image changes)
            Center(
              child: GestureDetector(
                onTap: () {
                  // Handle image upload if needed
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_photo_alternate,
                    size: 40,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            // Form Fields
            _buildTextField(eventNameController, 'Event Name', Icons.event),
            _buildTextField(
              descriptionController,
              'Event Description',
              Icons.description,
              isMultiLine: true,
            ),
            _buildTextField(dateController, 'Event Date', Icons.calendar_today),
            _buildTextField(timeController, 'Event Time', Icons.access_time),
            _buildTextField(venueController, 'Event Venue', Icons.location_on),
            _buildTextField(linkController, 'Event Registration Link', Icons.link),
            _buildTextField(paymentController, 'Event Payment', Icons.attach_money),
            const SizedBox(height: 30),
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: const BorderSide(color: Colors.blueAccent),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16, color: Colors.blueAccent),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _updateEvent,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    backgroundColor: Colors.blueAccent,
                    shadowColor: Colors.blue.withOpacity(0.4),
                    elevation: 5,
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
