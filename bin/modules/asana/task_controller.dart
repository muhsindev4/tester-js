import 'dart:convert';
import 'dart:typed_data';
import 'auth_controller.dart';
import 'package:dio/dio.dart';

class TaskController {
  Dio? _dio;

  TaskController() {
    _dio = Dio(
      BaseOptions(
        headers: {
          'Authorization': 'Bearer ${AuthController.getAccessToken}',
          'Content-Type': 'application/json'
        },
      ),
    );
  }

  // Create a new task
  Future<dynamic> createTask({
    required String title,
    String notes = "",
    String html_notes = "",
  }) async {
    final data = json.encode({
      "data": {
        "projects": "1207155941360865",
        "name": title,
        "notes": notes,
        // "html_notes":html_notes,
        // "assignee": ""
      }
    });

    final res = await _dio!.post("https://app.asana.com/api/1.0/tasks", data: data);
    print("RESp=${res.statusCode}");
    print("RESp=${res.data}");

    if (res.statusCode == 201) {
      return res.data;
    } else {
      return false;
    }
  }


  Future<dynamic> updateTaskHtmlNotes({
    required String taskId,
    required String htmlNotes,
  }) async {
    print("TOken=${AuthController.getAccessToken}");
    print("taskId=${taskId}");
    print("htmlNotes=${htmlNotes}");
    final data = json.encode({
      "data": {
        "html_notes": htmlNotes,
      }
    });

    try {
      final res = await _dio!.put(
        "https://app.asana.com/api/1.0/tasks/$taskId",
        data: data,
      );

      print("Response Status Code: ${res.statusCode}");
      print("Response Data: ${res.data}");

      if (res.statusCode == 200) {
        return res.data;
      } else {
        return false;
      }
    } catch (e) {
      print("Error: $e");
      return false;
    }
  }

  // Add comment to a task
  Future<bool> addCommentToTask({
    required String taskId,
    required String comment,
  }) async {
    final data = json.encode({
      "data": {
        "text": comment,
      }
    });

    final res = await _dio!.post(
      "https://app.asana.com/api/1.0/tasks/$taskId/stories",
      data: data,
    );
    print("RESp=${res.statusCode}");
    print("RESp=${res.data}");

    if (res.statusCode == 201) {
      return true;
    } else {
      return false;
    }
  }

  // Add attachment to a task
  Future<dynamic> addAttachmentToTask({
    required String taskId,
    required String base64Image,
  }) async {

    // Convert base64 string to bytes
    Uint8List imageBytes = base64Decode(base64Image);

    // Create MultipartFile from bytes
    final multipartFile = MultipartFile.fromBytes(
      imageBytes,
      filename: 'screenshot.png',
    );

    final formData = FormData.fromMap({
      'file': multipartFile,
      'parent': taskId,
    });
    final res = await _dio!.post(
      "https://app.asana.com/api/1.0/attachments",
      data: formData,
    );
    print("IMage Uplpaded-${res.data}");
    return res.data;
  }
}
