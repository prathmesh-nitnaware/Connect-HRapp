import 'package:flutter/material.dart';
import '../core/network/api_service.dart';
import '../models/document_asset_model.dart';

class DocumentAssetProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<VaultDocument> _documents = [];
  List<CompanyAsset> _assets = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<VaultDocument> get documents => _documents;
  List<CompanyAsset> get assets => _assets;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMyDocuments({String? token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _documents = await _apiService.getMyDocuments(token: token);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadDocument(Map<String, dynamic> payload, {String? token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final doc = await _apiService.uploadDocument(payload, token: token);
      _documents.insert(0, doc);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchMyAssets({String? token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _assets = await _apiService.getMyAssets(token: token);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllAssets({String? token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _assets = await _apiService.getAllAssets(token: token);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> assignAsset(Map<String, dynamic> payload, {String? token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final item = await _apiService.assignAsset(payload, token: token);
      _assets.insert(0, item);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
