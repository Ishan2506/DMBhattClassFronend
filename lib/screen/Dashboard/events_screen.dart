import 'dart:convert';
import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/event_gallery_screen.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  late Future<List<dynamic>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = _fetchEvents();
  }

  Future<List<dynamic>> _fetchEvents() async {
    try {
      final response = await ApiService.getAllEvents();
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load events');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(
        title: "Events",
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CustomLoader());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "No events found",
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            );
          }

          final events = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _buildEventCard(context, event);
            },
          );
        },
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Map<String, dynamic> event) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Process images
    List<String> photos = [];
    String? coverImage;
    if (event['images'] != null && (event['images'] as List).isNotEmpty) {
       // Assuming backend returns relative paths or full URLs. 
       // If relative, might need to prepend base URL. 
       // For now assuming full URL or handling locally.
       // Adjust based on your backend 'uploads/...' path serving.
       // You might need a helper to construct full URL.
       photos = List<String>.from(event['images'].map((e) => e.toString()));
       coverImage = photos.first; 
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventGalleryScreen(
              eventTitle: event['title'] ?? 'Event',
              photos: photos,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Cover Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: coverImage != null 
                 ? Image.network(
                    // Construct full URL if needed. 
                    // Example: "http://localhost:5000/$coverImage"
                    // Ideally ApiService should have a method or constant for Image Base URL.
                    // For now, assuming backend serves static files correctly or returns full URL.
                    // If it returns "uploads/file.jpg", we need base URL.
                    ApiService.getFileUrl(coverImage), 
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        color: colorScheme.surfaceContainerHigh,
                        child: Center(child: Icon(Icons.broken_image, size: 50, color: colorScheme.onSurfaceVariant)),
                      );
                    },
                   )
                 : Container(
                    height: 180,
                    color: colorScheme.surfaceContainerHigh,
                    child: Center(child: Icon(Icons.event, size: 50, color: colorScheme.onSurfaceVariant)),
                  ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          event['title'] ?? "No Title",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                       Text(
                        event['date'] != null 
                            ? DateFormat('MMM dd, yyyy').format(DateTime.parse(event['date'])) 
                            : "",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (event['description'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      event['description'],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    "Tap to view gallery",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
