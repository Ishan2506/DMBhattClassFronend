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

      final response = await ApiService.getProfile(token);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'];
        final profile = data['profile'];

        setState(() {
          studentName = "${user['firstName']} ${user['middleName'] ?? ''} ${user['lastName'] ?? ''}".trim();
          mobileNo = user['phoneNum'] ?? "";
          
          if (profile != null) {
             studentStandard = "${profile['std'] ?? 'N/A'} - ${profile['medium'] ?? ''}";
             schoolName = profile['school'] ?? (profile['schoolName'] ?? 'N/A'); // Handle student vs guest
          }
          
          _isLoading = false;
        });
      } else {
        CustomToast.showError(context, "Failed to load profile");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      CustomToast.showError(context, "Error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade900, Colors.blue.shade700],
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
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
                      icon: const Icon(Icons.edit, color: Colors.black54, size: 22),
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
                    radius: MediaQuery.of(context).size.width * 0.16,
                    backgroundColor: const Color(0xFFE0E0E0),
                    child: CircleAvatar(
                      radius: MediaQuery.of(context).size.width * 0.15,
                      backgroundColor: Colors.white,
                      backgroundImage: const AssetImage("assets/images/user_placeholder.png"), 
                    ),
                  ),
                  const SizedBox(height: 20),

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
                  Divider(height: MediaQuery.of(context).size.height * 0.03),
                  _buildInfoRow(
                    context,
                    icon: Icons.phone_android,
                    label: "Mobile No",
                    value: mobileNo,
                  ),
                  Divider(height: MediaQuery.of(context).size.height * 0.03),
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
                        "125", // Mock Points for now
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
            _buildSectionHeader("Academic Performance"),
            const SizedBox(height: 10),

            _buildMarksCard(
              context,
              title: "Offline Test Exam",
              marks: "85/100",
              color: Colors.orange,
              onTap: () {},
            ),
            const SizedBox(height: 10),
            _buildMarksCard(
              context,
              title: "Online MCQ Exam",
              marks: "42/50",
              color: Colors.green,
              isOnline: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const McqDetailScreen()),
                );
              },
            ),

            const SizedBox(height: 30),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.07,
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
                  backgroundColor: const Color(0xFF4C53A5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: Text("Sign out",
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
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
    return Row(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: Colors.black54),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.black45)),
                    Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
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
                    Icon(icon2, size: 22, color: Colors.black54),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label2,
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: Colors.black45)),
                          Text(value2,
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87)),
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

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        const Icon(Icons.stars, color: Colors.orangeAccent),
      ],
    );
  }

  Widget _buildMarksCard(BuildContext context,
      {required String title, required String marks, required Color color, bool isOnline = false, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.black54)),
                const SizedBox(height: 4),
                Text(marks, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            if (isOnline)
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)
          ],
        ),
      ),
    );
  }
}