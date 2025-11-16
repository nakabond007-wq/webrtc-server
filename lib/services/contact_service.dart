import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact.dart';

class ContactService {
  static final ContactService _instance = ContactService._internal();
  factory ContactService() => _instance;
  ContactService._internal();

  static const String _contactsKey = 'contacts';
  List<Contact> _contacts = [];

  List<Contact> get contacts => _contacts;

  Future<void> loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = prefs.getString(_contactsKey);
    
    if (contactsJson != null) {
      final List<dynamic> decoded = jsonDecode(contactsJson);
      _contacts = decoded.map((json) => Contact.fromJson(json)).toList();
      _contacts.sort((a, b) => a.name.compareTo(b.name));
    }
  }

  Future<void> addContact(String id, String name) async {
    // Check if contact already exists
    if (_contacts.any((c) => c.id == id)) {
      // Update existing contact
      _contacts = _contacts.map((c) => 
        c.id == id ? Contact(id: id, name: name, addedAt: c.addedAt) : c
      ).toList();
    } else {
      // Add new contact
      _contacts.add(Contact(
        id: id,
        name: name,
        addedAt: DateTime.now(),
      ));
    }
    
    _contacts.sort((a, b) => a.name.compareTo(b.name));
    await _saveContacts();
  }

  Future<void> deleteContact(String id) async {
    _contacts.removeWhere((c) => c.id == id);
    await _saveContacts();
  }

  String? getContactName(String id) {
    final contact = _contacts.firstWhere(
      (c) => c.id == id,
      orElse: () => Contact(id: '', name: '', addedAt: DateTime.now()),
    );
    return contact.id.isNotEmpty ? contact.name : null;
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = jsonEncode(_contacts.map((c) => c.toJson()).toList());
    await prefs.setString(_contactsKey, contactsJson);
  }

  Future<void> clearContacts() async {
    _contacts.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_contactsKey);
  }
}
