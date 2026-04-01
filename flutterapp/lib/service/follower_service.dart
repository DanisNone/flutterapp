import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutterapp/model/user_info.dart';
import 'package:flutterapp/service/api.dart' as api;

class FollowerService extends ChangeNotifier {
  static const int _pageSize = 25;

  final List<UserInfo> _followers = <UserInfo>[];
  final List<UserInfo> _following = <UserInfo>[];
  final Set<int> _followingIds = <int>{};
  final Set<int> _pendingRelations = <int>{};

  bool _isLoadingFollowers = false;
  bool _isLoadingFollowing = false;
  bool _isRefreshing = false;

  int _followersLoadSerial = 0;
  int _followingLoadSerial = 0;

  String? _followersError;
  String? _followingError;
  String? _mutationError;

  String? _nextFollowersCursor;
  String? _nextFollowingCursor;
  bool _hasMoreFollowers = true;
  bool _hasMoreFollowing = true;

  String _followersQuery = '';
  String _followingQuery = '';
  bool _followersLoadedOnce = false;
  bool _followingLoadedOnce = false;

  List<UserInfo> get followers => List.unmodifiable(_followers);
  List<UserInfo> get following => List.unmodifiable(_following);
  Set<int> get followingIds => Set.unmodifiable(_followingIds);

  bool get isLoadingFollowers => _isLoadingFollowers;
  bool get isLoadingFollowing => _isLoadingFollowing;
  bool get isRefreshing => _isRefreshing;
  bool get hasFollowers => _followers.isNotEmpty;
  bool get hasFollowing => _following.isNotEmpty;

  bool get hasMoreFollowers => _hasMoreFollowers;
  bool get hasMoreFollowing => _hasMoreFollowing;
  bool get isFollowersReady => _followersLoadedOnce;
  bool get isFollowingReady => _followingLoadedOnce;

  String? get followersError => _followersError;
  String? get followingError => _followingError;
  String? get mutationError => _mutationError;

  bool isFollowing(int userId) => _followingIds.contains(userId);
  bool isRelationPending(int userId) => _pendingRelations.contains(userId);

