import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/auth/supabase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/responsive/responsive_layout.dart';
import '/features/profile/data/health_profile_repository.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class EditProfileWidget extends StatefulWidget {
  const EditProfileWidget({super.key, this.motherDets});

  final DocumentReference? motherDets;

  static const String routeName = 'EditProfile';
  static const String routePath = '/editProfile';

  @override
  State<EditProfileWidget> createState() => _EditProfileWidgetState();
}

class _EditProfileWidgetState extends State<EditProfileWidget> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _occupation = TextEditingController();
  final _address = TextEditingController();

  late Future<void> _loading;
  DateTime? _dateOfBirth;
  String? _motherId;
  bool _saving = false;
  bool _submitted = false;
  String? _loadError;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _loading = _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _occupation.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final userId = currentUserUid;
    if (userId.isEmpty) {
      throw const _ProfileEditException('Please sign in to edit your profile.');
    }
    try {
      final results = await Future.wait<dynamic>([
        SupabaseDatabase.instance.runWithFreshSession(
          () => Supabase.instance.client
              .from('profiles')
              .select('email,display_name,phone_number')
              .eq('id', userId)
              .single(),
        ),
        SupabaseDatabase.instance.runWithFreshSession(
          () => Supabase.instance.client
              .from('mothers')
              .select(
                'id,name,phone_number,date_of_birth,occupation,address',
              )
              .eq('profile_id', userId)
              .maybeSingle(),
        ),
      ]);
      final profile = Map<String, dynamic>.from(results[0] as Map);
      final mother = results[1] == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(results[1] as Map);
      _motherId = mother['id']?.toString();
      _name.text = _firstText([mother['name'], profile['display_name']]);
      _email.text = _firstText([profile['email'], currentUserEmail]);
      _phone.text = _firstText([
        mother['phone_number'],
        profile['phone_number'],
      ]);
      _occupation.text = _text(mother['occupation']);
      _address.text = _text(mother['address']);
      _dateOfBirth = mother['date_of_birth'] == null
          ? null
          : DateTime.tryParse(mother['date_of_birth'].toString());
    } catch (_) {
      _loadError = 'Your profile could not be loaded. Please try again.';
      rethrow;
    }
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _submitted = true;
      _saveError = null;
    });
    if (_formKey.currentState?.validate() != true || _dateOfBirth == null) {
      return;
    }
    final userId = currentUserUid;
    if (userId.isEmpty) {
      setState(
          () => _saveError = 'Your session expired. Please sign in again.');
      return;
    }

    setState(() => _saving = true);
    try {
      if (kDebugMode) debugPrint('[HealthProfile] Saving personal profile.');
      final client = Supabase.instance.client;
      final name = _name.text.trim();
      final phone = _phone.text.trim();
      await SupabaseDatabase.instance.runWithFreshSession(
        () => client.from('profiles').update({
          'display_name': name,
          'phone_number': phone,
        }).eq('id', userId),
      );
      final motherData = {
        'profile_id': userId,
        'name': name,
        'phone_number': phone,
        'date_of_birth': _dateId(_dateOfBirth!),
        'occupation': _nullIfBlank(_occupation.text),
        'address': _address.text.trim(),
      };
      if (_motherId == null) {
        final inserted = await SupabaseDatabase.instance.runWithFreshSession(
          () => client
              .from('mothers')
              .insert({
                'id': userId,
                ...motherData,
              })
              .select('id')
              .single(),
        );
        _motherId = inserted['id'].toString();
      } else {
        await SupabaseDatabase.instance.runWithFreshSession(
          () => client.from('mothers').update(motherData).eq('id', _motherId!),
        );
      }
      HealthProfileRepository.notifyChanged();
      if (kDebugMode) debugPrint('[HealthProfile] Personal profile saved.');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saveError = 'Your profile could not be updated. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.primaryBackground,
        foregroundColor: theme.primaryText,
        title: const Text('Edit profile'),
      ),
      body: FutureBuilder<void>(
        future: _loading,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return DawaMomEmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Profile could not be loaded',
              description: _loadError ?? 'Check your connection and try again.',
              actionLabel: 'Retry',
              onAction: () => setState(() => _loading = _load()),
            );
          }
          return Stack(
            children: [
              SingleChildScrollView(
                child: ResponsivePageContainer(
                  maxWidth: 760,
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _submitted
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personal information',
                          style: theme.headlineSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Keep your details accurate for appointments and personalised guidance.',
                          style: theme.bodyMedium.copyWith(
                            color: theme.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _FormSection(
                          title: 'About you',
                          children: [
                            TextFormField(
                              key: const ValueKey('edit-profile-name'),
                              controller: _name,
                              enabled: !_saving,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Full name',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  (value?.trim().length ?? 0) < 2
                                      ? 'Enter your full name.'
                                      : null,
                            ),
                            const SizedBox(height: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Date of birth *'),
                                const SizedBox(height: 7),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _saving ? null : _pickDateOfBirth,
                                    borderRadius: BorderRadius.circular(4),
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        prefixIcon: const Icon(
                                          Icons.calendar_today_outlined,
                                        ),
                                        border: const OutlineInputBorder(),
                                        errorText:
                                            _submitted && _dateOfBirth == null
                                                ? 'Choose your date of birth.'
                                                : null,
                                      ),
                                      child: Text(
                                        _dateOfBirth == null
                                            ? 'Choose date'
                                            : DateFormat('d MMMM y')
                                                .format(_dateOfBirth!),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _occupation,
                              enabled: !_saving,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Occupation (optional)',
                                prefixIcon: Icon(Icons.work_outline_rounded),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _FormSection(
                          title: 'Contact details',
                          children: [
                            TextFormField(
                              controller: _email,
                              enabled: false,
                              decoration: const InputDecoration(
                                labelText: 'Email address',
                                helperText:
                                    'Your sign-in email is managed securely.',
                                prefixIcon: Icon(Icons.email_outlined),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              key: const ValueKey('edit-profile-phone'),
                              controller: _phone,
                              enabled: !_saving,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9+\-\s()]'),
                                ),
                                LengthLimitingTextInputFormatter(18),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Mobile number',
                                prefixIcon: Icon(Icons.phone_outlined),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                final digits =
                                    (value ?? '').replaceAll(RegExp(r'\D'), '');
                                return digits.length < 8
                                    ? 'Enter a valid mobile number.'
                                    : null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              key: const ValueKey('edit-profile-address'),
                              controller: _address,
                              enabled: !_saving,
                              textCapitalization: TextCapitalization.sentences,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Address',
                                alignLabelWithHint: true,
                                prefixIcon: Icon(Icons.location_on_outlined),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  (value?.trim().length ?? 0) < 3
                                      ? 'Enter your address.'
                                      : null,
                            ),
                          ],
                        ),
                        if (_saveError != null) ...[
                          const SizedBox(height: 16),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              _saveError!,
                              style: TextStyle(color: theme.error),
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        FilledButton.icon(
                          key: const ValueKey('save-profile'),
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(_saving ? 'Saving...' : 'Save changes'),
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.primary,
                            minimumSize: const Size.fromHeight(50),
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ),
              if (_saving)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(minHeight: 3),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _text(dynamic value) => value?.toString().trim() ?? '';
  static String _firstText(List<dynamic> values) => values
      .map(_text)
      .firstWhere((value) => value.isNotEmpty, orElse: () => '');
  static String _dateId(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
  static String? _nullIfBlank(String value) =>
      value.trim().isEmpty ? null : value.trim();
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        border: Border.all(color: theme.alternate),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.titleSmall.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _ProfileEditException implements Exception {
  const _ProfileEditException(this.message);
  final String message;
}
