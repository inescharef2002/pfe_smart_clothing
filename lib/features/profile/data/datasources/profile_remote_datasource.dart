import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/profile_model.dart';

const _cloudinaryCloud = 'defg4c0bd';
const _cloudinaryPreset = 'smartclothingadvisor';

abstract class ProfileDataSource {
  Future<ProfileModel> getProfile(String userId);
  Future<void> updateProfile(String userId, ProfileModel profile, {XFile? imageFile});
  Future<String> uploadPhoto(String userId, XFile imageFile);
  Stream<List<Map<String, dynamic>>> watchOrders(String userId);
  Stream<int> watchWardrobeCount(String userId);
  Stream<int> watchCartCount(String userId);
  Stream<int> watchOrdersCount(String userId);
}

class ProfileRemoteDataSource implements ProfileDataSource {
  final FirebaseFirestore _firestore;

  ProfileRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  DocumentReference _userRef(String userId) =>
      _firestore.collection('users').doc(userId);

  Future<String> _uploadToCloudinary(List<int> bytes) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudinaryCloud/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _cloudinaryPreset
      ..files.add(http.MultipartFile.fromBytes('file', bytes,
          filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg'));
    final response = await request.send();
    final body = await response.stream.bytesToString();
    final json = jsonDecode(body) as Map<String, dynamic>;
    final url = json['secure_url'];
    if (url == null) throw Exception('Upload échoué : ${json['error']?['message'] ?? body}');
    return url as String;
  }

  @override
  Future<String> uploadPhoto(String userId, XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final url = await _uploadToCloudinary(bytes);
    // Met à jour UNIQUEMENT le champ photoUrl — aucun autre champ touché
    await _userRef(userId).set({'photoUrl': url}, SetOptions(merge: true));
    return url;
  }

  @override
  Future<ProfileModel> getProfile(String userId) async {
    final doc = await _userRef(userId).get();
    if (!doc.exists) {
      return ProfileModel(id: userId, nom: '', email: '');
    }
    return ProfileModel.fromFirestore(doc);
  }

  @override
  Future<void> updateProfile(String userId, ProfileModel profile, {XFile? imageFile}) async {
    String photoUrl = profile.photoUrl;
    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      photoUrl = await _uploadToCloudinary(bytes);
    }
    final data = {...profile.toMap(), 'photoUrl': photoUrl};
    await _userRef(userId).set(data, SetOptions(merge: true));
  }

  @override
  Stream<List<Map<String, dynamic>>> watchOrders(String userId) {
    return _firestore
        .collection('commandes')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  @override
  Stream<int> watchWardrobeCount(String userId) {
    return _userRef(userId)
        .collection('wardrobe')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  @override
  Stream<int> watchCartCount(String userId) {
    return _userRef(userId).collection('cart').snapshots().map((snap) {
      int total = 0;
      for (final doc in snap.docs) {
        total += (doc.data()['quantity'] as int? ?? 0);
      }
      return total;
    });
  }

  @override
  Stream<int> watchOrdersCount(String userId) {
    return _firestore
        .collection('commandes')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}
