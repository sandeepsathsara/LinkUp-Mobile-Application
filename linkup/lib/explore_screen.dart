import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For rootBundle
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For parsing date
import 'event_map_screeen.dart';
import 'notification_screen.dart';
import 'home_screen.dart';
import 'u_event_details.dart'; // Navigate to user event details now

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  static const String _mapboxAccessToken = String.fromEnvironment("MAPBOX_ACCESS_TOKEN");

  MapboxMap? _mapboxMap;
  PointAnnotationManager? _annotationManager;
  int _selectedIndex = 1; // 'Explore' tab is index 1

  // Stores events in the current month (for map markers).
  List<Map<String, dynamic>> _eventsInThisMonth = [];

  // Cache for our custom marker image.
  Uint8List? _markerImage;

  @override
  void initState() {
    super.initState();
    if (_mapboxAccessToken.isNotEmpty) {
      MapboxOptions.setAccessToken(_mapboxAccessToken);
    } else {
      debugPrint("⚠️ MAPBOX_ACCESS_TOKEN not set. Use --dart-define.");
    }
    _loadMarkerImage();
  }

  /// Loads the custom marker image from assets.
  Future<void> _loadMarkerImage() async {
    final ByteData bytes = await rootBundle.load('assets/red_marker.png');
    setState(() {
      _markerImage = bytes.buffer.asUint8List();
    });
  }

  /// Attempts to parse a date string.
  /// Supports "yyyy-MM-dd" or "MM-dd" (assumes current year).
  DateTime? _parseDate(String dateStr) {
    dateStr = dateStr.trim();
    if (RegExp(r'^\d{2}-\d{2}$').hasMatch(dateStr)) {
      final year = DateTime.now().year;
      final combined = '$year-$dateStr'; // e.g., "2023-03-31"
      try {
        return DateFormat('yyyy-MM-dd').parse(combined);
      } catch (_) {
        return null;
      }
    } else {
      try {
        return DateFormat('yyyy-MM-dd').parse(dateStr);
      } catch (_) {
        return null;
      }
    }
  }

  /// Returns true if [dt] is in the current month and year.
  bool _isInThisMonth(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month;
  }

  /// Called once the MapWidget is created.
  Future<void> _onMapCreated(MapboxMap controller) async {
    _mapboxMap = controller;
    _annotationManager = await _mapboxMap!.annotations.createPointAnnotationManager();

    // If events in this month are already available, add markers.
    if (_eventsInThisMonth.isNotEmpty) {
      _addMarkersForMonthEvents(_eventsInThisMonth);
    }
  }

  /// Clears existing markers and adds new ones for events in the current month.
  Future<void> _addMarkersForMonthEvents(List<Map<String, dynamic>> events) async {
    if (_annotationManager == null) return;
    await _annotationManager!.deleteAll();

    for (final e in events) {
      final dateStr = (e['date'] as String?)?.trim() ?? '';
      final dt = _parseDate(dateStr);
      if (dt != null && _isInThisMonth(dt)) {
        final location = e['location'];
        if (location != null && location is GeoPoint) {
          final lat = location.latitude;
          final lng = location.longitude;
          await _annotationManager!.create(
            PointAnnotationOptions(
              geometry: Point(coordinates: Position(lng, lat)),
              image: _markerImage, // Custom marker image
              iconSize: 1.3,
            ),
          );
        }
      }
    }
  }

  /// Builds a single event card.
  Widget _buildEventCard(Map<String, dynamic> event) {
    final String? imageUrl = event['imageUrl'] as String?;
    final String eventName = event['eventName'] ?? 'No Title';
    final String date = event['date'] ?? 'No Date';

    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.blueAccent,
      ),
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(right: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display event image.
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/march.png',
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
                : Image.asset(
              'assets/march.png',
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              eventName,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            date,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  /// Builds a category section with horizontal scrolling event cards.
  /// Returns an empty widget if there are no events in that category.
  Widget _buildCategorySection(String title, List<Map<String, dynamic>> events) {
    if (events.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header.
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text("View More"),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: events.length,
            itemBuilder: (context, index) {
              final rawEvent = events[index];
              final docId = rawEvent['id']; // ✅ Use already-attached ID
              final event = Map<String, dynamic>.from(rawEvent);
              event['id'] = docId;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserEventDetailsScreen(event: event),
                    ),
                  );
                },
                child: _buildEventCard(event),
              );

            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.95),
        elevation: 0,
        title: TextField(
          decoration: InputDecoration(
            hintText: "Explore Upcoming Events",
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[200],
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background map.
          MapWidget(
            key: const ValueKey("explore_map"),
            styleUri: MapboxStyles.MAPBOX_STREETS,
            textureView: true,
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(80.7718, 7.8731)),
              zoom: 5.0,
            ),
            onMapCreated: _onMapCreated,
          ),
          // Foreground DraggableScrollableSheet.
          DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.3,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return SafeArea(
                top: false,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('events')
                              .orderBy('createdAt', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(child: Text("Error: ${snapshot.error}"));
                            }
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.data!.docs.isEmpty) {
                              return const Center(child: Text("No events found."));
                            }

                            final docs = snapshot.data!.docs;
                            final allEvents = docs
                                .map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              data['id'] = doc.id; // ✅ Attach the ID here
                              return data;
                            })
                                .toList();


                            // Clear and rebuild the events for the current month.
                            _eventsInThisMonth = [];
                            final popularNow = <Map<String, dynamic>>[];
                            final techDev = <Map<String, dynamic>>[];
                            final business = <Map<String, dynamic>>[];

                            for (final e in allEvents) {
                              final dateStr = (e['date'] as String?)?.trim() ?? '';
                              final dt = _parseDate(dateStr);
                              if (dt != null && _isInThisMonth(dt)) {
                                _eventsInThisMonth.add(e);
                              }
                              final cat = e['category'] as String? ?? 'Uncategorized';
                              if (cat == 'Popular') {
                                popularNow.add(e);
                              } else if (cat == 'Tech & Development') {
                                techDev.add(e);
                              } else if (cat == 'Business & Networking') {
                                business.add(e);
                              }
                            }

                            // If annotation manager is ready, add markers.
                            if (_annotationManager != null) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _addMarkersForMonthEvents(_eventsInThisMonth);
                              });
                            }

                            return ListView(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 15),
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Explore Events",
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const EventMapScreen()),
                                        );
                                      },
                                      icon: const Icon(Icons.map),
                                      label: const Text("View Map"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueAccent,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // Only show non-empty categories.
                                _buildCategorySection("Popular Now", popularNow),
                                _buildCategorySection("Tech & Development", techDev),
                                _buildCategorySection("Business & Networking", business),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: false,
        elevation: 5,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
          } else if (index == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ExplorePage()));
          } else if (index == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
          }
          // index 2 or 4: handle if needed.
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
