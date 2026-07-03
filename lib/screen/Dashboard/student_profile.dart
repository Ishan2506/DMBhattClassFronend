import 'dart:convert';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/utils/database_helper.dart';
import 'package:dm_bhatt_tutions/utils/notification_service.dart';
import 'package:dm_bhatt_tutions/screen/authentication/welcome_screen.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dm_bhatt_tutions/screen/Dashboard/edit_profile_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/landing_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/student_exam_history_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/more_detail.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/screen/authentication/login_screen.dart';
import 'package:intl/intl.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:dm_bhatt_tutions/utils/revenue_cat_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

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
          padding: const EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: 40,
          ),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.switchProfile,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),

              ...accounts.map((acc) {
                bool isActive = acc['token'] == currentToken;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? theme.colorScheme.primary.withOpacity(0.05)
                        : theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive
                          ? theme.colorScheme.primary
                          : Colors.grey.shade200,
                      width: isActive ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: theme.colorScheme.primary.withOpacity(
                        0.1,
                      ),
                      backgroundImage:
                          (acc['profilePic'] != null &&
                              acc['profilePic'].toString().isNotEmpty)
                          ? NetworkImage(
                              ApiService.getFileUrl(acc['profilePic']),
                            )
                          : null,
                      child:
                          (acc['profilePic'] == null ||
                              acc['profilePic'].toString().isEmpty)
                          ? Text(
                              (acc['name'] ?? "U")[0].toUpperCase(),
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      acc['name'] ?? "User",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      acc['phone'] ?? "",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    trailing: isActive
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : IconButton(
                            icon: const Icon(
                              Icons.logout,
                              color: Colors.red,
                              size: 20,
                            ),
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
              }),

              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const LoginScreen(isAddAccount: true),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: Text(l10n.logInExisting),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _logoutAccount(
    BuildContext context,
    Map<String, dynamic> account,
  ) async {
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

  static Future<void> _switchUser(
    BuildContext context,
    Map<String, dynamic> account,
  ) async {
    CustomLoader.show(context);
    final prefs = await SharedPreferences.getInstance();

    try {
      String token = account['token'];

      // Update prefs with stored data
      await ApiService.setAuthToken(token);
      final revenueCatUserId = account['userId']?.toString();
      if (revenueCatUserId != null && revenueCatUserId.isNotEmpty) {
        await RevenueCatService.instance.login(revenueCatUserId);
      }
      if (account['phone'] != null)
        await prefs.setString('user_phone', account['phone']);
      if (account['userId'] != null)
        await prefs.setString('userId', account['userId']);

      // Handle userData if present
      if (account['userData'] != null) {
        final user = jsonDecode(account['userData']);
        if (user['role'] != null)
          await prefs.setString('user_role', user['role']);
        if (user['firstName'] != null)
          await prefs.setString('firstName', user['firstName']);
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
  String dob = "";
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
      final profileResponse = await ApiService.getProfile(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      if (profileResponse.statusCode == 200) {
        final data = jsonDecode(profileResponse.body);
        final user = data['user'];
        final profile = data['profile'];
        debugPrint("UserDate $data");
        setState(() {
          studentName =
              "${user['firstName']} ${user['middleName'] ?? ''} ${user['lastName'] ?? ''}"
                  .trim();
          mobileNo = user['phoneNum'] ?? "";
          email =
              user['email'] ??
              (profile?['email'] ?? ""); // Check both locations
          _photoPath = user['photoPath'];

          final rawDob = user['dob'];
          if (rawDob != null && rawDob.toString().isNotEmpty) {
            try {
              final parsedDate = DateTime.parse(rawDob.toString());
              dob = DateFormat('dd/MM/yyyy').format(parsedDate);
            } catch (e) {
              dob = rawDob.toString();
            }
          } else {
            dob = "";
          }

          if (profile != null) {
            studentStandard =
                "${profile['std'] ?? 'N/A'}${l10n.th} - ${profile['medium'] ?? ''}";
            schoolName = profile['school'] ?? (profile['schoolName'] ?? 'N/A');
            profilePic = user['photoPath'] ?? ""; // Use photoPath from user
            // Check parentPhone, then parentNo, then maybe in user object?
            parentMobile =
                profile['parentPhone'] ??
                (profile['parentNo'] ?? (user['parentPhone'] ?? ""));

            // Subscribe to user-specific and standard-specific notification topics
            final userId = user['_id'];
            if (userId != null && userId.toString().isNotEmpty) {
              NotificationService.instance.subscribeToUserTopic(userId.toString());
            }
            final std = profile['std'];
            if (std != null && std.toString().isNotEmpty) {
              NotificationService.instance.subscribeToStandardTopic(
                std.toString(),
              );
            }
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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.myProfile,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
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
                      child: Icon(
                        Icons.account_circle_outlined,
                        size: 80,
                        color: theme.colorScheme.primary,
                      ),
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
                            MaterialPageRoute(
                              builder: (context) => const WelcomeScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          "Login or Signup",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 55,
                                  backgroundColor: theme.colorScheme.primary
                                      .withOpacity(0.1),
                                  backgroundImage:
                                      (_photoPath != null &&
                                          _photoPath!.isNotEmpty)
                                      ? NetworkImage(
                                          ApiService.getFileUrl(_photoPath!),
                                        )
                                      : const AssetImage(
                                              "assets/images/user_placeholder.png",
                                            )
                                            as ImageProvider,
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
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const EditProfileScreen(),
                                      ),
                                    );
                                    debugPrint(
                                      "Returned from edit screen: $result",
                                    );

                                    if (result != null) {
                                      debugPrint(
                                        "Profile updated! Result: $result",
                                      );
                                      // Immediate UI update from result to wow the user
                                      if (result is Map<String, dynamic>) {
                                        final user = result['user'];
                                        final profile = result['profile'];
                                        if (user != null || profile != null) {
                                          setState(() {
                                            if (user != null) {
                                              studentName =
                                                  "${user['firstName'] ?? ''} ${user['middleName'] ?? ''} ${user['lastName'] ?? ''}"
                                                      .trim();
                                              mobileNo = user['phoneNum'] ?? "";
                                              _photoPath = user['photoPath'];
                                              profilePic =
                                                  user['photoPath'] ?? "";
                                              
                                              final rawDob = user['dob'];
                                              if (rawDob != null && rawDob.toString().isNotEmpty) {
                                                try {
                                                  final parsedDate = DateTime.parse(rawDob.toString());
                                                  dob = DateFormat('dd/MM/yyyy').format(parsedDate);
                                                } catch (e) {
                                                  dob = rawDob.toString();
                                                }
                                              } else {
                                                dob = "";
                                              }
                                            }
                                            if (profile != null) {
                                              studentStandard =
                                                  "${profile['std'] ?? 'N/A'}${l10n.th} - ${profile['medium'] ?? ''}";
                                              schoolName =
                                                  profile['school'] ??
                                                  (profile['schoolName'] ??
                                                      'N/A');
                                              parentMobile =
                                                  profile['parentPhone'] ??
                                                  (profile['parentNo'] ??
                                                      (user?['parentPhone'] ??
                                                          ""));
                                            }
                                          });
                                          debugPrint(
                                            "Updated local state for: $studentName",
                                          );
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
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.edit_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
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
                          colors: [
                            Colors.amber.shade400,
                            Colors.orange.shade700,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
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
                            child: const Icon(
                              Icons.stars_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.learningPoints,
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                "$_totalPoints XP",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 4. Switch Account Section (Clearly Visible)
                  // _buildSwitchAccountSection(context, theme),

                  // const SizedBox(height: 32),

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
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const HistoryMenuScreen(),
                                    ),
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
                          ..._examResults
                              .take(2)
                              .map(
                                (exam) => Padding(
                                  // Changed to take(2)
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildMarksCard(
                                    context,
                                    title: exam['title'] ?? l10n.regularExams,
                                    marks:
                                        "${exam['obtainedMarks'] ?? 0}/${exam['totalMarks'] ?? 0}",
                                    color:
                                        (exam['totalMarks'] != null &&
                                            exam['totalMarks'] != 0)
                                        ? ((exam['obtainedMarks'] ?? 0) /
                                                      exam['totalMarks']) >=
                                                  0.4
                                              ? Colors.green
                                              : Colors.red
                                        : Colors.grey,
                                    isOnline: exam['isOnline'] ?? false,
                                    l10n: l10n,
                                  ),
                                ),
                              ),
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
                        _buildDetailItem(
                          context,
                          Icons.phone_android_rounded,
                          l10n.mobile,
                          mobileNo,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailItem(
                          context,
                          Icons.email_rounded,
                          l10n.email,
                          email.isEmpty ? l10n.notProvided : email,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailItem(
                          context,
                          Icons.family_restroom_rounded,
                          l10n.parentsContact,
                          parentMobile.isEmpty
                              ? l10n.notApplicable
                              : parentMobile,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailItem(
                          context,
                          Icons.cake_rounded,
                          l10n.dateOfBirth,
                          dob.isEmpty ? l10n.notProvided : dob,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  /*
                  // 7. Manage Subscription
                  if (Platform.isIOS)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (context) =>
                                  const _ManageSubscriptionScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.manage_accounts_rounded),
                          label: Text(
                            "Manage Subscription",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                  */

                  // Delete Account
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text("Delete Account", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                            content: Text("Are you sure you want to permanently delete your account? This action cannot be undone.", style: GoogleFonts.poppins()),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text("Delete", style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          CustomLoader.show(context);
                          try {
                            final response = await ApiService.deleteAccount();
                            CustomLoader.hide(context);
                            if (response.statusCode == 200 || response.statusCode == 201) {
                              final prefs = await SharedPreferences.getInstance();
                              final currentToken = prefs.getString('auth_token') ?? "";
                              
                              // Delete from local SQLite database
                              final db = DatabaseHelper();
                              final accounts = await db.getAccounts();
                              final activeAcc = accounts.firstWhere(
                                (acc) => acc['token'] == currentToken,
                                orElse: () => <String, dynamic>{},
                              );
                              if (activeAcc.isNotEmpty && activeAcc['userId'] != null) {
                                await db.deleteAccount(activeAcc['userId']);
                              }

                              await ApiService.logoutUser(currentToken);
                              await ApiService.clearAuthToken();
                              if (!mounted) return;
                              CustomToast.showSuccess(context, "Account deleted successfully");
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                                (route) => false,
                              );
                            } else {
                              CustomToast.showError(context, "Failed to delete account: ${ApiService.getErrorMessage(response.body)}");
                            }
                          } catch (e) {
                            CustomLoader.hide(context);
                            CustomToast.showError(context, "Error: $e");
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      label: Text(
                        "Delete Account",
                        style: GoogleFonts.poppins(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Colors.red, width: 1),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 8. Sign Out
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextButton.icon(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final currentToken =
                            prefs.getString('auth_token') ?? "";

                        // Call backend logout
                        await ApiService.logoutUser(currentToken);

                        // Clear local session
                        await ApiService.clearAuthToken();

                        if (!mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WelcomeScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout_rounded, color: Colors.red),
                      label: Text(
                        l10n.signOutSession,
                        style: GoogleFonts.poppins(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Colors.red, width: 1),
                        ),
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
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 40,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.noResultsMessage,
            style: GoogleFonts.poppins(
              color: Colors.grey.shade500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
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
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildSwitchAccountSection(BuildContext context, ThemeData theme) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper().getAccounts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return const SizedBox.shrink();
        final l10n = AppLocalizations.of(context)!;
        final accounts = snapshot.data!;

        return FutureBuilder<SharedPreferences>(
          future: SharedPreferences.getInstance(),
          builder: (context, prefSnapshot) {
            if (!prefSnapshot.hasData) return const SizedBox.shrink();
            final prefs = prefSnapshot.data!;
            String currentToken = prefs.getString('auth_token') ?? "";

            // Filter out current active account for the "Switch" list
            final otherAccounts = accounts
                .where((acc) => acc['token'] != currentToken)
                .toList();

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.switchProfile,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            StudentProfileScreen.showSwitchAccountSheet(
                              context,
                            ),
                        child: Text(
                          l10n.seeAll,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (otherAccounts.isEmpty)
                    Text(
                      l10n.singleProfileActive,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
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
                            onTap: () =>
                                StudentProfileScreen._switchUser(context, acc),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: theme.dividerColor.withOpacity(0.1),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: theme.colorScheme.primary
                                        .withOpacity(0.1),
                                    backgroundImage:
                                        (acc['profilePic'] != null &&
                                            acc['profilePic']
                                                .toString()
                                                .isNotEmpty)
                                        ? NetworkImage(acc['profilePic'])
                                        : null,
                                    child:
                                        (acc['profilePic'] == null ||
                                            acc['profilePic']
                                                .toString()
                                                .isEmpty)
                                        ? Text(
                                            (acc['name'] ?? "U")[0]
                                                .toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    acc['name'] ?? "User",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
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
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                LoginScreen(isAddAccount: true),
                          ),
                        ),
                        icon: const Icon(
                          Icons.add_circle_outline_rounded,
                          size: 18,
                        ),
                        label: Text(l10n.addAnotherAccount),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          textStyle: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMarksCard(
    BuildContext context, {
    required String title,
    required String marks,
    required Color color,
    bool isOnline = false,
    required AppLocalizations l10n,
  }) {
    final theme = Theme.of(context);

    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
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
              child: Icon(
                Icons.auto_stories_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    isOnline ? l10n.onlineExam : l10n.offlineExam,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
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
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      );
  }
}

class _ManageSubscriptionScreen extends StatefulWidget {
  const _ManageSubscriptionScreen();

  @override
  State<_ManageSubscriptionScreen> createState() =>
      _ManageSubscriptionScreenState();
}

class _ManageSubscriptionScreenState extends State<_ManageSubscriptionScreen> {
  CustomerInfo? _customerInfo;
  bool _isLoading = true;
  bool _isRestoring = false;
  bool _isChangingPlan = false;

  @override
  void initState() {
    super.initState();
    _loadCustomerInfo();
  }

  Future<void> _loadCustomerInfo() async {
    final info = await RevenueCatService.instance.getCustomerInfo();
    if (!mounted) return;
    setState(() {
      _customerInfo = info;
      _isLoading = false;
    });
  }

  bool get _isActive =>
      _customerInfo
          ?.entitlements
          .all[RevenueCatService.entitlementId]
          ?.isActive ??
      false;

  String get _subscriptionTitle {
    final activeSubscription =
        _customerInfo?.activeSubscriptions.isNotEmpty == true
        ? _customerInfo!.activeSubscriptions.first
        : null;
    if (activeSubscription == null || activeSubscription.isEmpty) {
      return "Padhaku Pro";
    }

    final standardMatch = RegExp(
      r"std[_\-. ]?(\d+)",
      caseSensitive: false,
    ).firstMatch(activeSubscription);
    if (standardMatch != null) {
      final standard = standardMatch.group(1);
      final plan = activeSubscription.toLowerCase().contains("month")
          ? "Monthly"
          : "Annual";
      return "Standard $standard - $plan";
    }

    return "Padhaku Pro";
  }

  String get _renewalText {
    final expirationDate = _customerInfo?.latestExpirationDate;
    if (expirationDate == null || expirationDate.isEmpty) {
      return _isActive
          ? "Your subscription is active."
          : "No active subscription found.";
    }
    return "Your next charge is ₹700.00 on ${_formatRevenueCatDate(expirationDate)}.";
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: CupertinoPageScaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CupertinoActivityIndicator())
              : DefaultTextStyle.merge(
                  style: const TextStyle(
                    decoration: TextDecoration.none,
                    decorationColor: CupertinoColors.transparent,
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 28),
                      _buildSubscriptionCard(),
                      const SizedBox(height: 32),
                      _buildActionGroup(),
                      const SizedBox(height: 30),
                      _buildSectionLabel("ACCOUNT DETAILS"),
                      const SizedBox(height: 12),
                      _buildAccountDetailsCard(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Text(
            "How can we help?",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: CupertinoColors.black,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(44, 44),
            onPressed: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFE5E5EA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.xmark,
                color: CupertinoColors.black,
                size: 30,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard() {
    return _buildRoundedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _subscriptionTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: CupertinoColors.black,
                    height: 1.15,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (_isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDFF7E8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "Active",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: CupertinoColors.black,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _renewalText,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8E8E93),
              height: 1.28,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "App Store",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8E8E93),
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGroup() {
    return _buildRoundedCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildActionRow("Restore past purchases", _restorePurchases),
          _buildDivider(),
          _buildActionRow("Change plans", _openPaywall),
          _buildDivider(),
          _buildActionRow("Cancel subscription", _showCancelMessage),
          _buildDivider(),
          _buildActionRow("Request a refund", _showRefundMessage),
        ],
      ),
    );
  }

  Widget _buildAccountDetailsCard() {
    final originalDate =
        _customerInfo?.originalPurchaseDate ??
        _customerInfo?.firstSeen ??
        _customerInfo?.requestDate;
    return _buildRoundedCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            flex: 3,
            child: Text(
              "Original Download Date",
              maxLines: 2,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: CupertinoColors.black,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            flex: 2,
            child: Text(
              originalDate == null
                  ? "Unavailable"
                  : _formatRevenueCatDate(originalDate),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8E8E93),
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(String title, VoidCallback onPressed) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 19),
      minimumSize: Size.zero,
      onPressed: onPressed,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.black,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }

  Widget _buildRoundedCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 28,
      vertical: 24,
    ),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: child,
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: const Color(0xFFE5E5EA));
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 28),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8E8E93),
          letterSpacing: 0,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Future<void> _restorePurchases() async {
    if (_isRestoring) return;
    setState(() => _isRestoring = true);
    final result = await RevenueCatService.instance.restorePurchases();
    final info = await RevenueCatService.instance.getCustomerInfo();
    if (!mounted) return;
    setState(() {
      _customerInfo = info;
      _isRestoring = false;
    });
    await _showStatusDialog(title: result.title, message: result.message);
  }

  Future<void> _openPaywall() async {
    if (_isChangingPlan) return;

    setState(() => _isChangingPlan = true);
    final planInfo = await _loadNextPlanInfo();
    if (!mounted) return;
    setState(() => _isChangingPlan = false);

    if (planInfo == null) return;

    final result = await RevenueCatService.instance
        .presentStandardPaywallWithResult(
          context: context,
          standard: planInfo.nextStandard,
        );

    if (result.isSuccess && mounted) {
      await _completeAppleUpgradeFromRevenueCat(result, planInfo);
    }

    final info = await RevenueCatService.instance.getCustomerInfo();
    if (!mounted) return;
    setState(() => _customerInfo = info);
    if (result.shouldShowAlert) {
      await _showStatusDialog(title: result.title, message: result.message);
    }
  }

  Future<_ChangePlanInfo?> _loadNextPlanInfo() async {
    String? currentStandard;
    String? medium;
    String? stream;

    try {
      final prefs = await SharedPreferences.getInstance();
      currentStandard = _standardNumberFrom(prefs.getString("std"));
      medium = _cleanProfileValue(prefs.getString("medium"));
      stream = _cleanProfileValue(prefs.getString("stream"));

      final response = await ApiService.getProfile(forceRefresh: true);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final profile = data['profile'];
        if (profile != null) {
          currentStandard =
              _standardNumberFrom(profile['std']) ?? currentStandard;
          medium = _cleanProfileValue(profile['medium']) ?? medium;
          stream = _cleanProfileValue(profile['stream']) ?? stream;

          if (currentStandard != null) {
            await prefs.setString('std', currentStandard);
          }
          if (medium != null) {
            await prefs.setString('medium', medium);
          }
          if (stream != null) {
            await prefs.setString('stream', stream);
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading profile for plan change: $e");
    }

    final current = int.tryParse(currentStandard ?? "");
    if (current == null) {
      await _showStatusDialog(
        title: "Change Plans",
        message:
            "We could not identify your current standard. Please refresh your profile and try again.",
      );
      return null;
    }

    if (current >= 12) {
      await _showStatusDialog(
        title: "Change Plans",
        message:
            "You are already on the highest available standard. No higher plan is available.",
      );
      return null;
    }

    if (medium == null) {
      await _showStatusDialog(
        title: "Change Plans",
        message:
            "We could not identify your current medium. Please update your profile and try again.",
      );
      return null;
    }

    final nextStandard = (current + 1).toString();
    return _ChangePlanInfo(
      nextStandard: nextStandard,
      medium: medium,
      stream: stream,
      amount: _amountForStandard(nextStandard),
    );
  }

  Future<void> _completeAppleUpgradeFromRevenueCat(
    RevenueCatPurchaseResult result,
    _ChangePlanInfo planInfo,
  ) async {
    final productId = result.productId;
    final expectedProductId =
        result.requestedProductId ??
        RevenueCatService.productIdForStandard(planInfo.nextStandard);
    final transactionId = result.transactionId;
    debugPrint("[Apple Profile Upgrade] Completing via RevenueCat");
    debugPrint("[Apple Profile Upgrade] productId: $productId");
    debugPrint("[Apple Profile Upgrade] expectedProductId: $expectedProductId");
    debugPrint("[Apple Profile Upgrade] transactionId: $transactionId");
    debugPrint(
      "[Apple Profile Upgrade] nextStandard: ${planInfo.nextStandard}",
    );
    debugPrint("[Apple Profile Upgrade] medium: ${planInfo.medium}");
    debugPrint("[Apple Profile Upgrade] stream: ${planInfo.stream}");
    debugPrint(
      "[Apple Profile Upgrade] amount: ${result.amountPaid ?? planInfo.amount}",
    );
    final active = await RevenueCatService.instance.refreshIsProActive();
    if (!active ||
        productId == null ||
        productId.isEmpty ||
        transactionId == null ||
        transactionId.isEmpty) {
      debugPrint(
        "[Apple Profile Upgrade] Missing verification details: "
        "entitlementActive=$active, "
        "productIdMissing=${productId == null || productId.isEmpty}, "
        "transactionIdMissing=${transactionId == null || transactionId.isEmpty}",
      );
      await _showStatusDialog(
        title: "Purchase Failed",
        message:
            "Apple purchase finished, but active subscription access was not found. Please restore purchases or try again.",
      );
      return;
    }

    if (expectedProductId != null && productId != expectedProductId) {
      debugPrint(
        "[Apple Profile Upgrade] Product mismatch: "
        "expected=$expectedProductId actual=$productId",
      );
      await _showStatusDialog(
        title: "Purchase Failed",
        message:
            "Apple returned a different product ($productId) than the selected plan ($expectedProductId). Please try again or restore the correct subscription.",
      );
      return;
    }

    final refreshedReceipt = await RevenueCatService.instance
        .getAppleReceiptAfterPurchase(
          maxAttempts: 8,
          delay: const Duration(milliseconds: 1500),
          forceRefresh: true,
        );
    final receipt =
        (refreshedReceipt != null &&
            refreshedReceipt.length > (result.receipt?.length ?? 0))
        ? refreshedReceipt
        : result.receipt;

    if (receipt == null || receipt.isEmpty) {
      debugPrint("[Apple Profile Upgrade] Missing Apple receipt");
      await _showStatusDialog(
        title: "Verification Failed",
        message:
            "Apple purchase completed, but the receipt was not available. Please try restore purchases.",
      );
      return;
    }

    final response = await _verifyAppleUpgradeWithReceiptRetry(
      receipt: receipt,
      productId: productId,
      expectedProductId: expectedProductId,
      transactionId: transactionId,
      planInfo: planInfo,
      amount: result.amountPaid ?? planInfo.amount,
    );

    if (!mounted) return;
    if (response.statusCode != 200 && response.statusCode != 201) {
      await _showStatusDialog(
        title: "Verification Failed",
        message: ApiService.getErrorMessage(response.body),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("std", planInfo.nextStandard);
    await prefs.setString("medium", planInfo.medium);
    if (planInfo.stream != null) {
      await prefs.setString("stream", planInfo.stream!);
    }
    await _loadCustomerInfo();
    if (!mounted) return;
    await _showStatusDialog(
      title: "Purchase Successful",
      message: "Your subscription is active.",
    );
  }

  Future<dynamic> _verifyAppleUpgradeWithReceiptRetry({
    required String receipt,
    required String productId,
    required String? expectedProductId,
    required String transactionId,
    required _ChangePlanInfo planInfo,
    required double amount,
  }) async {
    var response = await ApiService.verifyAppleUpgrade(
      receipt: receipt,
      productId: productId,
      expectedProductId: expectedProductId,
      transactionId: transactionId,
      newStandard: planInfo.nextStandard,
      medium: planInfo.medium,
      stream: planInfo.stream,
      amount: amount,
    );

    if (!_isReceiptMissingProductError(response.body)) {
      return response;
    }

    debugPrint(
      "[Apple Profile Upgrade] Receipt missing purchased product. Refreshing receipt and retrying verification.",
    );
    await Future.delayed(const Duration(seconds: 4));
    final refreshedReceipt = await RevenueCatService.instance
        .getAppleReceiptAfterPurchase(
          maxAttempts: 8,
          delay: const Duration(milliseconds: 1500),
          forceRefresh: true,
        );

    if (refreshedReceipt == null || refreshedReceipt.isEmpty) {
      return response;
    }

    return ApiService.verifyAppleUpgrade(
      receipt: refreshedReceipt,
      productId: productId,
      expectedProductId: expectedProductId,
      transactionId: transactionId,
      newStandard: planInfo.nextStandard,
      medium: planInfo.medium,
      stream: planInfo.stream,
      amount: amount,
    );
  }

  bool _isReceiptMissingProductError(String body) {
    final lower = body.toLowerCase();
    return lower.contains("purchased product was missing") ||
        lower.contains("missing in the receipt") ||
        lower.contains("receipt is not valid");
  }

  String? _standardNumberFrom(dynamic value) {
    if (value == null) return null;
    return RegExp(r"(\d+)").firstMatch(value.toString())?.group(1);
  }

  String? _cleanProfileValue(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == "none") return null;
    return text;
  }

  double _amountForStandard(String standard) {
    switch (standard) {
      case "6":
        return 300;
      case "7":
        return 400;
      case "8":
        return 500;
      case "9":
        return 600;
      case "10":
        return 700;
      case "11":
        return 800;
      case "12":
        return 900;
      default:
        return 0;
    }
  }

  Future<void> _showCancelMessage() async {
    await _showStatusDialog(
      title: "Cancel Subscription",
      message:
          "You can cancel this subscription from your iPhone Settings. Open Settings, tap your Apple ID, choose Subscriptions, then select Padhaku.",
    );
  }

  Future<void> _showRefundMessage() async {
    await _showStatusDialog(
      title: "Request a Refund",
      message:
          "Refund requests are managed by Apple. Open reportaproblem.apple.com with your Apple ID to request a refund for this subscription.",
    );
  }

  Future<void> _showStatusDialog({
    required String title,
    required String message,
  }) async {
    if (!mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  String _formatRevenueCatDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    final local = parsed.toLocal();
    return "${local.day} ${months[local.month - 1]} ${local.year}";
  }
}

class _ChangePlanInfo {
  const _ChangePlanInfo({
    required this.nextStandard,
    required this.medium,
    required this.amount,
    this.stream,
  });

  final String nextStandard;
  final String medium;
  final String? stream;
  final double amount;
}
