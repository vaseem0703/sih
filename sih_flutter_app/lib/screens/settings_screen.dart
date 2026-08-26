import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsService? settingsService;
  final ValueChanged<AppSettings>? onSettingsChanged;

  const SettingsScreen({
    super.key,
    this.settingsService,
    this.onSettingsChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsService _settingsService = widget.settingsService ?? SettingsService();
  AppSettings _settings = const AppSettings();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await _settingsService.loadSettings();
    if (mounted) {
      setState(() {
        _settings = s;
        _isLoading = false;
      });
    }
  }

  void _updateSettings(AppSettings s) {
    setState(() => _settings = s);
    _settingsService.saveSettings(s);
    widget.onSettingsChanged?.call(s);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. LANGUAGE SETTING
              _buildSettingCard(
                icon: Icons.g_translate_rounded,
                iconColor: AppColors.orange,
                title: 'Language',
                subtitle: _settings.languageMode,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Target Pair: Hindi ↔ Santali (Ol Chiki)'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // 2. VOICE SETTING
              _buildSettingCard(
                icon: Icons.record_voice_over_rounded,
                iconColor: AppColors.green,
                title: 'Voice',
                subtitle: _settings.ttsSpeaker,
                trailing: DropdownButton<String>(
                  value: _settings.ttsSpeaker.contains('Female')
                      ? 'Phulmani (Female)'
                      : 'Sido (Male)',
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                      value: 'Phulmani (Female)',
                      child: Text('Phulmani (Female)'),
                    ),
                    DropdownMenuItem(
                      value: 'Sido (Male)',
                      child: Text('Sido (Male)'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      _updateSettings(_settings.copyWith(ttsSpeaker: val));
                    }
                  },
                ),
              ),

              const SizedBox(height: 16),

              // 3. VOLUME SLIDER
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppColors.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.volume_up_rounded, color: AppColors.blue),
                        SizedBox(width: 14),
                        Text(
                          'Volume',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _settings.volume,
                      activeColor: AppColors.blue,
                      inactiveColor: AppColors.blueLight,
                      onChanged: (val) {
                        _updateSettings(_settings.copyWith(volume: val));
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 4. OFFLINE CONTENT STATUS
              _buildSettingCard(
                icon: Icons.download_done_rounded,
                iconColor: AppColors.purple,
                title: 'Offline Content',
                subtitle: 'Downloaded & Ready',
                trailing: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.green,
                ),
              ),

              const SizedBox(height: 16),

              // 5. ABOUT
              _buildSettingCard(
                icon: Icons.info_outline_rounded,
                iconColor: AppColors.orange,
                title: 'About',
                subtitle: 'SIH Problem Statement 26042',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'SIH Vernacular Pedagogy App',
                    applicationVersion: '1.0.0 (Offline Prototype)',
                    applicationLegalese:
                        'AI-Powered Vernacular Pedagogy and Real-Time Translation Tool for Mother Tongue-Based Primary Education (Hindi ↔ Santali)',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
