import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:dio/dio.dart';
//import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';

class EventGalleryScreen extends StatelessWidget {
  final String eventTitle;
  final List<dynamic> photos;

  const EventGalleryScreen({super.key, required this.eventTitle, required this.photos});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: eventTitle,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // Smaller images
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.0,
        ),
        itemCount: photos.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GestureDetector(
               onTap: () {
                 // Open full screen image viewer if needed
                 _showFullScreenImage(context, photos[index]);
               },
              child: Image.asset(
                photos[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: colorScheme.surfaceContainerHigh,
                    child: const Icon(Icons.broken_image),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imagePath) {
    final colorScheme = Theme.of(context).colorScheme;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black, // Keeping black background for better image viewing
          appBar: CustomAppBar(
            title: "Event Photo",
            actions: [
               IconButton(
                 icon: const Icon(Icons.download, color: Colors.white),
                 onPressed: (){},
                 //onPressed: () => _saveImage(context, imagePath),
               ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.asset(imagePath),
            ),
          ),
        ),
      ),
    );
  }

  // Future<void> _saveImage(BuildContext context, String assetPath) async {
  //   try {
  //     // Logic to save asset image to gallery
  //     // 1. Get bytes from asset
  //     final byteData = await rootBundle.load(assetPath);
  //     final bytes = byteData.buffer.asUint8List();

  //     // 2. Save to gallery
  //     final result = await ImageGallerySaver.saveImage(
  //       bytes,
  //       quality: 100,
  //       name: "dmbhatt_event_${DateTime.now().millisecondsSinceEpoch}",
  //     );

  //     if (result['isSuccess'] == true) {
  //        if(context.mounted) CustomToast.showSuccess(context, "Image saved to gallery");
  //     } else {
  //        if(context.mounted) CustomToast.showError(context, "Failed to save image");
  //     }
  //   } catch (e) {
  //     if(context.mounted) CustomToast.showError(context, "Error: $e");
  //   }
  // }
}
