import 'dart:convert';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' as rendering;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';

class ReferAndEarnScreen extends StatefulWidget {
  const ReferAndEarnScreen({super.key});

  @override
  State<ReferAndEarnScreen> createState() => _ReferAndEarnScreenState();
}

class _ReferAndEarnScreenState extends State<ReferAndEarnScreen> {
  bool _isLoading = false;
  String _referralCode = "";
  int _bonusPoints = 0;
  List<dynamic> _invitedFriends = [];
  final int _maxReferrals = 5;
  String _studentName = "Student";
  final GlobalKey _globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fetchReferralData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage("assets/images/app_logo.png"), context);
    precacheImage(const AssetImage("assets/images/dmai_helper_lady.png"), context);
  }

  Future<void> _fetchReferralData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      // Token managed internally


      final response = await ApiService.getReferralData();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Also fetch profile to get name
        String name = "Student";
        try {
           final profileRes = await ApiService.getProfile();
           if (profileRes.statusCode == 200) {
             final pData = jsonDecode(profileRes.body);
             final user = pData['user'];
             name = "${user['firstName']} ${user['lastName'] ?? ''}".trim();
           }
        } catch (_) {}

        if (mounted) {
          setState(() {
            _referralCode = data['referralCode'] ?? "Generate Code";
            _bonusPoints = data['bonusPoints'] ?? 0;
            _invitedFriends = data['invitedFriends'] ?? [];
            _studentName = name;
            _isLoading = false;
          });
        }
      } else {
        // If 404 or other error, handle gracefully (e.g., allow generating first code)
        if (mounted) {
           setState(() {
             _isLoading = false;
             // Default values if no data found yet
             _referralCode = "Generate Code"; 
           });
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _isLoading = false;
        });
        CustomToast.showError(context, "${l10n.registrationFailed} $e");
      }
    }
  }

  Future<void> _shareCode() async {
    final l10n = AppLocalizations.of(context)!;
    if (_referralCode.isEmpty || _referralCode == "Generate Code") {
       CustomToast.showError(context, l10n.generateCodeFirst);
       return;
    }

    try {
      // Show loading
      CustomToast.showSuccess(context, kIsWeb ? "Sharing code..." : "Generating share image...");

      if (kIsWeb) {
         // Web doesn't support file sharing easily or path_provider, share text only
         await Share.share(
          l10n.shareTextWeb(_referralCode, 'https://play.google.com/store/apps/details?id=com.dmbhatt.tutions'),
         );
         return;
      }

      // Small delay to ensure widget is rendered if it wasn't
      await Future.delayed(const Duration(milliseconds: 100));

      rendering.RenderRepaintBoundary? boundary = _globalKey.currentContext?.findRenderObject() as rendering.RenderRepaintBoundary?;
      if (boundary == null) return;
      
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/referral_code.png').create();
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: l10n.shareTextMobile(_referralCode, 'https://play.google.com/store/apps/details?id=com.dmbhatt.tutions'),
      );
    } catch (e) {
      CustomToast.showError(context, "Error sharing: $e");
    }
  }

  void _copyCode() {
    final l10n = AppLocalizations.of(context)!;
    if (_referralCode.isEmpty || _referralCode == "Generate Code" || _referralCode == l10n.generateCode) return;
    Clipboard.setData(ClipboardData(text: _referralCode));
    CustomToast.showSuccess(context, l10n.codeCopied);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final remainingReferrals = _maxReferrals - _invitedFriends.length;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: l10n.referAndEarn,
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (_isLoading)
            const LinearProgressIndicator(minHeight: 2),
            
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                   // Header Illustration or Icon
                   Container(
                     padding: const EdgeInsets.all(24),
                     decoration: BoxDecoration(
                       color: colorScheme.primary.withOpacity(0.1),
                       shape: BoxShape.circle,
                     ),
                     child: Icon(Icons.diversity_3_rounded, size: 64, color: colorScheme.primary),
                   ),
                   const SizedBox(height: 24),
                   
                   Text(
                     l10n.referAndEarnHeader,
                     textAlign: TextAlign.center,
                     style: GoogleFonts.poppins(
                       fontSize: 20,
                       fontWeight: FontWeight.bold,
                       color: colorScheme.onSurface,
                     ),
                   ),
                   const SizedBox(height: 12),
                   Text(
                     l10n.referAndEarnSubtext,
                     textAlign: TextAlign.center,
                     style: GoogleFonts.poppins(
                       fontSize: 14,
                       color: colorScheme.onSurfaceVariant,
                     ),
                   ),
                   const SizedBox(height: 32),

                   // Referral Code Card
                   Container(
                     padding: const EdgeInsets.all(24),
                     decoration: BoxDecoration(
                       color: colorScheme.surfaceContainer,
                       borderRadius: BorderRadius.circular(20),
                       border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                       boxShadow: [
                         BoxShadow(
                           color: Colors.black.withOpacity(0.05),
                           blurRadius: 10,
                           offset: const Offset(0, 4),
                         ),
                       ],
                     ),
                     child: Column(
                       children: [
                         Text(
                           l10n.yourReferralCode,
                           style: GoogleFonts.poppins(
                             fontSize: 12,
                             fontWeight: FontWeight.w600,
                             letterSpacing: 1.5,
                             color: colorScheme.onSurfaceVariant,
                           ),
                         ),
                         const SizedBox(height: 16),
                         InkWell(
                           onTap: _copyCode,
                           borderRadius: BorderRadius.circular(12),
                           child: Container(
                             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                             decoration: BoxDecoration(
                               color: colorScheme.primary.withOpacity(0.1),
                               borderRadius: BorderRadius.circular(12),
                               border: Border.all(color: colorScheme.primary.withOpacity(0.3), style: BorderStyle.solid), // Dashed border is complex, solid for now
                             ),
                             child: Row(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 Text(
                                   _referralCode,
                                   style: GoogleFonts.poppins(
                                     fontSize: 24,
                                     fontWeight: FontWeight.bold,
                                     color: colorScheme.primary,
                                     letterSpacing: 2.0,
                                   ),
                                 ),
                                 const SizedBox(width: 12),
                                 Icon(Icons.copy_rounded, size: 20, color: colorScheme.primary),
                               ],
                             ),
                           ),
                         ),
                         const SizedBox(height: 24),
                         SizedBox(
                           width: double.infinity,
                           child: ElevatedButton.icon(
                             onPressed: remainingReferrals > 0 ? _shareCode : null,
                             icon: const Icon(Icons.share_rounded, color: Colors.white),
                             label: Text(remainingReferrals > 0 ? "Share Code" : "Limit Reached", 
                               style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
                             style: ElevatedButton.styleFrom(
                               backgroundColor: colorScheme.primary,
                               padding: const EdgeInsets.symmetric(vertical: 16),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                             ),
                           ),
                         ),
                         const SizedBox(height: 12),
                         Text(
                           remainingReferrals > 0 
                             ? "You can refer $remainingReferrals more students."
                             : "You have reached the maximum referral limit of $_maxReferrals.",
                           style: GoogleFonts.poppins(fontSize: 12, color: remainingReferrals > 0 ? Colors.green : Colors.red),
                         )
                       ],
                     ),
                   ),

                   const SizedBox(height: 32),

                   // Milestone Progress
                   Align(
                     alignment: Alignment.centerLeft,
                     child: Text(
                       l10n.referralMilestones,
                       style: GoogleFonts.poppins(
                         fontSize: 16,
                         fontWeight: FontWeight.bold,
                         color: colorScheme.onSurface,
                       ),
                     ),
                   ),
                   const SizedBox(height: 16),
                   Container(
                     padding: const EdgeInsets.all(20),
                     decoration: BoxDecoration(
                       color: colorScheme.surfaceContainer,
                       borderRadius: BorderRadius.circular(20),
                       border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                     ),
                     child: Column(
                       children: [
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: List.generate(5, (index) {
                             final milestoneNum = index + 1;
                             final isCompleted = _invitedFriends.length >= milestoneNum;
                             final isCurrent = _invitedFriends.length == index;
                             
                             return Column(
                               children: [
                                 Container(
                                   width: 40,
                                   height: 40,
                                   decoration: BoxDecoration(
                                     color: isCompleted 
                                         ? Colors.green 
                                         : isCurrent 
                                             ? colorScheme.primary 
                                             : colorScheme.surfaceContainerHighest,
                                     shape: BoxShape.circle,
                                     border: Border.all(
                                       color: isCurrent ? Colors.white : Colors.transparent,
                                       width: 2,
                                     ),
                                   ),
                                   child: Center(
                                     child: isCompleted
                                         ? const Icon(Icons.check, color: Colors.white, size: 20)
                                         : Text(
                                             "$milestoneNum",
                                             style: GoogleFonts.poppins(
                                               color: isCurrent ? Colors.white : colorScheme.onSurfaceVariant,
                                               fontWeight: FontWeight.bold,
                                             ),
                                           ),
                                   ),
                                 ),
                                 const SizedBox(height: 8),
                                 Text(
                                   "${milestoneNum * 500} pts",
                                   style: GoogleFonts.poppins(
                                     fontSize: 10,
                                     fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                     color: isCompleted ? Colors.green : isCurrent ? colorScheme.primary : colorScheme.onSurfaceVariant,
                                   ),
                                 ),
                               ],
                             );
                           }),
                         ),
                         const SizedBox(height: 20),
                         Container(
                           padding: const EdgeInsets.all(12),
                           decoration: BoxDecoration(
                             color: colorScheme.primary.withOpacity(0.05),
                             borderRadius: BorderRadius.circular(12),
                           ),
                           child: Row(
                             children: [
                               Icon(Icons.info_outline, size: 18, color: colorScheme.primary),
                               const SizedBox(width: 12),
                               Expanded(
                                 child: Text(
                                   l10n.pointsConversionNote,
                                   style: GoogleFonts.poppins(
                                     fontSize: 12,
                                     color: colorScheme.onSurfaceVariant,
                                   ),
                                 ),
                               ),
                             ],
                           ),
                         ),
                       ],
                     ),
                   ),

                   const SizedBox(height: 32),

                   // Bonus Points Display
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                     decoration: BoxDecoration(
                       gradient: LinearGradient(
                         colors: [Colors.amber.shade400, Colors.orange.shade600],
                         begin: Alignment.topLeft,
                         end: Alignment.bottomRight,
                       ),
                       borderRadius: BorderRadius.circular(16),
                       boxShadow: [
                         BoxShadow(
                           color: Colors.orange.withOpacity(0.3),
                           blurRadius: 8,
                           offset: const Offset(0, 4),
                         ),
                       ],
                     ),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(
                               l10n.totalBonusPoints,
                               style: GoogleFonts.poppins(
                                 fontSize: 14,
                                 fontWeight: FontWeight.w600,
                                 color: Colors.white,
                               ),
                             ),
                             Text(
                               "$_bonusPoints",
                               style: GoogleFonts.poppins(
                                 fontSize: 28,
                                 fontWeight: FontWeight.bold,
                                 color: Colors.white,
                               ),
                             ),
                           ],
                         ),
                         Container(
                           padding: const EdgeInsets.all(12),
                           decoration: BoxDecoration(
                             color: Colors.white.withOpacity(0.2),
                             shape: BoxShape.circle,
                           ),
                           child: const Icon(Icons.stars_rounded, color: Colors.white, size: 32),
                         ),
                       ],
                     ),
                   ),

                   const SizedBox(height: 32),

                   // Invited List
                   Align(
                     alignment: Alignment.centerLeft,
                     child: Text(
                       "Invited Friends (${_invitedFriends.length}/$_maxReferrals)",
                       style: GoogleFonts.poppins(
                         fontSize: 16,
                         fontWeight: FontWeight.bold,
                         color: colorScheme.onSurface,
                       ),
                     ),
                   ),
                   const SizedBox(height: 16),
                   if (_invitedFriends.isEmpty)
                     Container(
                       padding: const EdgeInsets.all(32),
                       alignment: Alignment.center,
                       child: Column(
                         children: [
                           Icon(Icons.person_add_disabled_rounded, size: 48, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
                           const SizedBox(height: 12),
                           Text(
                             "No friends invited yet",
                             style: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant),
                           ),
                         ],
                       ),
                     )
                   else
                     ListView.builder(
                       shrinkWrap: true,
                       physics: const NeverScrollableScrollPhysics(),
                       itemCount: _invitedFriends.length,
                       itemBuilder: (context, index) {
                         final friend = _invitedFriends[index];
                         // Assuming friend is a map {"name": "Name", "status": "Joined"}
                         final name = friend['name'] ?? "Unknown User";
                         // final date = friend['date'] ?? ""; // If available
                         
                         return Container(
                           margin: const EdgeInsets.only(bottom: 12),
                           padding: const EdgeInsets.all(16),
                           decoration: BoxDecoration(
                             color: colorScheme.surfaceContainer,
                             borderRadius: BorderRadius.circular(12),
                             border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
                           ),
                           child: Row(
                             children: [
                               CircleAvatar(
                                 backgroundColor: colorScheme.primary.withOpacity(0.1),
                                 child: Text(
                                   name.substring(0, 1).toUpperCase(),
                                   style: GoogleFonts.poppins(
                                     fontWeight: FontWeight.bold,
                                     color: colorScheme.primary,
                                   ),
                                 ),
                               ),
                               const SizedBox(width: 16),
                               Expanded(
                                 child: Text(
                                   name,
                                   style: GoogleFonts.poppins(
                                     fontSize: 16,
                                     fontWeight: FontWeight.w500,
                                     color: colorScheme.onSurface,
                                   ),
                                 ),
                               ),
                               Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                 decoration: BoxDecoration(
                                   color: Colors.green.withOpacity(0.1),
                                   borderRadius: BorderRadius.circular(20),
                                 ),
                                 child: Text(
                                   "Joined",
                                   style: GoogleFonts.poppins(
                                     fontSize: 12,
                                     fontWeight: FontWeight.bold,
                                     color: Colors.green,
                                   ),
                                 ),
                               ),
                             ],
                           ),
                         );
                       },
                     ),
                ],
              ),
            ),
            // Hidden Share Widget
            Transform.translate(
              offset: const Offset(-9999, -9999),
              child: RepaintBoundary(
                key: _globalKey,
                child: _buildShareWidget(),
              ),
            ),
          ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareWidget() {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(32),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo
          Image.asset("assets/images/app_logo.png", height: 80),
          const SizedBox(height: 24),

          // Student Friendly Image
          Image.asset("assets/images/dmai_helper_lady.png", height: 180),
          const SizedBox(height: 24),
          
          // Promo Text
          Text(
            "Use my code and discount at the time of register",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 32),

          // Referral Code Code
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).primaryColor, width: 2, style: BorderStyle.solid), // Dashed preferred but solid for simplicity
            ),
            child: Text(
              _referralCode,
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
                letterSpacing: 4.0,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Student Name
          Text(
            _studentName,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Text(
            "Using Padhaku App",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
