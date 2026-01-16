import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/mcq_Detail.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data
    final String studentName = "Devarsh Shah";
    final String studentStandard = "10th - English Medium";
    final String schoolName = "St. Xavier's High School";
    final String mobileNo = "9106315912";
    final String email = "shadevarsh1000@gmail.com";

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
        // CHANGED: Replaced Logo with Back Button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Profile",
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
        centerTitle: true,
        // CHANGED: Removed Edit button from actions
        actions: const [SizedBox(width: 48)], // To keep title centered
      ),
      body: SingleChildScrollView(
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
                  // NEW: Edit Button moved to the body part (Top Right of Card)
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.black54, size: 22),
                      onPressed: () {
                        // Handle Edit Profile
                      },
                    ),
                  ),
                  
                  // Profile Image
                  const CircleAvatar(
                    radius: 60,
                    backgroundColor: Color(0xFFE0E0E0),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white,
                      backgroundImage: AssetImage("assets/images/user_placeholder.png"), 
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
                  const Divider(height: 30),
                  _buildInfoRow(
                    context,
                    icon: Icons.phone_android,
                    label: "Mobile No",
                    value: mobileNo,
                    icon2: Icons.email_outlined,
                    label2: "Email",
                    value2: email,
                  ),
                  const Divider(height: 30),
                  _buildInfoRow(
                    context,
                    icon: Icons.school_outlined,
                    label: "School Name",
                    value: schoolName,
                    icon2: Icons.location_on_outlined,
                    label2: "Location",
                    value2: "Nehrunagar",
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
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // Handle Sign out logic
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
      required IconData icon2,
      required String label2,
      required String value2}) {
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon2, size: 22, color: Colors.black54),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label2, style: GoogleFonts.poppins(fontSize: 11, color: Colors.black45)),
                    Text(value2, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                  ],
                ),
              ),
            ],
          ),
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