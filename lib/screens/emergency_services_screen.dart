import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/emergency_history_service.dart';
import 'emergency_contacts_screen.dart';
import 'hospital_insurance_screen.dart';
import 'first_aid_screen.dart';
import 'emergency_numbers_screen.dart';
import 'emergency_history_screen.dart';

class EmergencyServicesScreen extends StatelessWidget {
  const EmergencyServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            // Big SOS circle
            Center(
              child: GestureDetector(
                onLongPress: () async {
                  // 1) Log SOS event
                  await EmergencyHistoryService.logEvent(
                    type: 'sos',
                    title: 'SOS Activated',
                    description: 'SOS button held for 3 seconds',
                    status: 'In Progress',
                  );

                  // 2) Immediately call emergency number
                  const emergencyNumber = '122';
                  final callUri =
                      Uri(scheme: 'tel', path: emergencyNumber);
                  await launchUrl(callUri);

                  // 3) Open SMS to notify emergency contacts
                  const smsMessage =
                      'SOS emergency! Please help and call me back immediately.';
                  final smsUri = Uri(
                    scheme: 'sms',
                    path: '',
                    queryParameters: {'body': smsMessage},
                  );
                  await launchUrl(smsUri);
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 230,
                      height: 230,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white24,
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 200,
                      height: 200,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Hold 3 second',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'EMERGENCY SERVICES',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            _buildEmergencyTile(
              context,
              icon: Icons.contacts_outlined,
              label: 'Emergency Contacts',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EmergencyContactsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildEmergencyTile(
              context,
              icon: Icons.local_hospital_outlined,
              label: 'Hospital & insurance',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HospitalInsuranceScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildEmergencyTile(
              context,
              icon: Icons.medical_services_outlined,
              label: 'First Aid',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FirstAidScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildEmergencyTile(
              context,
              icon: Icons.call_outlined,
              label: 'Emergency Numbers',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EmergencyNumbersScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildEmergencyTile(
              context,
              icon: Icons.history,
              label: 'Emergency History',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EmergencyHistoryScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white70,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

