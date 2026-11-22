import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class NotificationsButton extends StatefulWidget {
  const NotificationsButton({super.key});
  @override
  State<NotificationsButton> createState() => _NotificationsButtonState();
}

class _NotificationsButtonState extends State<NotificationsButton> {
  Timer? _timer;
  List<dynamic>? _items;
  int _unread = 0;
  bool _error = false;
  VoidCallback? _refreshSheet;

  void _changed(VoidCallback change) {
    setState(change);
    _refreshSheet?.call();
  }

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _load() async {
    final token = ApiConstants.authToken;
    if (token == null) return;
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/notifications'), headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) throw StateError('HTTP ${response.statusCode}');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (mounted && token == ApiConstants.authToken) _changed(() { _items = data['items'] as List<dynamic>; _unread = data['unreadCount'] as int; _error = false; });
    } catch (_) { if (mounted && token == ApiConstants.authToken) _changed(() => _error = true); }
  }

  Future<void> _markRead(String id) async {
    final token = ApiConstants.authToken;
    if (token == null) return;
    try {
      final response = await http.patch(Uri.parse('${ApiConstants.baseUrl}/notifications/$id/read'), headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) throw StateError('HTTP ${response.statusCode}');
      await _load();
    } catch (_) { if (mounted) _changed(() => _error = true); }
  }

  void _open() {
    _load();
    showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (context) => _NotificationSheet(owner: this));
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: _unread > 0 ? 'Notificaciones: $_unread sin leer' : 'Notificaciones',
    onPressed: _open,
    icon: Badge(label: Text(_unread > 99 ? '99+' : '$_unread'), isLabelVisible: _unread > 0, child: const Icon(Icons.notifications_outlined)),
  );
}

class _NotificationSheet extends StatefulWidget {
  const _NotificationSheet({required this.owner});
  final _NotificationsButtonState owner;
  @override
  State<_NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends State<_NotificationSheet> {
  @override
  void initState() { super.initState(); widget.owner._refreshSheet = _refresh; }
  void _refresh() { if (mounted) setState(() {}); }
  @override
  void dispose() { widget.owner._refreshSheet = null; super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final owner = widget.owner;
    final items = owner._items;
    return SafeArea(child: SizedBox(height: MediaQuery.sizeOf(context).height * 0.65, child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 12, 12, 8), child: Row(children: [
        const Expanded(child: Text('Notificaciones', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600))),
        IconButton(tooltip: 'Cerrar', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
      ])),
      if (owner._error) Padding(padding: const EdgeInsets.all(12), child: Row(children: [
        const Expanded(child: Text('No se pudieron actualizar los avisos.')),
        TextButton(onPressed: owner._load, child: const Text('Reintentar')),
      ])),
      Expanded(child: items == null ? Center(child: owner._error ? const Text('Comprueba tu conexión.') : const CircularProgressIndicator()) : items.isEmpty ? const Center(child: Text('No tienes notificaciones.')) : ListView.separated(
        itemCount: items.length, separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = items[index] as Map<String, dynamic>;
          final unread = item['readAt'] == null;
          final date = DateTime.tryParse(item['createdAt'] as String? ?? '')?.toLocal();
          final dateText = date == null ? '' : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
          return ListTile(
            tileColor: unread ? const Color(0xFFF5F8FF) : null,
            title: Text(item['title'] as String? ?? '', style: TextStyle(fontWeight: unread ? FontWeight.w700 : FontWeight.w500)),
            subtitle: Text('${item['message'] ?? ''}\n$dateText'), isThreeLine: true,
            trailing: unread ? TextButton(onPressed: () => owner._markRead(item['id'] as String), child: const Text('Marcar leída')) : null,
          );
        },
      )),
    ])));
  }
}
