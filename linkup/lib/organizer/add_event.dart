import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For rootBundle
import 'package:image_picker/image_picker.dart' as picker;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart'; // For formatting date/time
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final MapController _mapController = MapController();
  final eventNameController = TextEditingController();
  final descriptionController = TextEditingController();
  final dateController = TextEditingController();
  final timeController = TextEditingController();
  final venueController = TextEditingController();
  final linkController = TextEditingController();
  final paymentController = TextEditingController();

  // New variable for category
  String? _selectedCategory = "Tech & Development";

  File? _imageFile;
  String? _uploadedImageUrl;
  double? selectedLatitude;
  double? selectedLongitude;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  /// For showing/hiding the loading dialog
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Removed Mapbox access token initialization since we are not using Mapbox.
  }

  /// Confirm exit if user tries to go back with unsaved data.
  Future<bool?> _confirmExitPopup() async {
    if (_formIsEmpty()) {
      // If no data is filled, allow exit immediately.
      return true;
    }
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Discard Changes?"),
        content: const Text("Are you sure you want to leave without saving?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  /// Check if form is essentially empty.
  bool _formIsEmpty() {
    return eventNameController.text.isEmpty &&
        descriptionController.text.isEmpty &&
        dateController.text.isEmpty &&
        timeController.text.isEmpty &&
        venueController.text.isEmpty &&
        linkController.text.isEmpty &&
        paymentController.text.isEmpty &&
        _imageFile == null &&
        selectedLatitude == null &&
        selectedLongitude == null;
  }

  /// Show loading dialog while uploading.
  void _showLoadingDialog() {
    setState(() => _isUploading = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
  }

  /// Hide loading dialog.
  void _hideLoadingDialog() {
    if (_isUploading) {
      Navigator.of(context).pop();
      setState(() => _isUploading = false);
    }
  }

  Future<void> _pickImage() async {
    final picked = await picker.ImagePicker().pickImage(
      source: picker.ImageSource.gallery,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _uploadToCloudinary() async {
    if (_imageFile == null) return;
    const cloudName = 'do7drlcop';
    const uploadPreset = 'LinkUp';
    // Generate a unique public id so that the image is placed in the "events" folder.
    final publicId = 'events/${DateTime.now().millisecondsSinceEpoch}';
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(_imageFile!.path),
      'upload_preset': uploadPreset,
      'folder': 'events',
      'public_id': publicId,
    });
    final response = await Dio().post(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      data: formData,
    );
    if (response.statusCode == 200) {
      _uploadedImageUrl = response.data['secure_url'];
    } else {
      throw Exception('Image upload failed');
    }
  }

  Future<void> _saveEvent() async {
    if (eventNameController.text.isEmpty ||
        _imageFile == null ||
        selectedLatitude == null ||
        selectedLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and select location.")),
      );
      return;
    }

    _showLoadingDialog();

    try {
      await _uploadToCloudinary();
      final uid = _auth.currentUser?.uid;

      // 1. Prepare event data
      final eventData = {
        'uid': uid,
        'eventName': eventNameController.text.trim(),
        'description': descriptionController.text.trim(),
        'date': dateController.text.trim(),
        'time': timeController.text.trim(),
        'venue': venueController.text.trim(),
        'registrationLink': linkController.text.trim(),
        'payment': paymentController.text.trim(),
        'category': _selectedCategory,
        'imageUrl': _uploadedImageUrl,
        'location': GeoPoint(selectedLatitude!, selectedLongitude!),
        'createdAt': FieldValue.serverTimestamp(),
      };

      // 2. Save to `events` collection
      final eventRef = await _firestore.collection('events').add(eventData);

      // 3. Add notification to `notifications` collection
      await _firestore.collection('notifications').add({
        'title': "New Event Added: ${eventData['eventName']}",
        'category': _selectedCategory,
        'createdAt': FieldValue.serverTimestamp(),
        'event': {
          'id': eventRef.id,
          'eventName': eventData['eventName'],
          'date': eventData['date'],
          'venue': eventData['venue'],
          'imageUrl': eventData['imageUrl'],
          'description': eventData['description'],
          'category': eventData['category'],
        },
      });

      // 🔔 Send push notification to users
      try {
        await Dio().post(
          'http://54.153.235.2:5000/send',
          options: Options(headers: {'Content-Type': 'application/json'}),
          data: {
            "title": "🚀 New Event: ${eventData['eventName']}",
            "body": "Don't miss out! Happening at ${eventData['venue']} on ${eventData['date']}.",
          },
        );
      } catch (e) {
        debugPrint("Notification send failed: $e");
      }

      _hideLoadingDialog();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event added successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      _hideLoadingDialog();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  /// Bottom sheet to pick location with a red marker.
  void _openMapPopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        LatLng? tappedLocation;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Column(
                  children: [
                    Expanded(
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: LatLng(7.8731, 80.7718),
                          initialZoom: 5,
                          onLongPress: (tapPosition, latlng) { // 👈 changed to long press
                            setModalState(() {
                              tappedLocation = latlng;
                            });
                            setState(() {
                              selectedLatitude = latlng.latitude;
                              selectedLongitude = latlng.longitude;
                            });
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                            subdomains: const ['a', 'b', 'c'],
                          ),
                          MarkerLayer(
                            markers: tappedLocation != null
                                ? [
                              Marker(
                                point: tappedLocation!,
                                width: 40,
                                height: 40,
                                child: Image.asset(
                                  'assets/red_marker.png',
                                  width: 40,
                                  height: 40,
                                ),
                              )
                            ]
                                : [],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Confirm Location",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (selected != null) {
      dateController.text = DateFormat('yyyy-MM-dd').format(selected);
    }
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (selected != null) {
      timeController.text = selected.format(context);
    }
  }

  Widget _buildTextField(
      TextEditingController controller,
      String hint,
      IconData icon, {
        bool isMultiLine = false,
        VoidCallback? onTap,
        bool readOnly = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: isMultiLine ? 3 : 1,
        style: const TextStyle(fontSize: 16),
        onTap: onTap,
        readOnly: readOnly,
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

  /// Dropdown for Category.
  Widget _buildCategoryDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: _selectedCategory,
        items: const [
          DropdownMenuItem(
            value: "Tech & Development",
            child: Text("Tech & Development"),
          ),
          DropdownMenuItem(
            value: "Business & Networking",
            child: Text("Business & Networking"),
          ),
        ],
        onChanged: (value) {
          setState(() {
            _selectedCategory = value;
          });
        },
        decoration: InputDecoration(
          hintText: "Select Category",
          prefixIcon: const Icon(Icons.category, color: Colors.blueAccent),
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
    return WillPopScope(
      onWillPop: () async {
        final confirm = await _confirmExitPopup();
        return confirm ?? false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () async {
              final confirm = await _confirmExitPopup();
              if (confirm == true) {
                Navigator.pop(context);
              }
            },
          ),
          title: const Text(
            'Add Event',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pick image.
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 6)],
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(_imageFile!, fit: BoxFit.cover),
                    )
                        : const Icon(Icons.add_photo_alternate, size: 40, color: Colors.blueAccent),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              // Event name.
              _buildTextField(eventNameController, 'Event Name', Icons.event),
              // Category dropdown.
              _buildCategoryDropdown(),
              // Description.
              _buildTextField(
                descriptionController,
                'Description',
                Icons.description,
                isMultiLine: true,
              ),
              // Date (with date picker).
              _buildTextField(
                dateController,
                'Date',
                Icons.calendar_today,
                onTap: _pickDate,
                readOnly: true,
              ),
              // Time (with time picker).
              _buildTextField(
                timeController,
                'Time',
                Icons.access_time,
                onTap: _pickTime,
                readOnly: true,
              ),
              // Venue.
              _buildTextField(venueController, 'Venue', Icons.location_on),
              // Location tile (map) – placed after the venue.
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                tileColor: Colors.white,
                leading: const Icon(Icons.map, color: Colors.blueAccent),
                title: Text(
                  selectedLatitude == null
                      ? 'Select Location on Map'
                      : 'Location: ($selectedLatitude, $selectedLongitude)',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _openMapPopup,
              ),
              const SizedBox(height: 10),
              // Registration link.
              _buildTextField(linkController, 'Registration Link', Icons.link),
              // Payment.
              _buildTextField(paymentController, 'Payment', Icons.attach_money),
              const SizedBox(height: 30),
              // Buttons.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      final confirm = await _confirmExitPopup();
                      if (confirm == true) {
                        Navigator.pop(context);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: const BorderSide(color: Colors.blueAccent),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 16, color: Colors.blueAccent)),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _saveEvent,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: Colors.blueAccent,
                      shadowColor: Colors.blue.withOpacity(0.4),
                      elevation: 5,
                    ),
                    child: const Text('Save', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
