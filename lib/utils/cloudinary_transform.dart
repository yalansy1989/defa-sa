// lib/utils/cloudinary_transform.dart

enum CloudinaryPreset {
  collectionSlider,
  productCover,
  thumbnail,
}

String cloudinaryTransform(
  String url, {
  CloudinaryPreset preset = CloudinaryPreset.collectionSlider,
  int? w,
  int? h,
}) {
  final u = url.trim();
  if (u.isEmpty) return u;

  if (!u.contains("res.cloudinary.com") || !u.contains("/image/upload/")) {
    return u;
  }

  // لو فيه Transform مسبقًا لا نكرر
  if (RegExp(r"/image/upload/[^/]+/").hasMatch(u)) return u;

  const marker = "/image/upload/";
  final parts = u.split(marker);
  if (parts.length != 2) return u;

  int ww;
  int hh;

  switch (preset) {
    case CloudinaryPreset.collectionSlider:
      ww = w ?? 1600;
      hh = h ?? 900;
      break;
    case CloudinaryPreset.productCover:
      ww = w ?? 900;
      hh = h ?? 900;
      break;
    case CloudinaryPreset.thumbnail:
      ww = w ?? 400;
      hh = h ?? 400;
      break;
  }

  final transform = "c_fill,g_auto,w_$ww,h_$hh,q_auto,f_auto,dpr_auto";
  return "${parts[0]}$marker$transform/${parts[1]}";
}

// (توافق خلفي)
String smartSliderUrl(String url, {int w = 1600, int h = 900}) {
  return cloudinaryTransform(
    url,
    preset: CloudinaryPreset.collectionSlider,
    w: w,
    h: h,
  );
}
