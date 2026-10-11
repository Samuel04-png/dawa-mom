import '/localization/dawa_localized_material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/auth/supabase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/responsive/responsive_layout.dart';
import '/design_system/dawa_components.dart';
import '/design_system/dawa_design_tokens.dart';
import '/design_system/dawa_interactions.dart';
import '/features/profile/data/health_profile_repository.dart';

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
  late final HealthProfileRepository _repository;
  bool _saving = false;
  bool _submitted = false;
  String? _loadError;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _repository = HealthProfileRepository();
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
      helpText: context.tr('Choose date of birth'),
      cancelText: context.tr('Cancel'),
      confirmText: context.tr('Save'),
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
      final saved = await _repository.savePersonalInformation(
        name: _name.text,
        dateOfBirth: _dateOfBirth!,
        phone: _phone.text,
        occupation: _occupation.text,
        address: _address.text,
      );
      if (kDebugMode) debugPrint('[HealthProfile] Personal profile saved.');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
      Navigator.pop(context, saved);
    } on HealthProfileException catch (error) {
      if (mounted) {
        setState(() {
          _saveError = error.message;
        });
      }
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
    return Scaffold(
      backgroundColor: DawaColors.canvas,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: DawaColors.canvas,
        foregroundColor: DawaColors.ink,
        title: Text('Edit profile', style: context.dawaTitle),
      ),
      body: FutureBuilder<void>(
        future: _loading,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(18),
              child: DawaPageSkeleton(
                label: 'Loading your profile form',
                showHero: false,
                cardCount: 4,
              ),
            );
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
                          style: context.dawaTitle,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Keep your details correct for visits and health tips.',
                          style: context.dawaBody.copyWith(
                            color: DawaColors.textSecondary,
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
                              decoration: InputDecoration(
                                labelText: 'Full name',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              validator: (value) =>
                                  (value?.trim().length ?? 0) < 2
                                      ? context.tr('Enter your full name.')
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
                                    borderRadius:
                                        BorderRadius.circular(DawaRadii.medium),
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        prefixIcon: const Icon(
                                          Icons.calendar_today_outlined,
                                        ),
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
                              decoration: InputDecoration(
                                labelText: 'Occupation (optional)',
                                prefixIcon: Icon(Icons.work_outline_rounded),
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
                              decoration: InputDecoration(
                                labelText: 'Email address',
                                helperText:
                                    'Your sign-in email is managed securely.',
                                prefixIcon: Icon(Icons.email_outlined),
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
                              decoration: InputDecoration(
                                labelText: 'Mobile number',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              validator: (value) {
                                final digits =
                                    (value ?? '').replaceAll(RegExp(r'\D'), '');
                                return digits.length < 8
                                    ? context.tr('Enter a valid mobile number.')
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
                              decoration: InputDecoration(
                                labelText: 'Address',
                                alignLabelWithHint: true,
                                prefixIcon: Icon(Icons.location_on_outlined),
                              ),
                              validator: (value) =>
                                  (value?.trim().length ?? 0) < 3
                                      ? context.tr('Enter your address.')
                                      : null,
                            ),
                          ],
                        ),
                        if (_saveError != null) ...[
                          const SizedBox(height: 16),
                          Semantics(
                            liveRegion: true,
                            child: DawaActionFeedback(
                              title: 'Changes not saved',
                              message: _saveError!,
                              tone: DawaFeedbackTone.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        DawaPrimaryButton(
                          key: const ValueKey('save-profile'),
                          onPressed: _saving ? null : _save,
                          busy: _saving,
                          icon: Icons.save_outlined,
                          label: 'Save changes',
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
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DawaColors.surface,
        border: Border.all(color: DawaColors.line),
        borderRadius: BorderRadius.circular(DawaRadii.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.dawaSectionTitle,
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
