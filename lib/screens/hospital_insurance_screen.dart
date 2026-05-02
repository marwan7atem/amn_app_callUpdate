import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/emergency_history_service.dart';

class HospitalInsuranceScreen extends StatefulWidget {
  const HospitalInsuranceScreen({super.key});

  @override
  State<HospitalInsuranceScreen> createState() =>
      _HospitalInsuranceScreenState();
}

class _HospitalInsuranceScreenState extends State<HospitalInsuranceScreen> {
  final GlobalKey<_HospitalListState> _hospitalListKey =
      GlobalKey<_HospitalListState>();

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
        title: const Text(
          'Hospital & Insurance',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: () async {
          final result = await showDialog<_HospitalInfo>(
            context: context,
            builder: (context) => const _AddHospitalDialog(),
          );
          if (result != null && mounted) {
            _hospitalListKey.currentState?.addHospital(result);
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _HospitalList(key: _hospitalListKey),
      ),
    );
  }
}

class _HospitalInfo {
  final String name;
  final String distance;
  final String status;
  final String phone;

  const _HospitalInfo({
    required this.name,
    required this.distance,
    required this.status,
    required this.phone,
  });
}

class _HospitalList extends StatefulWidget {
  const _HospitalList({super.key});

  @override
  State<_HospitalList> createState() => _HospitalListState();
}

class _HospitalListState extends State<_HospitalList> {
  final List<_HospitalInfo> _hospitals = [
    const _HospitalInfo(
      name: 'El Salam Hospital',
      distance: '2.3 Km',
      status: 'Open',
      phone: '+201111111111',
    ),
    const _HospitalInfo(
      name: 'Cleopatra Hospital',
      distance: '2.3 Km',
      status: 'Open',
      phone: '+201122233344',
    ),
  ];

  void addHospital(_HospitalInfo info) {
    setState(() {
      _hospitals.add(info);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: _hospitals.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final hospital = _hospitals[index];
        return _HospitalCard(info: hospital);
      },
    );
  }
}

class _HospitalCard extends StatelessWidget {
  final _HospitalInfo info;

  const _HospitalCard({required this.info});

  Future<void> _launchCall() async {
    await EmergencyHistoryService.logEvent(
      type: 'hospital_call',
      title: 'Calling ${info.name}',
      description: 'Hospital emergency call',
      status: 'In Progress',
    );
    final uri = Uri(scheme: 'tel', path: info.phone);
    await launchUrl(uri);
  }

  Future<void> _launchDirections() async {
    final destination = Uri.encodeComponent(info.name);
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=driving',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_hospital_outlined,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                info.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                info.distance,
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(width: 16),
              Text(
                info.status,
                style: const TextStyle(color: Colors.greenAccent, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _launchCall,
                    child: const Text(
                      'Call',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _launchDirections,
                    child: const Text(
                      'Directions',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddHospitalDialog extends StatefulWidget {
  const _AddHospitalDialog();

  @override
  State<_AddHospitalDialog>  createState()  => _AddHospitalDialogState();
}

class _AddHospitalDialogState extends State<_AddHospitalDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _distanceController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Add Hospital', style: TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(
              controller: _nameController,
              label: 'Hospital Name',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _distanceController,
              label: 'Distance (e.g. 2.3 Km)',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _statusController,
              label: 'Status (e.g. Open)',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
          onPressed: () {
            if (_nameController.text.trim().isEmpty ||
                _phoneController.text.trim().isEmpty ||
                _distanceController.text.trim().isEmpty ||
                _statusController.text.trim().isEmpty) {
              return;
            }
            final info = _HospitalInfo(
              name: _nameController.text.trim(),
              distance: _distanceController.text.trim(),
              status: _statusController.text.trim(),
              phone: _phoneController.text.trim(),
            );
            Navigator.pop(context, info);
          },
          child: const Text('Add', style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400]),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}