  Future<void> loadFirstFollowersPage({String query = ''}) async {
    final normalized = query.trim();
    final shouldReset = !_followersLoadedOnce || normalized != _followersQuery;

    final requestId = ++_followersLoadSerial;

    if (shouldReset) {
      _followers.clear();
      _nextFollowersCursor = null;
      _hasMoreFollowers = true;
      _followersError = null;
      _followersQuery = normalized;
      _followersLoadedOnce = false;
    }

    _isLoadingFollowers = true;
    notifyListeners();

    try {
      final page = await api.getFollowersPage(
        limit: _pageSize,
        cursor: null,
        q: normalized.isEmpty ? null : normalized,
      );
      if (requestId != _followersLoadSerial) return;
      _replaceFollowers(page);
      _followersLoadedOnce = true;
      _followersError = null;
    } catch (e) {
      if (requestId == _followersLoadSerial) {
        _followersError = e.toString();
      }
    } finally {
      if (requestId == _followersLoadSerial) {
        _isLoadingFollowers = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMoreFollowers() async {
    if (_isLoadingFollowers || !_hasMoreFollowers) return;

    _isLoadingFollowers = true;
    notifyListeners();

    try {
      final page = await api.getFollowersPage(
        limit: _pageSize,
        cursor: _nextFollowersCursor,
        q: _followersQuery.isEmpty ? null : _followersQuery,
      );
      _appendFollowers(page);
      _followersError = null;
    } catch (e) {
      _followersError = e.toString();
    } finally {
      _isLoadingFollowers = false;
      notifyListeners();
    }
  }

  Future<void> loadFirstFollowingPage({String query = ''}) async {
    final normalized = query.trim();
    final shouldReset = !_followingLoadedOnce || normalized != _followingQuery;

    final requestId = ++_followingLoadSerial;

    if (shouldReset) {
      _following.clear();
      _followingIds.clear();
      _nextFollowingCursor = null;
      _hasMoreFollowing = true;
      _followingError = null;
      _followingQuery = normalized;
      _followingLoadedOnce = false;
    }

    _isLoadingFollowing = true;
    notifyListeners();

    try {
      final page = await api.getFollowingPage(
        limit: _pageSize,
        cursor: null,
        q: normalized.isEmpty ? null : normalized,
      );
      if (requestId != _followingLoadSerial) return;
      _replaceFollowing(page);
      _followingLoadedOnce = true;
      _followingError = null;
    } catch (e) {
      if (requestId == _followingLoadSerial) {
        _followingError = e.toString();
      }
    } finally {
      if (requestId == _followingLoadSerial) {
        _isLoadingFollowing = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMoreFollowing() async {
    if (_isLoadingFollowing || !_hasMoreFollowing) return;

    _isLoadingFollowing = true;
    notifyListeners();

    try {
      final page = await api.getFollowingPage(
        limit: _pageSize,
        cursor: _nextFollowingCursor,
        q: _followingQuery.isEmpty ? null : _followingQuery,
      );
      _appendFollowing(page);
      _followingError = null;
    } catch (e) {
      _followingError = e.toString();
    } finally {
      _isLoadingFollowing = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    _followersError = null;
    _followingError = null;
    notifyListeners();

    try {
      await Future.wait([
        loadFirstFollowersPage(query: _followersQuery),
        loadFirstFollowingPage(query: _followingQuery),
      ]);
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<bool> follow(int userId) async {
    if (userId <= 0 || isFollowing(userId) || _pendingRelations.contains(userId)) {
      return true;
    }

    _pendingRelations.add(userId);
    _mutationError = null;
    notifyListeners();

    try {
      await api.followUser(userId);
      _followingIds.add(userId);
      _updateRelationCache(userId, true);
      return true;
    } catch (e) {
      _mutationError = e.toString();
      if (kDebugMode) {
        debugPrint('FollowerService.follow error: $e');
      }
      return false;
    } finally {
      _pendingRelations.remove(userId);
      notifyListeners();
    }
  }

  Future<bool> unfollow(int userId) async {
    if (userId <= 0 || !isFollowing(userId) || _pendingRelations.contains(userId)) {
      return true;
    }

    _pendingRelations.add(userId);
    _mutationError = null;
    notifyListeners();

    try {
      await api.unfollowUser(userId);
      _followingIds.remove(userId);
      _updateRelationCache(userId, false);
      return true;
    } catch (e) {
      _mutationError = e.toString();
      if (kDebugMode) {
        debugPrint('FollowerService.unfollow error: $e');
      }
      return false;
    } finally {
      _pendingRelations.remove(userId);
      notifyListeners();
    }
  }

  void clear() {
    _followers.clear();
    _following.clear();
    _followingIds.clear();
    _pendingRelations.clear();
    _isLoadingFollowers = false;
    _isLoadingFollowing = false;
    _isRefreshing = false;
    _followersError = null;
    _followingError = null;
    _mutationError = null;
    _nextFollowersCursor = null;
    _nextFollowingCursor = null;
    _hasMoreFollowers = true;
    _hasMoreFollowing = true;
    _followersQuery = '';
    _followingQuery = '';
    _followersLoadedOnce = false;
    _followingLoadedOnce = false;
    _followersLoadSerial = 0;
    _followingLoadSerial = 0;
    notifyListeners();
  }

  void _replaceFollowers(api.PagedUserInfoPage page) {
    _followers
      ..clear()
      ..addAll(page.users);
    _nextFollowersCursor = page.nextCursor;
    _hasMoreFollowers = page.hasMore;
    _syncFollowingFlags(page.users);
  }

  void _appendFollowers(api.PagedUserInfoPage page) {
    _followers.addAll(page.users);
    _nextFollowersCursor = page.nextCursor;
    _hasMoreFollowers = page.hasMore;
    _syncFollowingFlags(page.users);
  }

  void _replaceFollowing(api.PagedUserInfoPage page) {
    _following
      ..clear()
      ..addAll(page.users);
    _followingIds
      ..clear()
      ..addAll(page.users.map((user) => user.id));
    _nextFollowingCursor = page.nextCursor;
    _hasMoreFollowing = page.hasMore;
    _syncFollowingFlags(page.users, following: true);
  }

  void _appendFollowing(api.PagedUserInfoPage page) {
    _following.addAll(page.users);
    _followingIds.addAll(page.users.map((user) => user.id));
    _nextFollowingCursor = page.nextCursor;
    _hasMoreFollowing = page.hasMore;
    _syncFollowingFlags(page.users, following: true);
  }

  void _updateRelationCache(int userId, bool following) {
    for (var i = 0; i < _followers.length; i++) {
      if (_followers[i].id == userId) {
        _followers[i] = _followers[i].copyWith(isFollowing: following);
      }
    }
    for (var i = 0; i < _following.length; i++) {
      if (_following[i].id == userId) {
        _following[i] = _following[i].copyWith(isFollowing: following);
      }
    }
  }

  void _syncFollowingFlags(List<UserInfo> users, {bool? following}) {
    for (final user in users) {
      if (user.isFollowing == true) {
        _followingIds.add(user.id);
      } else if (user.isFollowing == false && following == null) {
        _followingIds.remove(user.id);
      }
      if (following != null) {
        if (following) {
          _followingIds.add(user.id);
        } else {
          _followingIds.remove(user.id);
        }
      }
    }
  }
}
