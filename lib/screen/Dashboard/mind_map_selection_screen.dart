import 'dart:convert';
import 'package:dm_bhatt_tutions/custom_widgets/custom_dropdown.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/mind_map_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:dm_bhatt_tutions/model/mind_map_model.dart';
import 'package:dm_bhatt_tutions/utils/guest_utils.dart';

class MindMapSelectionScreen extends StatefulWidget {
  const MindMapSelectionScreen({super.key});

  @override
  State<MindMapSelectionScreen> createState() => _MindMapSelectionScreenState();
}

class _MindMapSelectionScreenState extends State<MindMapSelectionScreen> {
  List<MindMapModel> _allMindMaps = [];
  bool _isLoading = true;
  bool _isGuest = false;

  String? _selectedSubject;
  String? _selectedUnit;
  String? _selectedTitle;

  List<String> _subjects = [];
  List<String> _units = [];
  List<String> _titles = [];

  @override
  void initState() {
    super.initState();
    _checkGuest();
    _fetchMindMaps();
  }

  Future<void> _checkGuest() async {
    _isGuest = await GuestUtils.isGuest();
    if (mounted) setState(() {});
  }

  Future<void> _fetchMindMaps() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getAllMindMaps();
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          final List<MindMapModel> allMaps = data.map((e) => MindMapModel.fromJson(e)).toList();
          if (_isGuest && allMaps.length > 2) {
            _allMindMaps = allMaps.sublist(0, 2);
          } else {
            _allMindMaps = allMaps;
          }
          _subjects = _allMindMaps.map((e) => e.subject).toSet().toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _allMindMaps = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching mind maps: $e");
      setState(() {
        _allMindMaps = [];
        _isLoading = false;
      });
    }
  }

  void _onSubjectChanged(String? subject) {
    setState(() {
      _selectedSubject = subject;
      _selectedUnit = null;
      _selectedTitle = null;
      if (subject != null) {
        _units = _allMindMaps
            .where((e) => e.subject == subject)
            .map((e) => e.unit)
            .toSet()
            .toList();
      } else {
        _units = [];
      }
      _titles = [];
    });
  }

  void _onUnitChanged(String? unit) {
    setState(() {
      _selectedUnit = unit;
      _selectedTitle = null;
      if (unit != null && _selectedSubject != null) {
        _titles = _allMindMaps
            .where((e) => e.subject == _selectedSubject && e.unit == unit)
            .map((e) => e.title)
            .toSet()
            .toList();
      } else {
        _titles = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: const CustomAppBar(
        title: "Mind Maps",
      ),
      body: _isLoading
          ? const CustomLoader()
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    "Select Subject & Unit to View Mind Map",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  CustomDropdown<String>(
                    labelText: "Subject",
                    hintText: "Select Subject",
                    value: _selectedSubject,
                    items: _subjects,
                    itemLabelBuilder: (String item) => item,
                    onChanged: _onSubjectChanged,
                  ),
                  const SizedBox(height: 24),
                  CustomDropdown<String>(
                    labelText: "Unit",
                    hintText: "Select Unit",
                    value: _selectedUnit,
                    items: _units,
                    itemLabelBuilder: (String item) => item,
                    onChanged: _onUnitChanged,
                  ),
                  const SizedBox(height: 24),
                  CustomDropdown<String>(
                    labelText: "Title",
                    hintText: "Select Mind Map Title",
                    value: _selectedTitle,
                    items: _titles,
                    itemLabelBuilder: (String item) => item,
                    onChanged: (val) => setState(() => _selectedTitle = val),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: (_selectedSubject == null || _selectedUnit == null || _selectedTitle == null)
                          ? null
                          : () async {
                              if (_isGuest) {
                                GuestUtils.showGuestRestrictionDialog(context, message: "Register as a student to view full mind maps!");
                                return;
                              }
                              final mindMap = _allMindMaps.firstWhere(
                                (e) => e.subject == _selectedSubject && e.unit == _selectedUnit && e.title == _selectedTitle,
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MindMapScreen(mindMap: mindMap),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey.shade400,
                      ),
                      child: const Text(
                        "Show Mind Map",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
