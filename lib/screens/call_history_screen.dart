import 'package:flutter/material.dart';
import '../models/call_history.dart';
import '../services/call_history_service.dart';
import '../services/contact_service.dart';

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  final CallHistoryService _historyService = CallHistoryService();
  final ContactService _contactService = ContactService();
  List<CallHistory> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadContacts();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    await _historyService.loadHistory();
    setState(() {
      _history = _historyService.history;
      _isLoading = false;
    });
  }

  Future<void> _loadContacts() async {
    await _contactService.loadContacts();
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить историю?'),
        content: const Text('Все записи будут удалены без возможности восстановления'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _historyService.clearHistory();
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('История звонков'),
        elevation: 0,
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearHistory,
              tooltip: 'Очистить историю',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    itemCount: _history.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      return _buildCallHistoryItem(_history[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'История звонков пуста',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ваши звонки будут отображаться здесь',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallHistoryItem(CallHistory call) {
    final isIncoming = call.type == CallType.incoming;
    final isMissed = call.status == CallStatus.missed;
    final isRejected = call.status == CallStatus.rejected;
    
    Color iconColor;
    IconData iconData;
    
    if (isMissed) {
      iconColor = const Color(0xFF6D6D6D);
      iconData = Icons.phone_missed;
    } else if (isRejected) {
      iconColor = const Color(0xFF5D5D5D);
      iconData = Icons.phone_disabled;
    } else if (isIncoming) {
      iconColor = const Color(0xFF8D8D8D);
      iconData = Icons.phone_callback;
    } else {
      iconColor = const Color(0xFF4D4D4D);
      iconData = Icons.phone_forwarded;
    }

    // Format date without locale dependency
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final callDate = DateTime(call.timestamp.year, call.timestamp.month, call.timestamp.day);
    
    String dateStr;
    if (callDate == today) {
      dateStr = 'Сегодня ${call.timestamp.hour.toString().padLeft(2, '0')}:${call.timestamp.minute.toString().padLeft(2, '0')}';
    } else if (callDate == yesterday) {
      dateStr = 'Вчера ${call.timestamp.hour.toString().padLeft(2, '0')}:${call.timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      dateStr = '${call.timestamp.day}.${call.timestamp.month}.${call.timestamp.year} ${call.timestamp.hour.toString().padLeft(2, '0')}:${call.timestamp.minute.toString().padLeft(2, '0')}';
    }
    
    String durationStr = '';
    if (call.duration.inSeconds > 0) {
      final minutes = call.duration.inMinutes;
      final seconds = call.duration.inSeconds % 60;
      durationStr = minutes > 0 ? '$minutes мин $seconds сек' : '$seconds сек';
    }

    String displayId = isIncoming ? call.callerId : call.receiverId;
    String? contactName = _contactService.getContactName(displayId);
    String displayName = contactName ?? 'ID: $displayId';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2D2D2D).withOpacity(0.5),
          ),
          child: Icon(iconData, color: iconColor, size: 24),
        ),
        title: Text(
          displayName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: const Color(0xFF6D6D6D),
                ),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6D6D6D),
                  ),
                ),
              ],
            ),
            if (durationStr.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.timer,
                    size: 14,
                    color: const Color(0xFF6D6D6D),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    durationStr,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6D6D6D),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.grey[600]),
          onSelected: (value) async {
            if (value == 'delete') {
              await _deleteCallRecord(call);
            } else if (value == 'add_contact') {
              await _addToContacts(displayId, contactName);
            }
          },
          itemBuilder: (context) => [
            if (contactName == null)
              const PopupMenuItem(
                value: 'add_contact',
                child: Row(
                  children: [
                    Icon(Icons.person_add, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Добавить в контакты'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Удалить запись'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCallRecord(CallHistory call) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить запись?'),
        content: const Text('Эта запись будет удалена из истории'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _historyService.deleteCall(call.id);
      _loadHistory();
    }
  }

  Future<void> _addToContacts(String id, String? existingName) async {
    if (existingName != null) return;

    final nameController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить в контакты'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ID: $id', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Имя контакта',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      await _contactService.addContact(id, nameController.text);
      setState(() {});
    }
  }
}
