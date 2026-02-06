import 'dart:convert';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/screen/authentication/welcome_screen.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/mcq_Detail.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/edit_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  bool _isLoading = true;
  String studentName = "";
  String studentStandard = "";
  String schoolName = "";
  String mobileNo = "";
  // String email = ""; // If needed

  List<dynamic> _examResults = [];
  int _totalPoints = 0;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        CustomToast.showError(context, "Session expired, please login again");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
        return;
      }

      // Fetch Profile
      final profileResponse = await ApiService.getProfile(token);
      if (profileResponse.statusCode == 200) {
        final data = jsonDecode(profileResponse.body);
        final user = data['user'];
        final profile = data['profile'];

        setState(() {
          studentName = "${user['firstName']} ${user['middleName'] ?? ''} ${user['lastName'] ?? ''}".trim();
          mobileNo = user['phoneNum'] ?? "";
          
          if (profile != null) {
             studentStandard = "${profile['std'] ?? 'N/A'} - ${profile['medium'] ?? ''}";
             schoolName = profile['school'] ?? (profile['schoolName'] ?? 'N/A'); 
          }
        });
      }

      // Fetch Dashboard Data (Points & Exams)
      final dashboardResponse = await ApiService.getDashboardData(token);
      if (dashboardResponse.statusCode == 200) {
         final data = jsonDecode(dashboardResponse.body);
         setState(() {
            _totalPoints = data['totalRewardPoints'] ?? 0;
            _examResults = data['examResults'] ?? [];
         });
      }

      setState(() => _isLoading = false);

    } catch (e) {
      CustomToast.showError(context, "Error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Dynamic background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Profile",
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: const [SizedBox(width: 48)], 
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              decoration: BoxDecoration(
                color: theme.cardColor, // Dynamic Card Color
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), // Adjusted Shadow
                      blurRadius: 10,
                      spreadRadius: 2)
                ],
              ),
              child: Column(
                children: [
                  // Edit Button
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: Icon(Icons.edit, color: theme.iconTheme.color?.withOpacity(0.7) ?? Colors.grey, size: 22),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                        );
                        _fetchProfile(); // Refresh on return
                      },
                    ),
                  ),
                  
                  // Profile Image
                  CircleAvatar(
                    radius: MediaQuery.of(context).size.width * 0.12,
                    backgroundColor: isDark ? Colors.grey.shade800 : const Color(0xFFE0E0E0),
                    child: CircleAvatar(
                      radius: MediaQuery.of(context).size.width * 0.12,
                      backgroundColor: theme.cardColor,
                      backgroundImage: const AssetImage("assets/images/user_placeholder.png"), 
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Info Grid
                  _buildInfoRow(
                    context,
                    icon: Icons.person_outline,
                    label: "Student Name",
                    value: studentName,
                    icon2: Icons.layers_outlined,
                    label2: "Standard",
                    value2: studentStandard,
                  ),
                  Divider(height: MediaQuery.of(context).size.height * 0.03, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                  _buildInfoRow(
                    context,
                    icon: Icons.phone_android,
                    label: "Mobile No",
                    value: mobileNo,
                  ),
                  Divider(height: MediaQuery.of(context).size.height * 0.03, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                  _buildInfoRow(
                    context,
                    icon: Icons.school_outlined,
                    label: "School Name",
                    value: schoolName,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Reward Points Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade400, Colors.amber.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                   BoxShadow(
                      color: Colors.amber.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                   )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Reward Points",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$_totalPoints",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
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
                    child: const Icon(Icons.stars_rounded, color: Colors.white, size: 36),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Marks Section
            _buildSectionHeader("Academic Performance", theme),
            const SizedBox(height: 10),

            if (_examResults.isEmpty) 
               Padding(
                 padding: const EdgeInsets.all(20.0),
                 child: Text("No exam results found", style: GoogleFonts.poppins(color: Colors.grey)),
               )
            else
               ..._examResults.map((exam) => Padding(
                 padding: const EdgeInsets.only(bottom: 10),
                 child: _buildMarksCard(
                    context,
                    title: exam['title'] ?? 'Exam',
                    marks: "${exam['obtainedMarks']}/${exam['totalMarks']}",
                    color: (exam['obtainedMarks'] / exam['totalMarks']) >= 0.4 ? Colors.green : Colors.red,
                    isOnline: exam['isOnline'] ?? false,
                    onTap: () {
                       if (exam['isOnline'] == true) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const McqDetailScreen()),
                          );
                       }
                    },
                  ),
               )).toList(),

            const SizedBox(height: 30),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.07,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear(); // Logout
                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text("Sign out",
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context,
      {required IconData icon,
      required String label,
      required String value,
      IconData? icon2,
      String? label2,
      String? value2}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = isDark ? Colors.grey.shade400 : Colors.black54;
    final labelColor = isDark ? Colors.grey.shade500 : Colors.black45;
    final valueColor = theme.textTheme.bodyLarge?.color;

    return Row(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: GoogleFonts.poppins(fontSize: 11, color: labelColor)),
                    Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: (icon2 != null && label2 != null && value2 != null)
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon2, size: 22, color: iconColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label2,
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: labelColor)),
                          Text(value2,
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: valueColor)),
                        ],
                      ),
                    ),
                  ],
                )
              : const SizedBox(),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color)),
        const Icon(Icons.stars, color: Colors.orangeAccent),
      ],
    );
  }

  Widget _buildMarksCard(BuildContext context,
      {required String title, required String marks, required Color color, bool isOnline = false, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: isDark ? Colors.grey.shade400 : Colors.black54)),
                const SizedBox(height: 4),
                Text(marks, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            if (isOnline)
               Icon(Icons.arrow_forward_ios, size: 16, color: isDark ? Colors.grey.shade600 : Colors.grey)
          ],
        ),
      ),
    );
  }
}