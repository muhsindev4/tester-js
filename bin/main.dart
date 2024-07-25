import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'package:dio/dio.dart';
import 'modules/asana/auth_controller.dart';

Future<void> main() async {

  AuthController authController = AuthController(
      clientId: "1207894088371778",
      clientSecret: "de154df256c664c6d534198326431c49",
      redirectUri: "http://localhost:63342/plugin/index.html"
  );
  // Inject the CSS link into the head of the document
  final link = LinkElement()
    ..rel = 'stylesheet'
    ..href = 'style.css';
  document.head!.append(link);

  final body = document.body!;

  // Initialize buttons
  final drawButton = ButtonElement()
    ..text = 'Draw'
    ..id = 'drawButton'
    ..classes.add('custom-button');

  final reportButton = ButtonElement()
    ..text = 'Report'
    ..id = 'reportButton'
    ..classes.add('custom-button');

  final completeButton = ButtonElement()
    ..text = 'Complete'
    ..id = 'completeButton'
    ..classes.add('custom-button');

  final authButton = ButtonElement()
    ..text = 'Auth'
    ..id = 'authButton'
    ..classes.add('custom-button');

  final canvas = CanvasElement(width: window.innerWidth, height: window.innerHeight)
    ..id = 'drawingCanvas';
  final context = canvas.context2D;

  body.append(canvas);
  body.append(drawButton);
  body.append(completeButton);
  body.append(reportButton);
  body.append(authButton);

  bool isDrawing = false;

  void startDrawing() {
    canvas.style.pointerEvents = 'auto';
    body.style.cursor = 'crosshair';
  }

  void stopDrawing() {
    canvas.style.pointerEvents = 'none';
    body.style.cursor = 'default';
  }

  // OAuth authentication
  authButton.onClick.listen((event) {
    window.location.href = authController.authorizationUrl();
  });

  // Handle redirect and exchange code for token
  if (window.location.href.contains('code=')) {
    final uri = Uri.parse(window.location.href);
    final code = uri.queryParameters['code'];
    print("CODE:-  $code  ");
    if (code != null) {
     await authController.fetchToken(code);
     print("authController.accessToken!${authController.accessToken!}");
      // Store token
      // window.localStorage['asana_token'] = authController.accessToken!;
      // print("window.localStorage:-${window.localStorage['asana_token']}");
      // exchangeCodeForToken(code);
    }
  }



  // Draw on canvas
  drawButton.onClick.listen((event) {
    startDrawing();
  });

  completeButton.onClick.listen((event) async {
    stopDrawing();
    await captureScreenshot();
  });

  reportButton.onClick.listen((event) {
    showReportInput();
  });

  canvas.onMouseDown.listen((event) {
    isDrawing = true;
    context.beginPath();
    context.moveTo(event.client.x, event.client.y);
  });

  canvas.onMouseMove.listen((event) {
    if (isDrawing) {
      context.lineTo(event.client.x, event.client.y);
      context.stroke();
    }
  });

  canvas.onMouseUp.listen((event) {
    isDrawing = false;
  });

  canvas.onMouseOut.listen((event) {
    isDrawing = false;
  });


}


Future<void> captureScreenshot() async {
  // Placeholder for screenshot capture logic
  // This is a complex feature and may require additional libraries or services
  print('Capture screenshot logic needs to be implemented.');
}

void showReportInput() {
  final overlay = DivElement()
    ..id = 'reportOverlay'
    ..classes.add('overlay');

  final titleInput = InputElement()
    ..placeholder = 'Title'
    ..id = 'titleInput';

  final descriptionInput = TextAreaElement()
    ..placeholder = 'Description'
    ..id = 'descriptionInput';

  final submitButton = ButtonElement()
    ..text = 'Submit'
    ..id = 'submitButton'
    ..classes.add('custom-button');

  submitButton.onClick.listen((event) {
    final title = (document.getElementById('titleInput') as InputElement).value ?? '';
    final description = (document.getElementById('descriptionInput') as TextAreaElement).value ?? '';
    print('Title: $title');
    print('Description: $description');
    overlay.remove();

    // Create task in Asana
    createTask(title, description);
  });

  overlay.append(titleInput);
  overlay.append(descriptionInput);
  overlay.append(submitButton);

  document.body!.append(overlay);
}

Future<void> createTask(String title, String description) async {
  final token = window.localStorage['asana_token'];
  final url = 'https://app.asana.com/api/1.0/tasks';
  final data = {
    'data': {
      'projects': 'stored_project_id', // Replace with selected project ID
      'name': title,
      'notes': '$description\n\nScreenshot: [Link to Screenshot](https://example.com/screenshot.png)',
      'assignee': 'muhsin@planetmedia.in',
    },
  };

  final response = await HttpRequest.request(
    url,
    method: 'POST',
    sendData: jsonEncode(data),
    requestHeaders: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  final responseJson = jsonDecode(response.responseText!);
  print('Task created: $responseJson');
}
