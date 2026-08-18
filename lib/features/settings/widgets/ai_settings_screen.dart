import 'package:flutter/material.dart';
import '../../../services/ai/ai_service.dart';

class AISettingsScreen extends StatefulWidget {
  const AISettingsScreen({super.key});

  @override
  State<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen> {
  final AIService _aiService = AIService();
  bool _isLoading = true;
  bool _isAiEnabled = false;
  String? _selectedProviderId;
  String? _selectedModel;
  String? _maskedApiKey;
  List<String> _availableModels = [];

  final TextEditingController _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    _isAiEnabled = await _aiService.isAiEnabled();
    _selectedProviderId = await _aiService.getActiveProviderId() ?? _aiService.providers.first.id;

    final provider = _aiService.getActiveProvider(_selectedProviderId);
    if (provider != null) {
      _availableModels = provider.availableModels;
      _selectedModel = await _aiService.getActiveModel();
      if (_selectedModel == null || !_availableModels.contains(_selectedModel)) {
        _selectedModel = _availableModels.first;
      }
      _maskedApiKey = await _aiService.getMaskedApiKey(_selectedProviderId!);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveProviderSelection(String providerId) async {
    await _aiService.setActiveProviderId(providerId);
    setState(() {
      _selectedProviderId = providerId;
    });
    await _loadSettings(); // Reload models and masked key for the new provider
  }

  Future<void> _saveModelSelection(String model) async {
    await _aiService.setActiveModel(model);
    setState(() {
      _selectedModel = model;
    });
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isNotEmpty && _selectedProviderId != null) {
      await _aiService.saveApiKey(_selectedProviderId!, key);
      _apiKeyController.clear();
      await _loadSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API Key saved securely.')));
      }
    }
  }

  Future<void> _deleteApiKey() async {
    if (_selectedProviderId != null) {
      await _aiService.deleteApiKey(_selectedProviderId!);
      await _loadSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API Key deleted.')));
      }
    }
  }

  Future<void> _testConnection() async {
    if (_selectedProviderId == null || _selectedModel == null) return;

    setState(() => _isLoading = true);
    final success = await _aiService.testConnection(_selectedProviderId!, _selectedModel!);
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Connection successful!' : 'Connection failed. Please check your API key.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentProvider = _aiService.getActiveProvider(_selectedProviderId);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Preferences')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            title: const Text('Enable AI Features'),
            subtitle: const Text('Allow AI assistance in Writer, Spreadsheet, and Presentation.'),
            value: _isAiEnabled,
            onChanged: (val) async {
              await _aiService.setAiEnabled(val);
              setState(() => _isAiEnabled = val);
            },
          ),
          const Divider(),
          if (_isAiEnabled) ...[
            const Text('Provider Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'AI Provider', border: OutlineInputBorder()),
              value: _selectedProviderId,
              items: _aiService.providers.map((p) {
                return DropdownMenuItem(value: p.id, child: Text(p.name));
              }).toList(),
              onChanged: (val) {
                if (val != null) _saveProviderSelection(val);
              },
            ),
            const SizedBox(height: 16),
            if (currentProvider != null) ...[
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Model', border: OutlineInputBorder()),
                value: _selectedModel,
                items: _availableModels.map((m) {
                  return DropdownMenuItem(value: m, child: Text(m));
                }).toList(),
                onChanged: (val) {
                  if (val != null) _saveModelSelection(val);
                },
              ),
              const SizedBox(height: 24),
              const Text('API Key (BYOK)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_maskedApiKey != null) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Key: $_maskedApiKey'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _deleteApiKey,
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _apiKeyController,
                  decoration: const InputDecoration(
                    labelText: 'Enter API Key',
                    border: OutlineInputBorder(),
                    hintText: 'sk-...',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _saveApiKey,
                    child: const Text('Save Key'),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.network_check),
                label: const Text('Test Connection'),
                onPressed: _maskedApiKey != null ? _testConnection : null,
              ),
            ],
            const Divider(height: 48),
            const Text('Privacy & Cost Warning', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
            const SizedBox(height: 8),
            const Text(
              'Using AI features will send the specific text or context you select to the chosen third-party AI provider.\n\n'
              'OpenWPS does not store or process your documents on its own servers.\n\n'
              'You are responsible for any costs incurred from your API provider based on your usage.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await _aiService.clearHistory();
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('History cleared.')));
              },
              child: const Text('Clear AI Conversation History'),
            )
          ],
        ],
      ),
    );
  }
}
