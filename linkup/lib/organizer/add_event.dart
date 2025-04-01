import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For rootBundle
import 'package:image_picker/image_picker.dart' as picker;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart'; // For formatting date/time
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
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

  late MapboxMap _mapboxMap;
  PointAnnotationManager? _annotationManager;

  /// For showing/hiding the loading dialog
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Set access token if provided via environment variable.
    const token = String.fromEnvironment("ACCESS_TOKEN");
    if (token.isNotEmpty) {
      MapboxOptions.setAccessToken(token);
    }
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
      await _firestore.collection('events').add({
        'uid': uid,
        'eventName': eventNameController.text.trim(),
        'description': descriptionController.text.trim(),
        'date': dateController.text.trim(),
        'time': timeController.text.trim(),
        'venue': venueController.text.trim(),
        'registrationLink': linkController.text.trim(),
        'payment': paymentController.text.trim(),
        'category': _selectedCategory, // Save the category here.
        'imageUrl': _uploadedImageUrl,
        'location': GeoPoint(selectedLatitude!, selectedLongitude!),
        'createdAt': FieldValue.serverTimestamp(),
      });
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
                  child: MapWidget(
                    key: const ValueKey("map_popup"),
                    styleUri: MapboxStyles.MAPBOX_STREETS,
                    textureView: true,
                    cameraOptions: CameraOptions(
                      center: Point(coordinates: Position(80.7718, 7.8731)),
                      zoom: 5,
                    ),
                    onMapCreated: (mapboxMap) async {
                      _mapboxMap = mapboxMap;
                      _annotationManager = await _mapboxMap.annotations.createPointAnnotationManager();
                    },
                    onTapListener: (MapContentGestureContext gestureContext) async {
                      final point = gestureContext.point;
                      final lat = (point.coordinates[1] as num).toDouble();
                      final lng = (point.coordinates[0] as num).toDouble();
                      setState(() {
                        selectedLatitude = lat;
                        selectedLongitude = lng;
                      });
                      _annotationManager?.deleteAll();
                      final ByteData imageData = await rootBundle.load('assets/red_marker.png');
                      Uint8List markerImage = imageData.buffer.asUint8List();
                      await _annotationManager?.create(
                        PointAnnotationOptions(
                          geometry: Point(coordinates: Position(lng, lat)),
                          image: markerImage,
                        ),
                      );
                    },
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
