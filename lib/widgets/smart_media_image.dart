import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:defa_sa/utils/media_processor.dart';
import 'package:defa_sa/services/media_service.dart';

class SmartMediaImage extends StatefulWidget {
  final String mediaId;
  final MediaUseCase useCase;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SmartMediaImage({
    super.key,
    required this.mediaId,
    required this.useCase,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<SmartMediaImage> createState() => _SmartMediaImageState();
}

class _SmartMediaImageState extends State<SmartMediaImage> {
  late Future<String?> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _resolveImageSource();
  }

  @override
  void didUpdateWidget(covariant SmartMediaImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaId != widget.mediaId) {
      setState(() {
        _imageFuture = _resolveImageSource();
      });
    }
  }

  Future<String?> _resolveImageSource() async {
    String id = widget.mediaId.trim();
    if (id.isEmpty) return null;

    if (id.startsWith('http')) return id;
    if (id.contains('assets/')) return 'ASSET:$id';

    // ✅ التحديث الحاسم: إضافة مسار المنتجات إلى قائمة البحث
    List<String> possiblePaths = [
      'media/products/$id',    // الأولوية لصور المنتجات كما ذكرت
      'media/$id',             // ثم المجلد الرئيسي
      'media/collections/$id', // ثم مجلد الكولكشن القديم
      id,                      // ثم الجذر
    ];

    for (String path in possiblePaths) {
      try {
        final ref = FirebaseStorage.instance.ref().child(path);
        final url = await ref.getDownloadURL();
        print('✅ [SmartImage] Found file at: $path');
        return url;
      } catch (e) {
        continue;
      }
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('media').doc(id).get();
      if (doc.exists && doc.data()?['url'] != null) {
        return doc.data()!['url'];
      }
    } catch (e) {
      // ignore
    }

    print('❌ [SmartImage] Failed to find image: $id');
    return MediaService.getRawUrl(id);
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: const Color(0xFF161B22),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFE0C097)),
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: const Color(0xFF161B22),
      child: Icon(Icons.image_not_supported_outlined, 
        color: Colors.white.withOpacity(0.2), 
        size: widget.width != null ? widget.width! * 0.4 : 24
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.placeholder ?? _buildPlaceholder(context);
        }

        final url = snapshot.data;
        if (url == null || url.isEmpty) {
          return widget.errorWidget ?? _buildError(context);
        }

        if (url.startsWith('ASSET:')) {
          return Image.asset(
            url.substring(6).replaceAll('media/', ''),
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            errorBuilder: (ctx, err, stack) => _buildError(context),
          );
        }

        String finalUrl = url;
        if (!url.contains('firebasestorage.googleapis.com')) {
           finalUrl = MediaProcessor.urlFor(url, widget.useCase);
        }

        return CachedNetworkImage(
          imageUrl: finalUrl,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          placeholder: (context, url) => widget.placeholder ?? _buildPlaceholder(context),
          errorWidget: (context, url, error) => widget.errorWidget ?? _buildError(context),
        );
      },
    );
  }
}