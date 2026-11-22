import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/reading_club_repository.dart' as club_data;
import '../../models/reading_club.dart';

class CreateReadingClubForm extends StatefulWidget {
  const CreateReadingClubForm({
    super.key,
    required this.repository,
    required this.onCreated,
  });

  final club_data.ReadingClubRepository repository;
  final ValueChanged<ReadingClub> onCreated;

  @override
  State<CreateReadingClubForm> createState() => _CreateReadingClubFormState();
}

class _CreateReadingClubFormState extends State<CreateReadingClubForm> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _placeController = TextEditingController();
  final _instagramController = TextEditingController();
  final _facebookController = TextEditingController();
  final _xController = TextEditingController();

  DateTime? _meetingDate;
  TimeOfDay? _meetingTime;
  String _modality = 'ONLINE';

  bool _saving = false;
  String? _error;

  bool get _isPresential => _modality == 'PRESENCIAL';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _placeController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    _xController.dispose();
    super.dispose();
  }

  String? _requiredText(String? value, int maxLength) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Este campo es obligatorio';
    }

    if (text.length > maxLength) {
      return 'Máximo $maxLength caracteres';
    }

    return null;
  }

  String? _optionalText(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  String _formattedDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formattedTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);

    final date = await showDatePicker(
      context: context,
      initialDate: _meetingDate ?? firstDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 5),
      helpText: 'Fecha del encuentro',
    );

    if (!mounted || date == null) return;

    setState(() {
      _meetingDate = date;
      _error = null;
    });
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _meetingTime ?? TimeOfDay.now(),
      helpText: 'Hora del encuentro',
    );

    if (!mounted || time == null) return;

    setState(() {
      _meetingTime = time;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_saving) return;

    if (!_formKey.currentState!.validate()) return;

    if (_meetingDate == null || _meetingTime == null) {
      setState(() {
        _error = 'Selecciona la fecha y la hora del encuentro.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final club = await widget.repository.createClub(
        club_data.CreateReadingClubForm(
          name: _nameController.text,
          description: _descriptionController.text,
          meetingDate: _meetingDate!,
          meetingTime: _formattedTime(_meetingTime!),
          modality: _modality,
          meetingPlace: _isPresential
              ? _optionalText(_placeController.text)
              : null,
          instagram: _optionalText(_instagramController.text),
          facebook: _optionalText(_facebookController.text),
          xHandle: _optionalText(_xController.text),
        ),
      );

      if (!mounted) return;

      widget.onCreated(club);
    } on ApiFailure catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.statusCode == 403
            ? 'Necesitas una verificación de organizador '
                  'aprobada para crear clubes.'
            : error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error =
            'No pudimos crear el club. '
            'Revisa tu conexión e inténtalo nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  InputDecoration _decoration(
    BuildContext context,
    String hint,
    IconData icon,
  ) {
    final gold = AppColors.goldOf(context);

    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        color: AppColors.textSecondaryOf(context),
        fontSize: 11,
      ),
      prefixIcon: Icon(icon, color: gold, size: 19),
      filled: true,
      fillColor: AppColors.surfaceSoftOf(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: gold.withValues(alpha: 0.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: gold.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: gold, width: 1.5),
      ),
    );
  }

  Widget _field(
    BuildContext context, {
    required String title,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required int maxLength,
    bool required = true,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            required ? '$title *' : title,
            style: GoogleFonts.inter(
              color: AppColors.textPrimaryOf(context),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLength: maxLength,
            maxLines: maxLines,
            enabled: !_saving,
            keyboardType: maxLines > 1
                ? TextInputType.multiline
                : TextInputType.text,
            style: GoogleFonts.inter(
              color: AppColors.textPrimaryOf(context),
              fontSize: 12,
            ),
            decoration: _decoration(context, hint, icon),
            validator: (value) {
              if (required) {
                return _requiredText(value, maxLength);
              }

              if ((value?.trim().length ?? 0) > maxLength) {
                return 'Máximo $maxLength caracteres';
              }

              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, Widget child) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.goldOf(context).withValues(alpha: 0.30),
        ),
      ),
      child: child,
    );
  }

  Widget _heading(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.goldOf(context), size: 23),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.cinzel(
                  color: AppColors.textPrimaryOf(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondaryOf(context),
                  fontSize: 10,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dateTimeButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: _saving ? null : onPressed,
      icon: Icon(icon, size: 18),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 9)),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimaryOf(context),
        side: BorderSide(
          color: AppColors.goldOf(context).withValues(alpha: 0.45),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textSecondary = AppColors.textSecondaryOf(context);

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        key: const ValueKey('create-reading-club'),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
        children: [
          _card(
            context,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heading(
                  context,
                  'Tu nuevo club de lectura',
                  'Crea un espacio para reunir a lectores '
                      'y compartir encuentros.',
                  Icons.auto_stories_rounded,
                ),
                const SizedBox(height: 22),
                _field(
                  context,
                  title: 'Nombre del club',
                  hint: 'Ej. Entre libros y café',
                  icon: Icons.groups_2_outlined,
                  controller: _nameController,
                  maxLength: 150,
                ),
                _field(
                  context,
                  title: 'Descripción del club',
                  hint: 'Cuéntanos qué compartirán los lectores...',
                  icon: Icons.edit_note_rounded,
                  controller: _descriptionController,
                  maxLength: 2000,
                  maxLines: 5,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _card(
            context,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heading(
                  context,
                  'El encuentro',
                  'Indica cuándo y cómo se reunirán.',
                  Icons.calendar_month_outlined,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _dateTimeButton(
                        context,
                        icon: Icons.event_outlined,
                        title: 'Fecha *',
                        value: _meetingDate == null
                            ? 'Seleccionar'
                            : _formattedDate(_meetingDate!),
                        onPressed: _selectDate,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _dateTimeButton(
                        context,
                        icon: Icons.schedule_rounded,
                        title: 'Hora *',
                        value: _meetingTime == null
                            ? 'Seleccionar'
                            : _formattedTime(_meetingTime!),
                        onPressed: _selectTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Modalidad *',
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimaryOf(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _modality,
                  decoration: _decoration(
                    context,
                    'Selecciona la modalidad',
                    Icons.public_rounded,
                  ),
                  dropdownColor: AppColors.surfaceOf(context),
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimaryOf(context),
                    fontSize: 12,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'ONLINE', child: Text('Online')),
                    DropdownMenuItem(
                      value: 'PRESENCIAL',
                      child: Text('Presencial'),
                    ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() => _modality = value);
                        },
                ),
                if (_isPresential) ...[
                  const SizedBox(height: 18),
                  _field(
                    context,
                    title: 'Lugar del encuentro',
                    hint: 'Dirección o lugar de reunión',
                    icon: Icons.location_on_outlined,
                    controller: _placeController,
                    maxLength: 300,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _card(
            context,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heading(
                  context,
                  'Redes sociales',
                  'Opcionales. Se mostrarán como información '
                      'del club, sin enlaces externos.',
                  Icons.alternate_email_rounded,
                ),
                const SizedBox(height: 20),
                _field(
                  context,
                  title: 'Instagram',
                  hint: '@tuclub',
                  icon: Icons.camera_alt_outlined,
                  controller: _instagramController,
                  maxLength: 200,
                  required: false,
                ),
                _field(
                  context,
                  title: 'Facebook',
                  hint: 'Nombre de la página',
                  icon: Icons.facebook_outlined,
                  controller: _facebookController,
                  maxLength: 200,
                  required: false,
                ),
                _field(
                  context,
                  title: 'X',
                  hint: '@tuclub',
                  icon: Icons.alternate_email_rounded,
                  controller: _xController,
                  maxLength: 200,
                  required: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          Text(
            'El club aparecerá en la comunidad una vez creado. '
            'El contador de lectores comenzará en cero.',
            style: GoogleFonts.inter(
              color: textSecondary,
              fontSize: 10,
              height: 1.6,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(
              _error!,
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.error,
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_stories_rounded),
              label: Text(
                _saving ? 'Creando club...' : 'Crear club de lectura',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
