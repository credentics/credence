class LocalFileMimeTypes {
  const LocalFileMimeTypes._();

  static const png = 'image/png';
  static const jpeg = 'image/jpeg';
  static const heic = 'image/heic';
  static const webp = 'image/webp';
  static const pdf = 'application/pdf';
  static const docx =
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
  static const doc = 'application/msword';
  static const xlsx =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  static const xls = 'application/vnd.ms-excel';
  static const pptx =
      'application/vnd.openxmlformats-officedocument.presentationml.presentation';
  static const ppt = 'application/vnd.ms-powerpoint';
  static const txt = 'text/plain';
  static const rtf = 'application/rtf';
  static const csv = 'text/csv';
  static const binary = 'application/octet-stream';

  static bool canPreview(String mime) {
    final normalized = mime.trim().toLowerCase();
    return normalized == pdf || normalized.startsWith('image/');
  }
}

extension LocalFilePathX on String {
  String get normalizedLowerPath => trim().toLowerCase();

  String get fileExtension {
    final normalized = normalizedLowerPath;
    final dotIndex = normalized.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == normalized.length - 1) {
      return '';
    }
    return normalized.substring(dotIndex);
  }

  String inferMimeType({String fallback = LocalFileMimeTypes.binary}) {
    return switch (fileExtension) {
      '.png' => LocalFileMimeTypes.png,
      '.jpg' || '.jpeg' => LocalFileMimeTypes.jpeg,
      '.heic' => LocalFileMimeTypes.heic,
      '.webp' => LocalFileMimeTypes.webp,
      '.pdf' => LocalFileMimeTypes.pdf,
      '.docx' => LocalFileMimeTypes.docx,
      '.doc' => LocalFileMimeTypes.doc,
      '.xlsx' => LocalFileMimeTypes.xlsx,
      '.xls' => LocalFileMimeTypes.xls,
      '.pptx' => LocalFileMimeTypes.pptx,
      '.ppt' => LocalFileMimeTypes.ppt,
      '.txt' => LocalFileMimeTypes.txt,
      '.rtf' => LocalFileMimeTypes.rtf,
      '.csv' => LocalFileMimeTypes.csv,
      _ => fallback,
    };
  }

  String inferFileTypeLabel({String fallback = 'FILE'}) {
    return switch (fileExtension) {
      '.pdf' => 'PDF',
      '.png' => 'PNG',
      '.jpg' || '.jpeg' => 'JPG',
      '.webp' => 'WEBP',
      '.heic' => 'HEIC',
      '.doc' || '.docx' => 'WORD',
      '.xls' || '.xlsx' => 'EXCEL',
      '.ppt' || '.pptx' => 'PPT',
      '.txt' => 'TXT',
      '.rtf' => 'RTF',
      '.csv' => 'CSV',
      _ => fallback,
    };
  }
}

extension MimeTypeX on String {
  String get normalizedMimeType => trim().toLowerCase();

  bool get isImageMimeType => normalizedMimeType.startsWith('image/');

  String? get preferredFileTypeLabel {
    final normalized = normalizedMimeType;
    if (normalized.isEmpty) {
      return null;
    }
    if (normalized == LocalFileMimeTypes.pdf) {
      return 'PDF';
    }
    if (normalized == LocalFileMimeTypes.doc ||
        normalized == LocalFileMimeTypes.docx) {
      return 'WORD';
    }
    if (normalized == LocalFileMimeTypes.xls ||
        normalized == LocalFileMimeTypes.xlsx) {
      return 'EXCEL';
    }
    if (normalized == LocalFileMimeTypes.ppt ||
        normalized == LocalFileMimeTypes.pptx) {
      return 'PPT';
    }
    if (normalized == LocalFileMimeTypes.txt) {
      return 'TXT';
    }
    if (normalized == LocalFileMimeTypes.rtf) {
      return 'RTF';
    }
    if (normalized == LocalFileMimeTypes.csv) {
      return 'CSV';
    }
    if (normalized.startsWith('image/')) {
      final subtype = normalized.replaceFirst('image/', '').trim();
      if (subtype.isEmpty) {
        return 'IMAGE';
      }
      if (subtype == 'jpeg' || subtype == 'jpg') {
        return 'JPG';
      }
      return subtype.toUpperCase();
    }
    return null;
  }
}

String resolveFileTypeLabel({
  required String path,
  required String mime,
  String fallback = 'FILE',
}) {
  return mime.preferredFileTypeLabel ??
      path.inferFileTypeLabel(fallback: fallback);
}
