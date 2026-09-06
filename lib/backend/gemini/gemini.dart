import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/flutter_flow/flutter_flow_util.dart';

Future<String?> geminiGenerateText(
  BuildContext context,
  String prompt,
) =>
    _invokeGeminiFunction(
      context,
      {
        'action': 'generate_text',
        'model': 'gemini-2.5-flash',
        'prompt': prompt,
      },
    );

Future<String?> geminiCountTokens(
  BuildContext context,
  String prompt,
) =>
    _invokeGeminiFunction(
      context,
      {
        'action': 'count_tokens',
        'model': 'gemini-2.5-flash',
        'prompt': prompt,
      },
    );

Future<Uint8List> loadImageBytesFromUrl(String imageUrl) async {
  final bytes = await NetworkAssetBundle(Uri.parse(imageUrl)).load(imageUrl);
  return bytes.buffer.asUint8List();
}

Future<String?> geminiTextFromImage(
  BuildContext context,
  String prompt, {
  String? imageNetworkUrl = '',
  FFUploadedFile? uploadImageBytes,
}) async {
  assert(
    imageNetworkUrl != null || uploadImageBytes != null,
    'Either imageNetworkUrl or uploadImageBytes must be provided.',
  );

  final imageBytes = uploadImageBytes != null
      ? uploadImageBytes.bytes
      : await loadImageBytesFromUrl(imageNetworkUrl!);

  return _invokeGeminiFunction(
    context,
    {
      'action': 'text_from_image',
      'model': 'gemini-2.5-flash',
      'prompt': prompt,
      'image_base64': base64Encode(imageBytes!),
      'mime_type': 'image/jpeg',
    },
  );
}

Future<String?> _invokeGeminiFunction(
  BuildContext context,
  Map<String, dynamic> body,
) async {
  try {
    final response = await SupabaseDatabase.instance.client.functions.invoke(
      'gemini-proxy',
      body: body,
    );
    final data = response.data;
    if (data is Map && data['text'] != null) {
      return data['text'].toString();
    }
    if (data is Map && data['tokens'] != null) {
      return data['tokens'].toString();
    }
    return null;
  } catch (error) {
    showSnackbar(context, error.toString());
    return null;
  }
}
