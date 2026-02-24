import 'dart:convert';
import 'package:dm_bhatt_tutions/custom_widgets/custom_dropdown.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/mind_map_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:dm_bhatt_tutions/model/mind_map_model.dart';

class MindMapSelectionScreen extends StatefulWidget {
  const MindMapSelectionScreen({super.key});

  @override
  State<MindMapSelectionScreen> createState() => _MindMapSelectionScreenState();
}

class _MindMapSelectionScreenState extends State<MindMapSelectionScreen> {
  List<MindMapModel> _allMindMaps = [];
  bool _isLoading = true;

  String? _selectedSubject;
  String? _selectedUnit;

  List<String> _subjects = [];
  List<String> _units = [];

  @override
  void initState() {
    super.initState();
    _fetchMindMaps();
  }

  Future<void> _fetchMindMaps() async {
    // Add dummy data for testing
    final dummyData = [
      MindMapModel(
        id: "dummy1",
        subject: "Science",
        unit: "Light - Reflection & Vision",
        root: MindMapNode(
          name: "Light",
          children: [
            MindMapNode(
              name: "Vision",
            ),
            MindMapNode(
              name: "Reflection of Light",
              children: [
                MindMapNode(name: "Virtual and erect"),
                MindMapNode(name: "Same size as object"),
                MindMapNode(name: "Equal distance"),
                MindMapNode(name: "Lateral inversion"),
              ],
            ),
            MindMapNode(
              name: "Plane Mirror Images",
            ),
            MindMapNode(
              name: "Multiple Reflection",
              children: [
                MindMapNode(name: "Multiple images"),
                MindMapNode(name: "Periscope"),
                MindMapNode(
                  name: "Kaleidoscope",
                  children: [
                    MindMapNode(name: "Three mirror strips"),
                    MindMapNode(name: "Infinite patterns"),
                  ],
                ),
              ],
            ),
            MindMapNode(
              name: "Sunlight",
              children: [
                MindMapNode(name: "Dispersion"),
                MindMapNode(name: "Seven colors"),
                MindMapNode(name: "Rainbow"),
              ],
            ),
            MindMapNode(name: "Human Eye"),
            MindMapNode(name: "Braille System"),
          ],
        ),
      ),
    ];

    try {
      final response = await ApiService.getAllMindMaps();
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _allMindMaps = data.map((e) => MindMapModel.fromJson(e)).toList();
          // Merge with dummy data if needed or just use dummy if empty
          if (_allMindMaps.isEmpty) {
            _allMindMaps = dummyData;
          } else {
            _allMindMaps.addAll(dummyData);
          }
          _subjects = _allMindMaps.map((e) => e.subject).toSet().toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _allMindMaps = dummyData;
          _subjects = _allMindMaps.map((e) => e.subject).toSet().toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching mind maps: $e");
      setState(() {
        _allMindMaps = dummyData;
        _subjects = _allMindMaps.map((e) => e.subject).toSet().toList();
        _isLoading = false;
      });
    }
  }

  void _onSubjectChanged(String? subject) {
    setState(() {
      _selectedSubject = subject;
      _selectedUnit = null;
      if (subject != null) {
        _units = _allMindMaps
            .where((e) => e.subject == subject)
            .map((e) => e.unit)
            .toSet()
            .toList();
      } else {
        _units = [];
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
                    onChanged: (val) => setState(() => _selectedUnit = val),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: (_selectedSubject == null || _selectedUnit == null)
                          ? null
                          : () {
                              final mindMap = _allMindMaps.firstWhere(
                                (e) => e.subject == _selectedSubject && e.unit == _selectedUnit,
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
