import 'dart:convert';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/utils/database_helper.dart';
import 'package:dm_bhatt_tutions/screen/authentication/welcome_screen.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/mcq_Detail.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/edit_profile_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/add_account_screen.dart';
import 'package:dm_bhatt_tutions/screen/authentication/register_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/landing_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/student_exam_history_screen.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/screen/authentication/login_screen.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:dm_bhatt_tutions/constant/app_images.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();


  static Future<void> showSwitchAccountSheet(BuildContext context) async {
    final db = DatabaseHelper();
    final prefs = await SharedPreferences.getInstance();
    
    // Fetch all saved accounts from SQLite
    List<Map<String, dynamic>> accounts = await db.getAccounts();
    String currentToken = prefs.getString('auth_token') ?? "";

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
         final theme = Theme.of(context);
         final l10n = AppLocalizations.of(context)!;
         return Container(
          padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 40),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                 child: Container(
                   width: 50, height: 5,
                   decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))
                 )
              ),
              const SizedBox(height: 24),
              Text(l10n.switchProfile, 
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)
              ),
              const SizedBox(height: 24),
              
              ...accounts.map((acc) {
                 bool isActive = acc['token'] == currentToken;
                 return Container(
                   margin: const EdgeInsets.only(bottom: 12),
                   decoration: BoxDecoration(
                     color: isActive ? theme.colorScheme.primary.withOpacity(0.05) : theme.cardColor,
                     borderRadius: BorderRadius.circular(16),
                     border: Border.all(
                       color: isActive ? theme.colorScheme.primary : Colors.grey.shade200,
                       width: isActive ? 1.5 : 1
                     ),
                   ),
                   child: ListTile(
                     contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                     leading: CircleAvatar(
                       radius: 24,
                       backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                       backgroundImage: (acc['profilePic'] != null && acc['profilePic'].toString().isNotEmpty) 
                           ? NetworkImage(acc['profilePic']) 
                           : null,
                       child: (acc['profilePic'] == null || acc['profilePic'].toString().isEmpty)
                           ? Text(
                               (acc['name'] ?? "U")[0].toUpperCase(), 
                               style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)
                             )
                           : null,
                     ),
                     title: Text(
                        acc['name'] ?? "User", 
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)
                     ),
                     subtitle: Text(
                        acc['phone'] ?? "", 
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600)
                     ),
                     trailing: isActive 
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : IconButton(
                            icon: const Icon(Icons.logout, color: Colors.red, size: 20),
                            onPressed: () => _logoutAccount(context, acc),
                          ),
                     onTap: () {
                       if (!isActive) {
                         Navigator.pop(context);
                         _switchUser(context, acc);
                       }
                     },
                   ),
                 );
              }).toList(),
              
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                           Navigator.pop(context);
                           Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen(isAddAccount: true)));
                        },
                        icon: const Icon(Icons.add),
                        label: Text(l10n.logInExisting),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  static Future<void> _logoutAccount(BuildContext context, Map<String, dynamic> account) async {
    final db = DatabaseHelper();
    final prefs = await SharedPreferences.getInstance();
    
    // Call backend logout
    try {
      await ApiService.logoutUser(account['token']);
    } catch (e) {
      debugPrint("Logout error: $e");
    }

    // Delete from DB
    await db.deleteAccount(account['userId']);
    
    // If it was active, clear prefs and go to welcome
    String currentToken = prefs.getString('auth_token') ?? "";
    if (account['token'] == currentToken) {
      await ApiService.clearAuthToken();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
      }
    } else {
      if (context.mounted) {
        Navigator.pop(context); // Close sheet
        showSwitchAccountSheet(context); // Reopen with updated list
      }
    }
  }

  static Future<void> _switchUser(BuildContext context, Map<String, dynamic> account) async {
     CustomLoader.show(context);
     final prefs = await SharedPreferences.getInstance();
     
     try {
       String token = account['token'];
       
       // Update prefs with stored data
       await ApiService.setAuthToken(token);
       if (account['phone'] != null) await prefs.setString('user_phone', account['phone']);
       if (account['userId'] != null) await prefs.setString('userId', account['userId']);
       
       // Handle userData if present
       if (account['userData'] != null) {
         final user = jsonDecode(account['userData']);
         if (user['role'] != null) await prefs.setString('user_role', user['role']);
         if (user['firstName'] != null) await prefs.setString('firstName', user['firstName']);
       }

       if (context.mounted) {
         CustomLoader.hide(context);
         Navigator.pushAndRemoveUntil(
           context,
           MaterialPageRoute(builder: (context) => const LandingScreen()),
           (route) => false,
         );
       }
     } catch (e) {
       if (context.mounted) {
         CustomLoader.hide(context);
         CustomToast.showError(context, "Switch failed: $e");
       }
     }
  }
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  bool _isLoading = false;
  String studentName = "";
  String studentStandard = "";
  String schoolName = "";
  String mobileNo = "";
  String email = "";
  String parentMobile = "";
  String profilePic = "";
  String? _photoPath;

  List<dynamic> _examResults = [];
  int _totalPoints = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchProfile();
    });
  }

  Future<void> _fetchProfile({bool forceRefresh = false}) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    
    // Handle Guest mode
    if (ApiService.isGuest) {
      setState(() {
        studentName = "Guest User";
        mobileNo = "Guest Mode";
        studentStandard = "N/A";
        schoolName = "N/A";
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      // Fetch Profile
      final profileResponse = await ApiService.getProfile(forceRefresh: forceRefresh);
      if (!mounted) return;
      if (profileResponse.statusCode == 200) {
        final data = jsonDecode(profileResponse.body);
        final user = data['user'];
        final profile = data['profile'];
        debugPrint("UserDate ${data}");
        setState(() {
             studentName = "${user['firstName']} ${user['middleName'] ?? ''} ${user['lastName'] ?? ''}".trim();
          mobileNo = user['phoneNum'] ?? "";
          email = user['email'] ?? (profile?['email'] ?? ""); // Check both locations
          _photoPath = user['photoPath'];
          
          if (profile != null) {
             studentStandard = "${profile['std'] ?? 'N/A'}${l10n.th} - ${profile['medium'] ?? ''}";
             schoolName = profile['school'] ?? (profile['schoolName'] ?? 'N/A'); 
             profilePic = user['photoPath'] ?? ""; // Use photoPath from user
             // Check parentPhone, then parentNo, then maybe in user object?
             parentMobile = profile['parentPhone'] ?? (profile['parentNo'] ?? (user['parentPhone'] ?? ""));
          }

          // Update saved accounts list with latest info
          debugPrint("Fetched student name: $studentName");
        });
        final prefs = await SharedPreferences.getInstance();

            // Removed legacy ensureCurrentAccountSaved call
      }

      // Fetch Dashboard Data (Points & Exams)
      final dashboardResponse = await ApiService.getDashboardData();
      if (!mounted) return;
      if (dashboardResponse.statusCode == 200) {
         final data = jsonDecode(dashboardResponse.body);
         setState(() {
            _totalPoints = data['totalRewardPoints'] ?? 0;
            _examResults = data['examResults'] ?? [];
         });
      }

    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, "Error: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.myProfile,
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: _isLoading 
          ? const Center(child: CustomLoader())
          : ApiService.isGuest 
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.account_circle_outlined, size: 80, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Welcome, Guest!",
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Login or sign up to access your full profile and track your learning progress.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                            ),
                            child: Text(
                              "Login or Signup",
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
        child: Column(
          children: [
            // 1. Premium Header Section
            Stack(
              clipBehavior: Clip.none,
              children: [
                const SizedBox(height: 170, width: double.infinity),
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 55,
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                            backgroundImage: (_photoPath != null && _photoPath!.isNotEmpty)
                                ? NetworkImage(_photoPath!)
                                : const AssetImage("assets/images/user_placeholder.png") as ImageProvider,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                              );
                              debugPrint("Returned from edit screen: $result");
                              
                              if (result != null) {
                                debugPrint("Profile updated! Result: $result");
                                // Immediate UI update from result to wow the user
                                if (result is Map<String, dynamic>) {
                                  final user = result['user'];
                                  final profile = result['profile'];
                                  if (user != null || profile != null) {
                                    setState(() {
                                      if (user != null) {
                                        studentName = "${user['firstName'] ?? ''} ${user['middleName'] ?? ''} ${user['lastName'] ?? ''}".trim();
                                        mobileNo = user['phoneNum'] ?? "";
                                        _photoPath = user['photoPath'];
                                        profilePic = user['photoPath'] ?? "";
                                      }
                                      if (profile != null) {
                                        studentStandard = "${profile['std'] ?? 'N/A'}${l10n.th} - ${profile['medium'] ?? ''}";
                                        schoolName = profile['school'] ?? (profile['schoolName'] ?? 'N/A');
                                        parentMobile = profile['parentPhone'] ?? (profile['parentNo'] ?? (user?['parentPhone'] ?? ""));
                                      }
                                    });
                                    debugPrint("Updated local state for: $studentName");
                                  }
                                }
                                
                                // And then do the full re-fetch in background to ensure total sync
                                if (mounted) {
                                  _fetchProfile(forceRefresh: true);
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),

            // 2. Name & Standard
            Text(
              studentName,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              "${l10n.standard}: $studentStandard",
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 24),

            // 3. Quick Stats (Reward Points)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade400, Colors.orange.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.stars_rounded, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.learningPoints,
                          style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          "$_totalPoints XP",
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 4. Switch Account Section (Clearly Visible)
            _buildSwitchAccountSection(context, theme),

            const SizedBox(height: 32),

            // 5. Academic Performance Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.recentPerformance,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (_examResults.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const StudentExamHistoryScreen()),
                            );
                          },
                          child: Text(
                            l10n.seeAll,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_examResults.isEmpty)
                    _buildEmptyPerformance(theme)
                  else
                    ..._examResults.take(2).map((exam) => Padding( // Changed to take(2)
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildMarksCard(
                            context,
                            title: exam['title'] ?? l10n.regularExams,
                            marks: "${exam['obtainedMarks'] ?? 0}/${exam['totalMarks'] ?? 0}",
                            color: (exam['totalMarks'] != null && exam['totalMarks'] != 0)
                                ? ((exam['obtainedMarks'] ?? 0) / exam['totalMarks']) >= 0.4 ? Colors.green : Colors.red
                                : Colors.grey,
                            isOnline: exam['isOnline'] ?? false,
                            l10n: l10n,
                            onTap: () {
                              if (exam['isOnline'] == true) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const McqDetailScreen()),
                                );
                              }
                            },
                          ),
                        )),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 6. Contact & Details Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    l10n.profileDetails,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailItem(context, Icons.phone_android_rounded, l10n.mobile, mobileNo),
                  const SizedBox(height: 12),
                  _buildDetailItem(context, Icons.email_rounded, l10n.email, email.isEmpty ? l10n.notProvided : email),
                  const SizedBox(height: 12),
                  _buildDetailItem(context, Icons.family_restroom_rounded, l10n.parentsContact, parentMobile.isEmpty ? l10n.notApplicable : parentMobile),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // 7. Sign Out
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextButton.icon(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final currentToken = prefs.getString('auth_token') ?? "";
                  
                  // Call backend logout
                  await ApiService.logoutUser(currentToken);
                  
                  // Clear local session
                  await ApiService.clearAuthToken();
                  
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.red),
                label: Text(l10n.signOutSession, style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.red, width: 1)),
                ),
              ),
            ),
            
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPerformance(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(l10n.noResultsMessage, style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                Text(value, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchAccountSection(BuildContext context, ThemeData theme) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper().getAccounts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        final l10n = AppLocalizations.of(context)!;
        final accounts = snapshot.data!;
        
        return FutureBuilder<SharedPreferences>(
          future: SharedPreferences.getInstance(),
          builder: (context, prefSnapshot) {
            if (!prefSnapshot.hasData) return const SizedBox.shrink();
            final prefs = prefSnapshot.data!;
            String currentToken = prefs.getString('auth_token') ?? "";

            // Filter out current active account for the "Switch" list
            final otherAccounts = accounts.where((acc) => acc['token'] != currentToken).toList();

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.switchProfile,
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                      ),
                      GestureDetector(
                        onTap: () => StudentProfileScreen.showSwitchAccountSheet(context),
                        child: Text(
                          l10n.seeAll,
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (otherAccounts.isEmpty)
                    Text(
                      l10n.singleProfileActive,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                    )
                  else
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: otherAccounts.length,
                        itemBuilder: (context, index) {
                          final acc = otherAccounts[index];
                          return GestureDetector(
                            onTap: () => StudentProfileScreen._switchUser(context, acc),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                   CircleAvatar(
                                    radius: 14,
                                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                    backgroundImage: (acc['profilePic'] != null && acc['profilePic'].toString().isNotEmpty) 
                                        ? NetworkImage(acc['profilePic']) 
                                        : null,
                                    child: (acc['profilePic'] == null || acc['profilePic'].toString().isEmpty)
                                        ? Text((acc['name'] ?? "U")[0].toUpperCase(), style: TextStyle(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.bold))
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(acc['name'] ?? "User", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  if (accounts.length < 3) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen(isAddAccount: true))),
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                        label: Text(l10n.addAnotherAccount),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildMarksCard(BuildContext context,
      {required String title, required String marks, required Color color, bool isOnline = false, required VoidCallback onTap, required AppLocalizations l10n}) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))
          ],
          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_stories_rounded, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(
                    isOnline ? l10n.onlineExam : l10n.offlineExam,
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                marks, 
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: color)
              ),
            ),
          ],
        ),
      ),
    );
  }
}

