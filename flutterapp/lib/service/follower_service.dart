import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutterapp/model/user_info.dart';
import 'package:flutterapp/service/api.dart' as api;


class FollowerService extends ChangeNotifier {
  static final FollowerService _instance = FollowerService._internal();
  factory FollowerService() => _instance;
  FollowerService._internal();

  final Set<int> _followingIds = <int>{};
  final List<UserInfo> _followers = [];
  
  bool _isLoading = false;
  String? _error;

  Set<int> get followingIds => Set.unmodifiable(_followingIds);
  List<UserInfo> get followers => List.unmodifiable(_followers);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasFollowers => _followers.isNotEmpty;

  bool isFollowing(int userId) => _followingIds.contains(userId);

  Future<void> initialize() async {
    if (_isLoading) return;
    await _load(false);
  }

  Future<void> refresh() async {
    await _load(true);
  }

  Future<void> _load(bool refresh) async {
    _isLoading = true;
    if (refresh) {
      _error = null;
    }
    notifyListeners();

    await _loadFollowing();
    await _loadFollowers();
  }
  Future<void> _loadFollowers() async {
    try {
      final followers = await api.getFollowers(limit: 1000, offset: 0);
      
      _followers.clear();
      _followers.addAll(followers);
      _error = null;
      
      if (kDebugMode) {
        print('FollowerService: Загружено ${_followers.length} подписчиков');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('FollowerService: Ошибка загрузки - $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFollowing() async {
    try {
      final following = await api.getFollowing(limit: 1000, offset: 0);
      
      _followingIds.clear();
      _followingIds.addAll(following.map((f) => f.id));
      _error = null;
      
      if (kDebugMode) {
        print('FollowerService: Загружено ${_followingIds.length} подписчиков');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('FollowerService: Ошибка загрузки - $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> follow(int userId) async {
    try {
      await api.followUser(userId);
      _followingIds.add(userId);
      
      await refresh();
      
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('FollowerService: Ошибка подписки - $e');
      }
      return false;
    }
  }

  Future<bool> unfollow(int userId) async {
    // TODO: Добавить API метод для отписки если нужно
    // _followingIds.remove(userId);
    // _followers.removeWhere((f) => f.id == userId);
    notifyListeners();
    return true;
  }

  void clear() {
    _followingIds.clear();
    _followers.clear();
    _error = null;
    notifyListeners();
  }
}
