import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dm_bhatt_tutions/model/mind_map_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';

class MindMapScreen extends StatefulWidget {
  final MindMapModel mindMap;
  const MindMapScreen({super.key, required this.mindMap});

  @override
  State<MindMapScreen> createState() => _MindMapScreenState();
}

class _MindMapScreenState extends State<MindMapScreen> with SingleTickerProviderStateMixin {
  bool _isLandscape = false;
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    // Default to portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    _bgController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  void _toggleOrientation() {
    setState(() {
      _isLandscape = !_isLandscape;
      if (_isLandscape) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
      }
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), 
      appBar: CustomAppBar(
        title: widget.mindMap.unit,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
            ]);
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            onPressed: _toggleOrientation,
            icon: Icon(
              _isLandscape ? Icons.screen_lock_portrait : Icons.screen_lock_landscape,
              color: Colors.white,
            ),
            tooltip: "Switch to ${_isLandscape ? 'Portrait' : 'Landscape'}",
          )
        ],
      ),
      body: Stack(
        children: [
          // Animated Light Background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, child) {
                return CustomPaint(
                  painter: LightBackgroundPainter(
                    animationValue: _bgController.value,
                  ),
                );
              },
            ),
          ),
          // Mind Map Content
          InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(3000), 
            minScale: 0.1,
            maxScale: 2.5,
            child: OverflowBox(
              minWidth: 0.0,
              maxWidth: double.infinity,
              minHeight: 0.0,
              maxHeight: double.infinity,
              child: Center(
                child: MindMapTreeNodeWidget(
                  node: widget.mindMap.root,
                  isRoot: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LightBackgroundPainter extends CustomPainter {
  final double animationValue;
  LightBackgroundPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Drawing light "dust" or particles
    final random = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < 20; i++) {
      // Logic to create moving orbs
      final double x = ( (i * 12345 + random) % size.width.toInt() ).toDouble();
      final double y = ( (size.height - (animationValue * size.height + i * 100) % size.height) );
      
      final double radius = (i % 5 + 2).toDouble();
      final double opacity = 0.1 + (i % 10) / 100;
      
      paint.color = Colors.blueAccent.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius * 5, paint);
      
      // Secondary glow
      paint.color = Colors.white.withAlpha((opacity * 255 * 0.5).toInt());
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant LightBackgroundPainter oldDelegate) => true;
}

class MindMapTreeNodeWidget extends StatefulWidget {
  final MindMapNode node;
  final bool isRoot;

  const MindMapTreeNodeWidget({
    super.key,
    required this.node,
    this.isRoot = false,
  });

  @override
  State<MindMapTreeNodeWidget> createState() => _MindMapTreeNodeWidgetState();
}

class _MindMapTreeNodeWidgetState extends State<MindMapTreeNodeWidget> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    if (widget.isRoot) {
      _isExpanded = true;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasChildren = widget.node.children.isNotEmpty;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Node Box
        GestureDetector(
          onTap: hasChildren ? _toggleExpand : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.isRoot 
                    ? [primaryColor, primaryColor.withOpacity(0.8)] 
                    : [const Color(0xFF334155), const Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isRoot ? Colors.white.withOpacity(0.5) : primaryColor.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    widget.node.name,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: widget.isRoot ? FontWeight.bold : FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (hasChildren) ...[
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.remove_circle_outline : Icons.add_circle_outline,
                    color: Colors.white.withOpacity(0.8),
                    size: 18,
                  ),
                ],
              ],
            ),
          ),
        ),

        // Connections and Children
        if (hasChildren)
          SizeTransition(
            sizeFactor: _expandAnimation,
            axis: Axis.horizontal,
            axisAlignment: -1.0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Main Horizontal Trunk
                Container(
                  width: 40,
                  height: 2,
                  color: primaryColor.withOpacity(0.4),
                ),
                // Children Stack with vertical spine
                Stack(
                  children: [
                    // Vertical Spine
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: 0,
                      child: Container(
                        width: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor.withOpacity(0.0),
                              primaryColor.withOpacity(0.4),
                              primaryColor.withOpacity(0.4),
                              primaryColor.withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.1, 0.9, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Children Column
                    Padding(
                      padding: const EdgeInsets.only(left: 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widget.node.children.map((child) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Side Branch from spine to child
                              Container(
                                width: 20,
                                height: 2,
                                color: primaryColor.withOpacity(0.4),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: MindMapTreeNodeWidget(node: child),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
