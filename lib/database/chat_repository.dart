import 'package:sqflite_sqlcipher/sqflite.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import 'database_helper.dart';

class ChatRepository {
  final DatabaseHelper _dbHelper;

  ChatRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<void> createConversation(Conversation conversation) async {
    final db = await _dbHelper.database;
    await db.insert(
      'conversations',
      conversation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Conversation>> getConversations() async {
    final db = await _dbHelper.database;
    final maps = await db.query('conversations', orderBy: 'updated_at DESC');

    final List<Conversation> conversations = [];
    for (final map in maps) {
      final convId = map['id'] as String;
      final lastMsgMap = await db.query(
        'messages',
        where: 'conversation_id = ?',
        whereArgs: [convId],
        orderBy: 'timestamp DESC',
        limit: 1,
      );

      String? lastMessage;
      if (lastMsgMap.isNotEmpty) {
        lastMessage = lastMsgMap.first['content'] as String;
      }

      conversations.add(Conversation.fromMap(map, lastMessage: lastMessage));
    }
    return conversations;
  }

  Future<void> deleteConversation(String id) async {
    final db = await _dbHelper.database;
    await db.delete('conversations', where: 'id = ?', whereArgs: [id]);
    await db.delete('messages', where: 'conversation_id = ?', whereArgs: [id]);
  }

  Future<void> insertMessage(ChatMessage message) async {
    final db = await _dbHelper.database;
    await db.insert('messages', message.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

    // Update conversation timestamp
    await db.update(
      'conversations',
      {'updated_at': message.timestamp.millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [message.conversationId],
    );
  }

  Future<List<ChatMessage>> getMessages(String conversationId, {int limit = 100, int offset = 0}) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp ASC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => ChatMessage.fromMap(map)).toList();
  }

  Future<void> updateMessageContent(String messageId, String newContent) async {
    final db = await _dbHelper.database;
    await db.update(
      'messages',
      {'content': newContent},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }
}
