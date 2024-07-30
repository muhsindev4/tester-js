import 'dart:async';
import 'dart:html';
import 'modules/canvas/canvas_controller.dart';
import 'utils/const.dart';
import 'modules/asana/auth_controller.dart';

Future<void> main() async {
  AuthController authController = AuthController(
      clientId: "1207894088371778",
      clientSecret: "de154df256c664c6d534198326431c49",
      redirectUri: "http://localhost:63342/plugin/index.html"
  );

  auth(authController);

  // Inject the CSS link into the head of the document
  final link = LinkElement()
    ..rel = 'stylesheet'
    ..href = 'style.css';
  final bootstrap = LinkElement()
    ..rel = 'stylesheet'
    ..href = 'https://cdn.jsdelivr.net/npm/bootstrap-icons/font/bootstrap-icons.css';
  document.head!.append(bootstrap);
  document.head!.append(link);

  // Create the feedback button
  ButtonElement feedbackButton = ButtonElement()
    ..id = 'feedbackButton'
    ..innerHtml = '<i class="bi bi-chat-right-dots-fill"></i>';

  // Create the auth button
  ButtonElement authButton = ButtonElement()
    ..id = 'authButton'
    ..innerHtml = '<img src="${Const.pluginAssets}/asana.png" alt="Asana Icon" />';

  // Add event listener to show the popup on click
  feedbackButton.onClick.listen((event) {
    _showPopup();
  });



  // Add the buttons to the document body
  document.body!.append(feedbackButton);
  document.body!.append(authButton);

  // Create the popup
  DivElement popup = DivElement()
    ..id = 'feedbackPopup'
    ..style.display = 'none' // Initially hidden
    ..innerHtml = '''
      <div id="popupContent">
        <button id="closePopup"><i class="bi bi-x-lg"></i></button>
        <h2>Feedback</h2>
        <ul>
          <li><a href="#" id="reportBug"><i class="bi bi-bug"></i> Report a bug</a></li>
          <li><a href="#" id="featureRequest"><i class="bi bi-lightbulb"></i> Feature request</a></li>
          <li><a href="#" id="generalFeedback"><i class="bi bi-chat-dots"></i> General feedback</a></li>
          <li><a href="#" id="contactUs"><i class="bi bi-envelope"></i> Contact us</a></li>
        </ul>
      </div>
    ''';

  // Add the popup to the document body
  document.body!.append(popup);

  // Add event listener to close the popup
  querySelector('#closePopup')!.onClick.listen((event) {
    _hidePopup();
  });

  // Add event listener for report bug
  querySelector('#reportBug')!.onClick.listen((event) {
    CanvasController().showCanvas();
    _hidePopup();
  });
}

void _showPopup() {
  querySelector('#feedbackPopup')!.style.display = 'block';
}

void _hidePopup() {
  querySelector('#feedbackPopup')!.style.display = 'none';
}

auth(AuthController authController) async {
  if (window.location.href.contains('code=')) {
    final uri = Uri.parse(window.location.href);
    final code = uri.queryParameters['code'];
    print("CODE:-  $code  ");
    if (code != null) {
      await authController.fetchToken(code);
      print("authController.accessToken!${authController.accessToken!}");
      // Store token
      window.localStorage['asana_token'] = authController.accessToken!;
      print("window.localStorage:-${window.localStorage['asana_token']}");
      // exchangeCodeForToken(code);
    }
  }
}
