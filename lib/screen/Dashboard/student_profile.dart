import 'dart:convert';
import 'package:dm_bhatt_tutions/network/api_service.dart';
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

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();

  static Future<void> showSwitchAccountSheet(BuildContext context, {String? name, String? phone, String? pic}) async {
    final prefs = await SharedPreferences.getInstance();
    
    await _ensureCurrentAccountSaved(prefs, name: name, phone: phone, pic: pic);

    List<String> savedContexts = prefs.getStringList('saved_accounts') ?? [];
    List<Map<String, dynamic>> accounts = savedContexts.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    String currentToken = prefs.getString('auth_token') ?? "";

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
         final theme = Theme.of(context);
         return Container(
          padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 40),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB( (255 * 0.1).round(), 0, 0, 0),
                blurRadius: 20,
                offset: const Offset(0, -5),
              )
            ],
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
              Text("Switch Accounts", 
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)
              ),
              const SizedBox(height: 8),
              Text("Manage your profiles seamlessly", 
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)
              ),
              const SizedBox(height: 24),
              
              ...accounts.map((acc) {
                 bool isActive = acc['token'] == currentToken;
                 return Container(
                   margin: const EdgeInsets.only(bottom: 12),
                   decoration: BoxDecoration(
                     color: isActive ? theme.colorScheme.primary.withAlpha((255 * 0.05).round()) : theme.cardColor,
                     borderRadius: BorderRadius.circular(16),
                     border: Border.all(
                       color: isActive ? theme.colorScheme.primary : Colors.grey.shade200,
                       width: isActive ? 1.5 : 1
                     ),
                     boxShadow: [
                       if (!isActive)
                         BoxShadow(color: Color.fromARGB( (255 * 0.03).round(), 0, 0, 0), blurRadius: 8, offset: const Offset(0, 2))
                     ]
                   ),
                   child: ListTile(
                     contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                     leading: Container(
                       padding: const EdgeInsets.all(2),
                       decoration: BoxDecoration(
                         shape: BoxShape.circle,
                         border: Border.all(color: isActive ? theme.colorScheme.primary : Colors.transparent, width: 2)
                       ),
                       child: CircleAvatar(
                         radius: 24,
                         backgroundColor: theme.colorScheme.primary.withAlpha((255 * 0.1).round()),
                         backgroundImage: (acc['profilePic'] != null && acc['profilePic'].toString().isNotEmpty) 
                             ? NetworkImage(acc['profilePic']) 
                             : null,
                         child: (acc['profilePic'] == null || acc['profilePic'].toString().isEmpty)
                             ? Text(
                                 acc['name'][0].toUpperCase(), 
                                 style: TextStyle(
                                   color: theme.colorScheme.primary, 
                                   fontWeight: FontWeight.bold,
                                   fontSize: 18
                                 )
                               )
                             : null,
                       ),
                     ),
                     title: Text(
                        acc['name'], 
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface)
                     ),
                     subtitle: Text(
                        acc['phone'], 
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600)
                     ),
                     trailing: isActive 
                        ? Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                            child: const Icon(Icons.check, color: Colors.white, size: 16),
                          )
                        : null,
                     onTap: () {
                       Navigator.pop(context);
                       if (!isActive) _switchUser(context, acc);
                     },
                   ),
                 );
              }),
              
              if (accounts.length < 3)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                             Navigator.pop(context);
                             Navigator.push(context, MaterialPageRoute(builder: (context) => const AddAccountScreen()));
                          },
                          icon: const Icon(Icons.login_rounded),
                          label: const Text("Log In Existing"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: theme.colorScheme.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600)
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                             Navigator.pop(context);
                             Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                          },
                          icon: const Icon(Icons.person_add_rounded, color: Colors.white),
                          label: const Text("Create New", style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600)
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

  static Future<void> _ensureCurrentAccountSaved(SharedPreferences prefs, {String? name, String? phone, String? pic}) async {
    String token = prefs.getString('auth_token') ?? "";
    if (token.isEmpty) return;
    
    List<String> savedContexts = prefs.getStringList('saved_accounts') ?? [];
    List<Map<String, dynamic>> accounts = savedContexts.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

    int index = accounts.indexWhere((acc) => acc['token'] == token);
    
    final updatedAccount = {
         'token': token,
         'name': (name != null && name.isNotEmpty) ? name : "User",
         'phone': (phone != null && phone.isNotEmpty) ? phone : "Signed In", 
         'password': prefs.getString('user_password') ?? "",
         'userId': prefs.getString('userId') ?? "",
         'std': prefs.getString('std') ?? "",
         'profilePic': pic ?? "",
    };

    if (index != -1) {
       accounts[index] = {
         ...accounts[index],
         'name': (name != null && name.isNotEmpty) ? name : accounts[index]['name'],
         'phone': (phone != null && phone.isNotEmpty) ? phone : accounts[index]['phone'],
         'profilePic': (pic != null && pic.isNotEmpty) ? pic : accounts[index]['profilePic'],
       };
    } else {
       accounts.add(updatedAccount);
    }
    
    await prefs.setStringList('saved_accounts', accounts.map((e) => jsonEncode(e)).toList());
  }

  static Future<void> _switchUser(BuildContext context, Map<String, dynamic> account) async {
     final prefs = await SharedPreferences.getInstance();
     
     await prefs.setString('auth_token', account['token']);
     if (account['password'] != null) await prefs.setString('user_password', account['password']);
     if (account['userId'] != null) await prefs.setString('userId', account['userId']);
     if (account['std'] != null) await prefs.setString('std', account['std']);
     
     if (!context.mounted) return;
     Navigator.pushAndRemoveUntil(
       context,
       MaterialPageRoute(builder: (context) => const LandingScreen()),
       (route) => false,
     );
  }
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  bool _isLoading = false;
  String studentName = "";
  String studentStandard = "";
  String schoolName = "";
  String mobileNo = "";
  String? _photoPath;
  String profilePic = "";
  String parentMobile = "";

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
        if (!mounted) return;
        CustomToast.showError(context, "Session expired, please login again");
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
        return;
      }

      final profileResponse = await ApiService.getProfile(token);
      if (profileResponse.statusCode == 200) {
        final data = jsonDecode(profileResponse.body);
        final user = data['user'];
        final profile = data['profile'];

        setState(() {
          studentName = "${user['firstName']} ${user['middleName'] ?? ''} ${user['lastName'] ?? ''}".trim();
          mobileNo = user['phoneNum'] ?? "";
          _photoPath = user['photoPath'];
          
          if (profile != null) {
             studentStandard = "${profile['std'] ?? 'N/A'} - ${profile['medium'] ?? ''}";
             schoolName = profile['school'] ?? (profile['schoolName'] ?? 'N/A'); 
             profilePic = profile['profile_pic'] ?? "";
             parentMobile = profile['parentPhone'] ?? "";
          }
        });
      }

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
      if (!mounted) return;
      CustomToast.showError(context, "Error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withAlpha((255 * 0.8).round()),
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
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    decoration: BoxDecoration(
                      color: theme.cardColor, 
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                            color: Color.fromARGB((255 * (isDark ? 0.3 : 0.05)).round(), 0, 0, 0), 
                            blurRadius: 10,
                            spreadRadius: 2)
                      ],
                    ),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            icon: Icon(Icons.edit, color: theme.iconTheme.color?.withAlpha((255 * 0.7).round()) ?? Colors.grey, size: 22),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                              );
                              _fetchProfile();
                            },
                          ),
                        ),
                        
                        CircleAvatar(
                          radius: MediaQuery.of(context).size.width * 0.12,
                          backgroundColor: isDark ? Colors.grey.shade800 : const Color(0xFFE0E0E0),
                          child: CircleAvatar(
                            radius: MediaQuery.of(context).size.width * 0.12,
                            backgroundColor: theme.cardColor,
                            backgroundImage: (_photoPath != null && _photoPath!.isNotEmpty)
                                ? NetworkImage(_photoPath!)
                                : const AssetImage("assets/images/user_placeholder.png") as ImageProvider, 
                          ),
                        ),
                        const SizedBox(height: 25),

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

                  const SizedBox(height: 24),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber.shade400, Colors.amber.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                          BoxShadow(
                            color: Color.fromARGB((255 * 0.3).round(), 255, 193, 7),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          )
                      ],
                    ),
                    child: Row(
                      children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color.fromARGB( (255 * 0.2).round(), 255, 255, 255),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.stars_rounded, color: Colors.white, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Total Reward Points",
                                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                              ),
                              Text(
                                "$_totalPoints",
                                style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  _buildDetailTile(
                    context, 
                    icon: Icons.school_outlined, 
                    title: "Institute / School", 
                    value: schoolName
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildDetailTile(context, icon: Icons.phone_android_rounded, title: "Mobile No", value: mobileNo)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDetailTile(context, icon: Icons.family_restroom_rounded, title: "Parent's Mobile", value: parentMobile.isEmpty ? "N/A" : parentMobile)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDetailTile(
                    context, 
                    icon: Icons.email_outlined, 
                    title: "Email ID", 
                    value: "N/A"
                  ),

                  const SizedBox(height: 24),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Academic Performance", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color))
                  ),
                  const SizedBox(height: 12),

                  if (_examResults.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor.withAlpha((255 * 0.5).round())),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.assignment_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text("No exam results yet", style: GoogleFonts.poppins(color: Colors.grey)),
                        ],
                      ),
                    )
                  else
                    ..._examResults.map((exam) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildMarksCard(
                          context,
                          title: exam['title'] ?? 'Exam',
                          marks: "${exam['obtainedMarks'] ?? 0}/${exam['totalMarks'] ?? 0}",
                          color: (exam['totalMarks'] != null && exam['totalMarks'] != 0) 
                              ? ((exam['obtainedMarks'] ?? 0) / exam['totalMarks']) >= 0.4 ? Colors.green : Colors.red
                              : Colors.grey,
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
                    )),
                  
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove('auth_token');
                          await prefs.remove('user_password');
                          await prefs.remove('userId'); 
                          await prefs.remove('std'); 
                          if (!mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                            (route) => false,
                          );
                        },
                        icon: Icon(Icons.logout_rounded, color: Colors.red.shade400),
                        label: Text("Sign Out", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.red.shade400)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.red.shade200),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailTile(BuildContext context, {required IconData icon, required String title, required String value}) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Color.fromARGB((255 * 0.04).round(), 0, 0, 0), blurRadius: 10, offset: const Offset(0, 4))
        ],
        border: Border.all(color: theme.dividerColor.withAlpha((255 * 0.1).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.primaryColor.withAlpha((255 * 0.7).round())),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value, 
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: theme.textTheme.bodyLarge?.color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMarksCard(BuildContext context,
      {required String title, required String marks, required Color color, bool isOnline = false, required VoidCallback onTap}) {
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
            BoxShadow(color: Color.fromARGB((255 * 0.03).round(), 0, 0, 0), blurRadius: 8, offset: const Offset(0, 2))
          ],
          border: Border.all(color: theme.dividerColor.withAlpha((255 * 0.1).round())),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
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
                    isOnline ? "Online Exam" : "Offline Exam",
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withAlpha((255 * 0.1).round()),
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

  Widget _buildInfoRow(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    IconData? icon2,
    String? label2,
    String? value2,
  }) {
    final theme = Theme.of(context);
    final textStyle = GoogleFonts.poppins(fontSize: 13, color: theme.textTheme.bodyLarge?.color);
    final boldTextStyle = GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: theme.textTheme.titleLarge?.color);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  Text(label, style: textStyle),
                ],
              ),
              const SizedBox(height: 4),
              Text(value, style: boldTextStyle),
            ],
          ),
        ),
        if (icon2 != null && label2 != null && value2 != null)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon2, size: 18, color: theme.primaryColor),
                    const SizedBox(width: 8),
                    Text(label2, style: textStyle),
                  ],
                ),
                const SizedBox(height: 4),
                Text(value2, style: boldTextStyle),
              ],
            ),
          ),
      ],
    );
  }
}
