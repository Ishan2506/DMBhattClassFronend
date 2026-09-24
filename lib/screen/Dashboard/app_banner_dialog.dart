import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Popup showing the banners uploaded from the admin panel.
/// Multiple active banners are swipeable, with page dots underneath.
class AppBannerDialog extends StatefulWidget {
  final List<Map<String, dynamic>> banners;

  const AppBannerDialog({super.key, required this.banners});

  static bool _linkOpened = false;

  /// Whether the app was last sent to the background by tapping a banner link.
  /// Resets on read, so only the return from that link is affected.
  static bool consumeLinkOpened() {
    final opened = _linkOpened;
    _linkOpened = false;
    return opened;
  }

  /// Fetches active banners and shows them, if there are any.
  /// Waits for the first image to load so the popup never opens blank.
  static Future<void> showIfAvailable(BuildContext context) async {
    final banners = (await ApiService.getActiveBanners())
        .where((b) => ApiService.getFileUrl(b['image']?.toString()).isNotEmpty)
        .toList();
    if (banners.isEmpty || !context.mounted) return;

    try {
      await precacheImage(
        NetworkImage(ApiService.getFileUrl(banners.first['image'].toString())),
        context,
      );
    } catch (e) {
      debugPrint("Banner image failed to load: $e");
      return;
    }
    // Only over the screen that asked for it — not over an exam, the paywall
    // or another popup the student opened while the banner was loading.
    if (!context.mounted || ModalRoute.of(context)?.isCurrent != true) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AppBannerDialog(banners: banners),
    );
  }

  @override
  State<AppBannerDialog> createState() => _AppBannerDialogState();
}

class _AppBannerDialogState extends State<AppBannerDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openLink(String? link) async {
    if (link == null || link.trim().isEmpty) return;
    final uri = Uri.tryParse(link.trim());
    if (uri == null) return;
    AppBannerDialog._linkOpened = true;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      AppBannerDialog._linkOpened = false;
      debugPrint('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bannerHeight = size.height * 0.6;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: bannerHeight,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.banners.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                final banner = widget.banners[index];
                // Center gives the image loose constraints, so the Stack hugs
                // the image's real size and the close button lands on its corner.
                return Center(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _openLink(banner['link']?.toString()),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            ApiService.getFileUrl(banner['image']?.toString()),
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, progress) =>
                                progress == null
                                    ? child
                                    : const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      ),
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.white70,
                                    size: 48,
                                  ),
                                ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black26, blurRadius: 6),
                              ],
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.black87,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (widget.banners.length > 1) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.banners.length, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 18 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}
