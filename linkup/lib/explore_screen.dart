import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'event_map_screeen.dart';
import 'notification_screen.dart';
import 'home_screen.dart';
import 'u_event_details.dart';
import 'profile_screen.dart';
import 'tech_dev_events_screen.dart';
import 'bus_net_events_screen.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({Key? key}) : super(key: key);

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  // Controller for flutter_map
  final MapController _mapController = MapController();

  int _selectedIndex = 2; // 'Explore' tab index

  // In-memory cache for events.
  List<Map<String, dynamic>> _cachedEvents = [];
  bool _hasLoadedEvents = false;

  // Stores events in the current month.
  List<Map<String, dynamic>> _eventsInThisMonth = [];

  // Holds search-filtered events.
  List<Map<String, dynamic>> _filteredEvents = [];

  // Helps update markers only when displayed events change.
  List<Map<String, dynamic>> _lastDisplayedEvents = [];

  // Cache for our custom marker image.
  Uint8List? _markerImage;

  // List of markers for flutter_map.
  List<Marker> _markers = [];

  // Controller for the search field.
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
      final combined = '$year-$dateStr';
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

  /// Updates markers for the given events.
  void _updateMarkersForEvents(List<Map<String, dynamic>> events) {
    List<Marker> markers = [];
    for (final e in events) {
      final dateStr = (e['date'] as String?)?.trim() ?? '';
      final dt = _parseDate(dateStr);
      if (dt != null && _isInThisMonth(dt)) {
        final location = e['location'];
        if (location != null && location is GeoPoint) {
          final lat = location.latitude;
          final lng = location.longitude;
          markers.add(
            Marker(
              point: LatLng(lat, lng),
              width: 40,
              height: 40,
              child: _markerImage != null
                  ? Image.memory(_markerImage!, width: 40, height: 40)
                  : const Icon(Icons.location_on, color: Colors.red, size: 40),
            ),
          );
        }
      }
    }
    setState(() {
      _markers = markers;
    });
  }

  /// Search function to filter events and center the map.
  void _searchAndCenterEvent(String query) {
    if (_eventsInThisMonth.isEmpty) return;

    final results = _eventsInThisMonth.where((e) {
      final name = (e['eventName'] as String?)?.toLowerCase().trim() ?? '';
      return name.contains(query.toLowerCase().trim());
    }).toList();

    setState(() {
      _filteredEvents = results;
    });

    _updateMarkersForEvents(results);

    if (results.isNotEmpty && results.first['location'] is GeoPoint) {
      final loc = results.first['location'] as GeoPoint;
      _mapController.move(LatLng(loc.latitude, loc.longitude), 10);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No matching events found.")),
      );
    }
  }

  /// Builds a single event card using CachedNetworkImage.
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
          // Display event image with caching.
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? CachedNetworkImage(
              imageUrl: imageUrl,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => Image.asset(
                'assets/march.png',
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              errorWidget: (_, __, ___) => Image.asset(
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
                onPressed: () {
                  if (title == 'Tech & Development') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TechDevEventsScreen(),
                      ),
                    );
                  } else if (title == 'Business & Networking') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BusinessNetworkingScreen(),
                      ),
                    );
                  }
                },
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
              final docId = rawEvent['id'];
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
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.pop(context, true);
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.white.withOpacity(0.95),
          elevation: 0,
          // Live search field.
          title: TextField(
            controller: _searchController,
            onChanged: (value) {
              if (value.trim().isEmpty) {
                setState(() {
                  _filteredEvents.clear();
                });
                _updateMarkersForEvents(_eventsInThisMonth);
              } else {
                _searchAndCenterEvent(value);
              }
            },
            decoration: InputDecoration(
              hintText: "Search by Event Name",
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
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(7.8731, 80.7718),
                initialZoom: 5.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: _markers,
                ),
              ],
            ),
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
                      borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 10)
                      ],
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
                            stream: !_hasLoadedEvents
                                ? FirebaseFirestore.instance
                                .collection('events')
                                .orderBy('createdAt', descending: true)
                                .snapshots()
                                : const Stream.empty(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Center(
                                    child: Text("Error: ${snapshot.error}"));
                              }
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              if (!_hasLoadedEvents && snapshot.hasData) {
                                final docs = snapshot.data!.docs;
                                _cachedEvents = docs.map((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  data['id'] = doc.id;
                                  return data;
                                }).toList();
                                _hasLoadedEvents = true;
                              }

                              // Filter events for current month.
                              _eventsInThisMonth = _cachedEvents.where((e) {
                                final dateStr =
                                    (e['date'] as String?)?.trim() ?? '';
                                final dt = _parseDate(dateStr);
                                return dt != null && _isInThisMonth(dt);
                              }).toList();

                              // Determine which events to display.
                              final toDisplay = _filteredEvents.isNotEmpty
                                  ? _filteredEvents
                                  : _eventsInThisMonth;

                              // Update markers if displayed events change.
                              if (_lastDisplayedEvents.isEmpty ||
                                  !listEquals(_lastDisplayedEvents, toDisplay)) {
                                _lastDisplayedEvents = List.from(toDisplay);
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  _updateMarkersForEvents(toDisplay);
                                });
                              }

                              return ListView(
                                controller: scrollController,
                                padding:
                                const EdgeInsets.symmetric(horizontal: 15),
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

                                  // Show filtered results if search is active, otherwise show category cards
                                  if (_filteredEvents.isNotEmpty)
                                    _buildCategorySection("Search Results", _filteredEvents)
                                  else ...[
                                    _buildCategorySection(
                                      "Popular Now",
                                      _cachedEvents.where((e) =>
                                      (e['category'] as String?)?.trim() == 'Popular').toList(),
                                    ),
                                    _buildCategorySection(
                                      "Tech & Development",
                                      _cachedEvents.where((e) =>
                                      (e['category'] as String?)?.trim() == 'Tech & Development').toList(),
                                    ),
                                    _buildCategorySection(
                                      "Business & Networking",
                                      _cachedEvents.where((e) =>
                                      (e['category'] as String?)?.trim() == 'Business & Networking').toList(),
                                    ),
                                  ],
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
          currentIndex: 1, // Highlight Explore tab.
          onTap: (index) {
            if (index == 0) {
              Navigator.pop(context, true);
            } else if (index == 1) {
              // Already in Explore.
            } else if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const NotificationScreen()),
              ).then((_) {
                if (mounted) setState(() {});
              });
            } else if (index == 3) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ).then((_) {
                if (mounted) setState(() {});
              });
            }
          },
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.explore), label: 'Explore'),
            BottomNavigationBarItem(
                icon: Icon(Icons.notifications), label: 'Alerts'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
