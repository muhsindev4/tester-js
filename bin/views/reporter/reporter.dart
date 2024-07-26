import 'dart:html';
import '../../modules/screenshot/screenshot_controller.dart';


class Reporter {
  DivElement? reportPopup;

  void showReportPopup() {
    HttpRequest.getString('report_popup.html').then((html) {
      if (reportPopup != null) {
        reportPopup!.remove();
      }

      reportPopup = DivElement()
        ..id = 'reportPopup'
        ..innerHtml = html
        ..style.position = 'fixed'
        ..style.top = '50%'
        ..style.left = '50%'
        ..style.transform = 'translate(-50%, -50%)'
        ..style.backgroundColor = 'white'
        ..style.padding = '20px'
        ..style.borderRadius = '10px'
        ..style.boxShadow = '0px 0px 15px rgba(0, 0, 0, 0.3)'
        ..style.zIndex = '10000';

      document.body!.append(reportPopup!);

      querySelector('#addScreenshotButton')!.onClick.listen((event) {
        _hideReportPopup();
        _hideCommentBoxes();
        _hideToolBar();

        CanvasElement canvas = querySelector('#feedbackCanvas') as CanvasElement;

        // Create a ScreenshotController instance with a callback
        ScreenshotController screenshotController = ScreenshotController(canvas, onScreenshotTaken: (imageUrl) {
          ImageElement img = ImageElement(src: imageUrl);
          document.body!.append(img);
          print('Screenshot image data: $imageUrl');
          _showToolBar();
          _showCommentBoxes();
          showReportPopup();
        });
        screenshotController.startSelection();
      });

      querySelector('#reportSubmitButton')!.onClick.listen((event) {
        _hideReportPopup();
        // Handle report submission
      });

      querySelector('#closePopupButton')!.onClick.listen((event) {
        _hideReportPopup();
      });
    });
  }

  void _hideReportPopup() {
    reportPopup?.remove();
  }

  void _showToolBar() {
    querySelector("#canvasToolbar")!.style.visibility = "visible";
  }

  void _hideToolBar() {
    querySelector("#canvasToolbar")!.style.visibility = "hidden";
  }

  void _showCommentBoxes() {
    ElementList commentBoxes = querySelectorAll(".inputContainer");
    for (Element commentBox in commentBoxes) {
      commentBox.style.visibility = "visible";
    }
  }

  void _hideCommentBoxes() {
    ElementList commentBoxes = querySelectorAll(".inputContainer");
    for (Element commentBox in commentBoxes) {
      commentBox.style.visibility = "hidden";
    }
  }
}
