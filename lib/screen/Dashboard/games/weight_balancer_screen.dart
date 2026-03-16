import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';

class WeightBalancerScreen extends StatefulWidget {
  const WeightBalancerScreen({super.key});

  @override
  State<WeightBalancerScreen> createState() => _WeightBalancerScreenState();
}

class _WeightBalancerScreenState extends State<WeightBalancerScreen> {
  final MindGameService _gameService = MindGameService();
  int _score = 0;
  bool _gameOver = false;
  
  int _targetWeight = 0;
  int _currentWeight = 0;
  List<int> _availableWeights = [];

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _startRound();
  }

  @override
  void dispose() {
    _gameService.stopSession();
    super.dispose();
  }

  void _startRound() {
    setState(() {
      _gameOver = false;
      _currentWeight = 0;
      
      _targetWeight = (_random.nextInt(10) + 5) * 5; // e.g 25, 30... 75
      
      _availableWeights.clear();
      // Generate some weights that can sum to target
      _availableWeights = [5, 10, 15, 20, 25, 50];
      _availableWeights.shuffle();
    });
  }

  void _addWeight(int w) {
    if (_gameOver) return;

    setState(() {
      _currentWeight += w;
    });

    if (_currentWeight == _targetWeight) {
      setState(() {
        _score += 20;
        _gameOver = true;
      });
    } else if (_currentWeight > _targetWeight) {
      // Bust
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Too heavy! Resetting scale...", style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
          duration: const Duration(milliseconds: 800),
        )
      );
      setState(() {
        _currentWeight = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(title: "Weight Balancer", centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoBadge(Icons.scale, "Target: $_targetWeight kg", theme.colorScheme.primary),
                _buildInfoBadge(Icons.star, "Score: $_score", Colors.amber[800]!),
                TextButton.icon(
                  onPressed: _startRound,
                  icon: const Icon(Icons.skip_next, size: 18),
                  label: Text(
                    AppLocalizations.of(context)!.skip,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_gameOver)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Icon(Icons.balance, size: 80, color: Colors.green),
                     const SizedBox(height: 16),
                     Text("Perfect Balance!", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
                     const SizedBox(height: 32),
                     ElevatedButton(
                       onPressed: _startRound,
                       style: ElevatedButton.styleFrom(
                         padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                         backgroundColor: theme.colorScheme.primary,
                         foregroundColor: theme.colorScheme.onPrimary,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                       ),
                       child: Text("Next Challenge", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                     )
                  ],
                ),
              )
            else
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Visual balance representation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildScalePan(theme, _targetWeight, "Target", true),
                        Icon(Icons.monitor_weight_outlined, size: 64, color: theme.dividerColor),
                        _buildScalePan(theme, _currentWeight, "Current", false),
                      ],
                    ),
                    const SizedBox(height: 64),
                    Text("Add weights to match the target exactly:", style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: _availableWeights.map((w) {
                        return ElevatedButton(
                          onPressed: () => _addWeight(w),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            foregroundColor: theme.colorScheme.onPrimaryContainer,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text("+$w kg", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _currentWeight = 0;
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text("Clear Scale"),
                    )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildScalePan(ThemeData theme, int weight, String label, bool isTarget) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: isTarget ? theme.colorScheme.primary.withOpacity(0.2) : Colors.orangeAccent.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: isTarget ? theme.colorScheme.primary : Colors.orangeAccent, width: 4),
          ),
          child: Center(
            child: Text(
              "$weight\nkg",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(text, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
