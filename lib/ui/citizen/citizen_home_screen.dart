import 'package:sereno_ya/ui/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/ui/core/widgets/app_drawer.dart';

import 'package:sereno_ya/ui/citizen/home/citizen_home_tab.dart';
import 'package:sereno_ya/ui/citizen/incident_history/incident_history_tab.dart';
import 'package:sereno_ya/ui/citizen/incident_tracking/incident_tracking_tab.dart';
import 'package:sereno_ya/ui/citizen/incident_tracking/view_models/incident_tracking_view_model.dart';

class CitizenHomeScreen extends StatefulWidget {
  const CitizenHomeScreen({super.key});

  @override
  State<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends State<CitizenHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    CitizenHomeTab(),
    IncidentTrackingTab(),
    IncidentHistoryTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SOS San Jerónimo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: context.appColors.primary,
        foregroundColor: context.appColors.textInverse,
      ),
      drawer: const AppDrawer(),
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 1) {
            context.read<IncidentTrackingViewModel>().loadActiveIncidents();
          }
        },
        selectedItemColor: context.appColors.tabIconSelected,
        unselectedItemColor: context.appColors.tabIconDefault,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes_outlined),
            activeIcon: Icon(Icons.track_changes),
            label: 'Seguimiento',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Historial',
          ),
        ],
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.label,
  });

  final String title;
  final String subtitle;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.appColors.textSecondary.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.appColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.phone_in_talk,
              color: context.appColors.textInverse,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: context.appColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: context.appColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.appColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.appColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.phone_in_talk,
              color: context.appColors.textInverse,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}
