import 'package:flutter/material.dart';
import 'package:flutterapp/constants/app_colors.dart';

class ImageLoader {
  final Map<String, ImageProvider<NetworkImage>> _imageCache = {};
  static final ImageLoader instance = ImageLoader._internal();
  factory ImageLoader() {
    return instance;
  }
  ImageLoader._internal();
  
  ImageProvider<NetworkImage> _loadImage(String url) {
    if (!_imageCache.containsKey(url)) {
      _imageCache[url] = NetworkImage(url);
    }
    return _imageCache[url]!;
  }
  Container loadImage(String? url, double size, Widget byFail) {
    ImageProvider<NetworkImage>? provider;

    if (url != null && url.isNotEmpty) {
      provider = _loadImage(url);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.borderGlow,
          width: 2,
        ),
        image: provider != null
            ? DecorationImage(
                image: provider,
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: provider == null ? byFail : null,
    );
  }
}