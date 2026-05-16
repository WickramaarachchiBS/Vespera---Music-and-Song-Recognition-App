import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class AudioCacheService {
  AudioCacheService._internal();
  static final AudioCacheService _instance = AudioCacheService._internal();
  factory AudioCacheService() => _instance;

  static const key = 'vespera-audio-cache';

  final CacheManager _cacheManager = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 200,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );

  /// Returns the cached file if present, otherwise null.
  Future<File?> getFileIfExists(String url) async {
    try {
      final info = await _cacheManager.getFileFromCache(url);
      return info?.file;
    } catch (e) {
      if (kDebugMode) print('getFileIfExists error: $e');
      return null;
    }
  }

  /// Prefetch the file into cache in background and return the cached File when done.
  Future<File?> prefetch(String url) async {
    try {
      final file = await _cacheManager.getSingleFile(url);
      return file;
    } catch (e) {
      if (kDebugMode) print('prefetch error: $e');
      return null;
    }
  }

  /// Get file (from cache or download). This will download if not cached.
  Future<File> getFile(String url) async {
    return await _cacheManager.getSingleFile(url);
  }

  Future<void> remove(String url) async {
    try {
      await _cacheManager.removeFile(url);
    } catch (e) {
      if (kDebugMode) print('remove cache error: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      await _cacheManager.emptyCache();
    } catch (e) {
      if (kDebugMode) print('clear cache error: $e');
    }
  }
}
