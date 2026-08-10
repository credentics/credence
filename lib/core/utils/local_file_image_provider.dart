import 'package:flutter/widgets.dart';
import 'package:pass_doc_manager/core/utils/local_file_image_provider_stub.dart'
    if (dart.library.io) 'package:pass_doc_manager/core/utils/local_file_image_provider_io.dart';

ImageProvider<Object>? resolveLocalFileImageProvider(String? localPath) {
  return resolveLocalFileImageProviderImpl(localPath);
}
