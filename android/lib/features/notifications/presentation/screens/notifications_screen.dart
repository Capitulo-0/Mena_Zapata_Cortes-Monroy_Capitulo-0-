import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../follow/data/follow_repository.dart';
import '../../data/notification_repository.dart';
import '../../domain/reader_notification.dart';

/// Authenticated inbox. The parent owns navigation and account scoping.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.repository,
    this.followRepository,
    this.onBack,
  });

  final NotificationRepository repository;
  final FollowRepository? followRepository;
  final VoidCallback? onBack;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<ReaderNotification> _items = [];
  final Set<int> _updatingIds = <int>{};
  bool _loading = true;
  bool _loadingMore = false;
  bool _lastPage = true;
  String? _error;
  int _nextPage = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.repository.getInbox();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.notifications);
        _nextPage = page.page + 1;
        _lastPage = page.isLast;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _errorMessage(error);
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || _lastPage) return;
    setState(() => _loadingMore = true);
    try {
      final page = await widget.repository.getInbox(page: _nextPage);
      if (!mounted) return;
      setState(() {
        final existingIds = _items.map((item) => item.id).toSet();
        _items.addAll(
          page.notifications.where((item) => !existingIds.contains(item.id)),
        );
        _nextPage = page.page + 1;
        _lastPage = page.isLast;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    }
  }

  Future<void> _markRead(ReaderNotification item) async {
    if (item.isRead || _updatingIds.contains(item.id)) return;
    setState(() => _updatingIds.add(item.id));
    try {
      final updated = await widget.repository.markRead(item.id);
      if (!mounted) return;
      setState(() {
        final index = _items.indexWhere((entry) => entry.id == item.id);
        if (index >= 0) _items[index] = updated;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    } finally {
      if (mounted) setState(() => _updatingIds.remove(item.id));
    }
  }

  Future<void> _resolveRequest(
    ReaderNotification item, {
    required bool accept,
  }) async {
    final followRepository = widget.followRepository;
    final followId = item.followId;
    if (followRepository == null ||
        followId == null ||
        item.type != ReaderNotificationType.followRequest ||
        _updatingIds.contains(item.id)) {
      return;
    }

    setState(() => _updatingIds.add(item.id));
    try {
      if (accept) {
        await followRepository.acceptRequest(followId);
      } else {
        await followRepository.rejectRequest(followId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accept ? 'Solicitud autorizada.' : 'Solicitud descartada.',
          ),
        ),
      );
      // El backend cambia FOLLOW_REQUEST a NEW_FOLLOWER al aprobar,
      // y elimina la notificación pendiente al descartar.
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_errorMessage(error))));
      // Una solicitud podría haberse cancelado en otra sesión.
      // Sincronizar el buzón con el estado real del servidor.
      await _refresh();
    } finally {
      if (mounted) setState(() => _updatingIds.remove(item.id));
    }
  }

  String _errorMessage(Object error) => error is ApiFailure
      ? error.message
      : 'No pudimos cargar las notificaciones. Inténtalo de nuevo.';

  String _section(DateTime time) {
    final now = DateTime.now();
    final local = time.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final difference = today.difference(day).inDays;
    if (difference <= 0) return 'Hoy';
    if (difference == 1) return 'Ayer';
    if (difference < 7) return 'Últimos 7 días';
    if (difference < 30) return 'Últimos 30 días';
    return 'Anteriores';
  }

  String _message(ReaderNotification item) {
    switch (item.type) {
      case ReaderNotificationType.followRequest:
        return '${item.actorHandle} quiere seguir tus lecturas';
      case ReaderNotificationType.newFollower:
        return '${item.actorHandle} ahora forma parte de tus seguidores';
      case ReaderNotificationType.followAccepted:
        return '${item.actorHandle} aprobó tu solicitud. ¡Ya puedes descubrir sus lecturas!';
      case ReaderNotificationType.organizerApproved:
        return '¡Tu organización fue verificada! El equipo de Capítulo 0 aprobó tu solicitud.';
      case ReaderNotificationType.organizerRejected:
        return 'Tu solicitud de verificación fue rechazada. Consulta el motivo en Perfil → Configuración → Verificación de organizador.';
    }
  }

  String _dateLabel(DateTime time) {
    final date = time.toLocal();
    final now = DateTime.now();
    final minutes = now.difference(date).inMinutes;
    if (minutes >= 0 && minutes < 1) return 'Ahora';
    if (minutes >= 0 && minutes < 60) return 'Hace $minutes min';
    if (minutes >= 0 && minutes < 1440) return 'Hace ${minutes ~/ 60} h';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _notificationTile(ReaderNotification item) {
    final primary = AppColors.textPrimaryOf(context);
    final secondary = AppColors.textSecondaryOf(context);
    final gold = AppColors.goldOf(context);
    final isOrganizerNotification = item.isOrganizerNotification;
    final IconData notificationIcon = isOrganizerNotification
        ? (item.type == ReaderNotificationType.organizerApproved
              ? Icons.verified_rounded
              : Icons.info_outline_rounded)
        : Icons.person_outline;
    final avatarUrl = isOrganizerNotification ? null : item.actorAvatarUrl;
    final hasAvatar =
        avatarUrl != null &&
        (avatarUrl.startsWith('https://') || avatarUrl.startsWith('http://'));

    return Card(
      color: AppColors.surfaceOf(context),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: gold.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: item.isRead ? null : () => _markRead(item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: gold.withValues(alpha: 0.15),
                backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                child: hasAvatar ? null : Icon(notificationIcon, color: gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _message(item),
                      style: GoogleFonts.inter(
                        color: primary,
                        fontSize: 13,
                        fontWeight: item.isRead
                            ? FontWeight.w400
                            : FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _dateLabel(item.occurredAt),
                      style: GoogleFonts.inter(color: secondary, fontSize: 11),
                    ),
                    if (item.type == ReaderNotificationType.followRequest) ...[
                      const SizedBox(height: 8),
                      if (widget.followRepository != null &&
                          item.followId != null)
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: _updatingIds.contains(item.id)
                                    ? null
                                    : () => _resolveRequest(item, accept: true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.accentOf(context),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Autorizar'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _updatingIds.contains(item.id)
                                    ? null
                                    : () =>
                                          _resolveRequest(item, accept: false),
                                child: const Text('Descartar'),
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          'Solicitud pendiente · Actualiza para revisar su estado.',
                          style: GoogleFonts.inter(
                            color: secondary,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              if (!item.isRead)
                Padding(
                  padding: const EdgeInsets.only(left: 6, top: 4),
                  child: _updatingIds.contains(item.id)
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : CircleAvatar(
                          radius: 5,
                          backgroundColor: AppColors.accentOf(context),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.textPrimaryOf(context);
    final secondary = AppColors.textSecondaryOf(context);
    final grouped = <String, List<ReaderNotification>>{};
    for (final item in _items) {
      grouped.putIfAbsent(_section(item.occurredAt), () => []).add(item);
    }
    const sections = [
      'Hoy',
      'Ayer',
      'Últimos 7 días',
      'Últimos 30 días',
      'Anteriores',
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.deepOf(context),
        foregroundColor: AppColors.goldOf(context),
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          'NOTIFICACIONES',
          style: GoogleFonts.cinzel(fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_outlined, size: 38, color: secondary),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: primary),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _refresh,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: _items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        Icon(
                          Icons.notifications_none_rounded,
                          size: 54,
                          color: secondary,
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: Text(
                            'Aún no tienes notificaciones',
                            style: GoogleFonts.inter(
                              color: primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Aquí aparecerán las novedades de tus lecturas.',
                            style: GoogleFonts.inter(
                              color: secondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                      children: [
                        for (final section in sections)
                          if (grouped.containsKey(section)) ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: 10,
                                top: 8,
                              ),
                              child: Text(
                                section,
                                style: GoogleFonts.inter(
                                  color: primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            for (final item in grouped[section]!)
                              _notificationTile(item),
                          ],
                        if (!_lastPage)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: _loadingMore
                                  ? const CircularProgressIndicator()
                                  : OutlinedButton(
                                      onPressed: _loadMore,
                                      child: const Text('Cargar más'),
                                    ),
                            ),
                          ),
                      ],
                    ),
            ),
    );
  }
}
