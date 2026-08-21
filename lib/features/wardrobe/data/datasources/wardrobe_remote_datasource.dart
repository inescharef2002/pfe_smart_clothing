import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/analysis_history_model.dart';
import '../models/outfit_model.dart';
import '../models/wardrobe_item_model.dart';

const _cloudinaryCloud = 'defg4c0bd';
const _cloudinaryPreset = 'smartclothingadvisor';

abstract class WardrobeDataSource {
  Stream<List<WardrobeItemModel>> watchItems(String userId);
  Stream<List<OutfitModel>> watchOutfits(String userId);
  Stream<List<AnalysisHistoryModel>> watchHistory(String userId);
  Future<void> addItem(String userId, WardrobeItemModel item, XFile? imageFile);
  Future<void> updateItem(
      String userId, WardrobeItemModel item, XFile? imageFile);
  Future<void> deleteItem(String userId, String itemId);
  Future<void> addOutfit(String userId, OutfitModel outfit);
  Future<void> deleteOutfit(String userId, String outfitId);
  Future<String> getAiSuggestion(List<WardrobeItemModel> items);
  Future<String> logAnalysis(String userId, AnalysisHistoryModel entry);
  Future<void> markHistoryAsSaved(String userId, String historyId);
}

class WardrobeRemoteDataSource implements WardrobeDataSource {
  final FirebaseFirestore _firestore;

  WardrobeRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  Future<String> _uploadToCloudinary(List<int> bytes) async {
    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudinaryCloud/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _cloudinaryPreset
      ..files.add(http.MultipartFile.fromBytes('file', bytes,
          filename: 'wardrobe_${DateTime.now().millisecondsSinceEpoch}.jpg'));
    final response = await request.send();
    final body = await response.stream.bytesToString();
    final json = jsonDecode(body);
    return json['secure_url'] as String;
  }

  CollectionReference _wardrobeRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('wardrobe');

  CollectionReference _outfitsRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('outfits');

  CollectionReference _historyRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('analyses_history');

  @override
  Stream<List<AnalysisHistoryModel>> watchHistory(String userId) {
    return _historyRef(userId)
        .orderBy('analyzedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AnalysisHistoryModel.fromFirestore(d)).toList());
  }

  @override
  Future<String> logAnalysis(String userId, AnalysisHistoryModel entry) async {
    final doc = await _historyRef(userId).add(entry.toMap());
    return doc.id;
  }

  @override
  Future<void> markHistoryAsSaved(String userId, String historyId) async {
    await _historyRef(userId).doc(historyId).update({'savedToWardrobe': true});
  }

  @override
  Stream<List<WardrobeItemModel>> watchItems(String userId) {
    return _wardrobeRef(userId)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => WardrobeItemModel.fromFirestore(d)).toList());
  }

  @override
  Stream<List<OutfitModel>> watchOutfits(String userId) {
    return _outfitsRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => OutfitModel.fromFirestore(d)).toList());
  }

  @override
  Future<void> addItem(
      String userId, WardrobeItemModel item, XFile? imageFile) async {
    String imageUrl = item.imageUrl;
    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      imageUrl = await _uploadToCloudinary(bytes);
    }
    await _wardrobeRef(userId).add({
      ...item.toMap(),
      'imageUrl': imageUrl,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateItem(
      String userId, WardrobeItemModel item, XFile? imageFile) async {
    String imageUrl = item.imageUrl;
    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      imageUrl = await _uploadToCloudinary(bytes);
    }
    await _wardrobeRef(userId).doc(item.id).update({
      ...item.toMap(),
      'imageUrl': imageUrl,
    });
  }

  @override
  Future<void> deleteItem(String userId, String itemId) async {
    await _wardrobeRef(userId).doc(itemId).delete();
  }

  @override
  Future<void> addOutfit(String userId, OutfitModel outfit) async {
    await _outfitsRef(userId).add({
      ...outfit.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteOutfit(String userId, String outfitId) async {
    await _outfitsRef(userId).doc(outfitId).delete();
  }

  @override
  Future<String> getAiSuggestion(List<WardrobeItemModel> items) async {
    final apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
    final summary = items
        .map((i) =>
            '- ${i.nom} (${i.categorie}${i.couleur.isNotEmpty ? ', ${i.couleur}' : ''}${i.taille.isNotEmpty ? ', taille ${i.taille}' : ''})')
        .join('\n');

    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-haiku-4-5-20251001',
        'max_tokens': 600,
        'system':
            'Tu es un conseiller mode expert et bienveillant. Tu réponds toujours en français, de façon chaleureuse et concise.',
        'messages': [
          {
            'role': 'user',
            'content':
                'Voici ma garde-robe :\n$summary\n\nPropose 2-3 tenues complètes à composer avec ces vêtements. Pour chaque tenue, donne un nom, les pièces à associer et un conseil stylistique court. Sois concis et pratique.',
          }
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['content'] as List)
          .firstWhere((c) => c['type'] == 'text',
              orElse: () => {'text': ''})['text'] as String;
    }
    throw Exception('Erreur serveur (${response.statusCode})');
  }
}
