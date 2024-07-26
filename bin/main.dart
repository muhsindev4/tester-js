import 'dart:async';
import 'dart:html';
import 'dart:math';

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
  final bootstrap = LinkElement()
    ..rel = 'stylesheet'
    ..href = 'https://cdn.jsdelivr.net/npm/bootstrap-icons/font/bootstrap-icons.css';
  document.head!.append(bootstrap);
  document.head!.append(link);

  // Create the feedback button
  ButtonElement feedbackButton = ButtonElement()
    ..id = 'feedbackButton'
    ..innerHtml = '<i class="bi bi-chat-right-dots-fill"></i>';

  // Add event listener to show the popup on click
  feedbackButton.onClick.listen((event) {
    showPopup();
  });

  // Add the button to the document body
  document.body!.append(feedbackButton);

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
    hidePopup();
  });

  // Add event listener for report bug
  querySelector('#reportBug')!.onClick.listen((event) {
    CanvasController().showCanvas();
    hidePopup();
  });
}

void showPopup() {
  querySelector('#feedbackPopup')!.style.display = 'block';
}

void hidePopup() {
  querySelector('#feedbackPopup')!.style.display = 'none';
}




class Shape {
  String type;
  Point start;
  Point end;

  Shape(this.type, this.start, this.end);
}

class CanvasController {
  CanvasElement? canvas;
  CanvasRenderingContext2D? context;
  DivElement? toolbar;
  DivElement? reportPopup;
  List<Shape> shapes = [];
  List<DivElement> screenshots = [];
  int circleCount = 0;
  bool isDrawing = false;
  String currentTool = '';
  Point? startPoint;

  void showCanvas() {
    canvas = CanvasElement(width: window.innerWidth, height: window.innerHeight)
      ..id = 'feedbackCanvas'
      ..style.position = 'absolute'
      ..style.top = '0'
      ..style.left = '0'
      ..style.zIndex = '9998';

    context = canvas!.context2D;

    document.body!.append(canvas!);

    toolbar = DivElement()
      ..id = 'canvasToolbar'
      ..innerHtml = '''
      <button id="drawRect"><i class="bi bi-square"></i></button>
      <button id="drawArrow"><i class="bi bi-arrow-right"></i></button>
      <button id="pinButton"><i class="bi bi-crosshair"></i></button>
      <button id="reportButton"><i class="bi bi-file-earmark-text"></i> Report</button>
    '''
      ..style.position = 'fixed'
      ..style.top = '10px'
      ..style.left = '50%'
      ..style.transform = 'translateX(-50%)'
      ..style.backgroundColor = 'white'
      ..style.padding = '10px'
      ..style.borderRadius = '5px'
      ..style.boxShadow = '0px 0px 10px rgba(0, 0, 0, 0.1)'
      ..style.zIndex = '9999';

    document.body!.append(toolbar!);

    querySelector('#drawRect')!.onClick.listen((event) {
      currentTool = 'rect';
      event.stopPropagation();
    });

    querySelector('#drawArrow')!.onClick.listen((event) {
      currentTool = 'arrow';
      event.stopPropagation();
    });

    querySelector('#pinButton')!.onClick.listen((event) {
      currentTool = 'pin';
    });

    querySelector('#reportButton')!.onClick.listen((event) {
      _showReportPopup();
    });

    canvas!.onMouseDown.listen((MouseEvent event) {
      if (currentTool == 'rect' || currentTool == 'arrow') {
        isDrawing = true;
        startPoint = event.offset;
      }
    });

    canvas!.onMouseMove.listen((MouseEvent event) {
      if (isDrawing && startPoint != null) {
        _drawShapes(
            includeNewShape: false); // Don't include new shape while dragging
        _drawShape(event.offset); // Draw new shape
      }
    });

    canvas!.onMouseUp.listen((MouseEvent event) {
      if (isDrawing && startPoint != null) {
        shapes.add(Shape(currentTool, startPoint!, event.offset));
        isDrawing = false;
        startPoint = null;
        _drawShapes(); // Redraw all shapes
      }
    });

    canvas!.onClick.listen((MouseEvent event) {
      if (currentTool == 'pin') {
        event.stopPropagation();
        handleCanvasClick(event);
      }
    });
  }

  void _drawShape(Point endPoint) {
    if (context == null || startPoint == null) return;

    if (currentTool == 'rect') {
      _drawRect(startPoint!, endPoint);
    } else if (currentTool == 'arrow') {
      _drawArrow(startPoint!, endPoint);
    }
  }

  void _drawRect(Point start, Point end) {
    context!.beginPath();
    context!.rect(start.x, start.y, end.x - start.x, end.y - start.y);
    context!.strokeStyle = 'rgba(98, 0, 234, 0.7)';
    context!.lineWidth = 2;
    context!.stroke();
    context!.closePath();
  }

  void _drawArrow(Point start, Point end) {
    context!.beginPath();
    context!.moveTo(start.x, start.y);
    context!.lineTo(end.x, end.y);

    // Draw arrowhead
    double arrowSize = 10;
    double angle = atan2(end.y - start.y, end.x - start.x);
    context!.lineTo(
        end.x - arrowSize * cos(angle - pi / 6),
        end.y - arrowSize * sin(angle - pi / 6));
    context!.moveTo(end.x, end.y);
    context!.lineTo(
        end.x - arrowSize * cos(angle + pi / 6),
        end.y - arrowSize * sin(angle + pi / 6));

    context!.strokeStyle = 'rgba(98, 0, 234, 0.7)';
    context!.lineWidth = 2;
    context!.stroke();
    context!.closePath();
  }

  void _drawShapes({bool includeNewShape = true}) {
    if (context == null) return;

    context!.clearRect(0, 0, canvas!.width!, canvas!.height!);

    for (var shape in shapes) {
      if (shape.type == 'rect') {
        _drawRect(shape.start, shape.end);
      } else if (shape.type == 'arrow') {
        _drawArrow(shape.start, shape.end);
      }
    }

    if (includeNewShape && startPoint != null) {
      _drawShape(startPoint!);
    }
  }

  void handleCanvasClick(MouseEvent event) {
    circleCount++;

    DivElement handleDiv = DivElement();
    DivElement circleDiv = DivElement()
      ..className = 'circleDiv'
      ..style.position = 'absolute'
      ..style.left = '${event.client.x - 10}px'
      ..style.top = '${event.client.y - 10}px'
      ..style.width = '20px'
      ..style.height = '20px'
      ..style.borderRadius = '50%'
      ..style.backgroundColor = 'rgba(98, 0, 234, 0.7)'
      ..style.display = 'flex'
      ..style.alignItems = 'center'
      ..style.justifyContent = 'center'
      ..style.zIndex = '10000';

    SpanElement countText = SpanElement()
      ..text = circleCount.toString()
      ..style.color = 'white'
      ..style.fontSize = '14px'
      ..style.fontFamily = 'Arial'
      ..style.fontWeight = 'bold';

    DivElement inputContainer = DivElement()
      ..className = 'inputContainer'
      ..style.position = 'absolute'
      ..style.left = '${event.client.x + 15}px'
      ..style.top = '${event.client.y - 10}px'
      ..style.zIndex = '10001'
      ..style.display = 'flex'
      ..style.alignItems = 'center'
      ..style.gap = '5px';

    TextAreaElement input = TextAreaElement()
      ..placeholder = 'Enter feedback...'
      ..style.padding = '5px'
      ..style.borderRadius = '5px'
      ..style.border = '1px solid #6200ea'
      ..style.resize = 'none'
      ..style.width = '200px'
      ..style.minHeight = '60px'
      ..style.overflow = 'hidden';

    ButtonElement inputRemoveButton = ButtonElement()
      ..innerHtml = '<i class="bi bi-x-circle-fill"></i>'
      ..style.background = 'none'
      ..style.border = 'none'
      ..style.cursor = 'pointer'
      ..style.color = '#6200ea';

    inputRemoveButton.onClick.listen((event) {
      circleCount--;
      handleDiv.remove();
    });

    input.onInput.listen((_) {
      input.style.height = 'auto';
      input.style.height = '${input.scrollHeight}px';
    });

    circleDiv.append(countText);
    inputContainer.append(input);
    inputContainer.append(inputRemoveButton);

    handleDiv.append(circleDiv);
    handleDiv.append(inputContainer);
    document.body!.append(handleDiv);
  }

  void _showReportPopup() {
    if (reportPopup != null) {
      reportPopup!.remove();
    }

    reportPopup = DivElement()
      ..id = 'reportPopup'
      ..style.position = 'fixed'
      ..style.top = '50%'
      ..style.left = '50%'
      ..style.transform = 'translate(-50%, -50%)'
      ..style.backgroundColor = 'white'
      ..style.padding = '20px'
      ..style.borderRadius = '10px'
      ..style.boxShadow = '0px 0px 15px rgba(0, 0, 0, 0.3)'
      ..style.zIndex = '10000';

    reportPopup!.innerHtml = '''
      <h3>Report Issue</h3>
      <div>
        <label>Title:</label>
        <input type="text" id="reportTitle" style="width: 100%; padding: 10px; margin-bottom: 10px; border-radius: 5px; border: 1px solid #ddd;">
      </div>
      <div>
        <label>Description:</label>
        <textarea id="reportDescription" style="width: 100%; padding: 10px; margin-bottom: 10px; border-radius: 5px; border: 1px solid #ddd;"></textarea>
      </div>
      <button id="addScreenshotButton" style="display: block; width: 100%; padding: 10px; margin-bottom: 10px; border-radius: 5px; border: 1px solid #6200ea; background-color: #6200ea; color: white; cursor: pointer;">Add Screenshot</button>
      <div id="screenshotList" style="margin-bottom: 10px; display: flex; overflow-x: auto;"></div>
      <button id="reportSubmitButton" style="display: block; width: 100%; padding: 10px; border-radius: 5px; border: 1px solid #6200ea; background-color: #6200ea; color: white; cursor: pointer;">Submit Report</button>
      <button id="closePopupButton" style="display: block; width: 100%; padding: 10px; margin-top: 10px; border-radius: 5px; border: 1px solid #ddd; background-color: #f5f5f5; color: #6200ea; cursor: pointer;">Close</button>
    ''';

    document.body!.append(reportPopup!);

    querySelector('#addScreenshotButton')!.onClick.listen((event) {
      _hideReportPopup();
      _startSelection();
    });

    querySelector('#reportSubmitButton')!.onClick.listen((event) {
      _hideReportPopup();
      // Handle report submission
    });

    querySelector('#closePopupButton')!.onClick.listen((event) {
      _hideReportPopup();
    });
  }

  void _hideReportPopup() {
    reportPopup?.remove();
  }

  void _startSelection() {
    DivElement selectionOverlay = DivElement()
      ..style.position = 'fixed'
      ..style.top = '0'
      ..style.left = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = 'rgba(0, 0, 0, 0.5)'
      ..style.zIndex = '10001';

    document.body!.append(selectionOverlay);

    selectionOverlay.onMouseDown.listen((MouseEvent event) {
     
    });

    selectionOverlay.onMouseMove.listen((MouseEvent event) {
      
    });

    selectionOverlay.onMouseUp.listen((MouseEvent event) {
    _takeScreenshot(start, end)
    });
  }

  void _drawSelectionArea(Point start, Point end) {
    // Remove any existing overlay canvas to avoid drawing multiple canvases
    CanvasElement? existingOverlayCanvas = document.querySelector(
        '#selectionCanvas') as CanvasElement?;
    existingOverlayCanvas?.remove();

    CanvasElement overlayCanvas = CanvasElement(
        width: window.innerWidth,
        height: window.innerHeight
    )
      ..id = 'selectionCanvas'
      ..style.position = 'fixed'
      ..style.top = '0'
      ..style.left = '0'
      ..style.zIndex = '10002';

    document.body!.append(overlayCanvas);

    CanvasRenderingContext2D overlayContext = overlayCanvas.context2D;
    overlayContext.clearRect(0, 0, overlayCanvas.width!, overlayCanvas.height!);

    overlayContext.beginPath();
    overlayContext.rect(start.x, start.y, end.x - start.x, end.y - start.y);
    overlayContext.strokeStyle = 'rgba(0, 0, 0, 0.8)';
    overlayContext.lineWidth = 2;
    overlayContext.stroke();
    overlayContext.closePath();
  }

  void _takeScreenshot(Point start, Point end) {
    // Calculate the selection area bounds
    int x = min(start.x, end.x).toInt();
    int y = min(start.y, end.y).toInt();
    int width = (end.x - start.x).abs().toInt();
    int height = (end.y - start.y).abs().toInt();

    CanvasElement screenshotCanvas = CanvasElement(
        width: width,
        height: height
    );
    CanvasRenderingContext2D screenshotContext = screenshotCanvas.context2D;

    screenshotContext.drawImageScaledFromSource(
        canvas!,
        x,
        y,
        width,
        height,
        0,
        0,
        width,
        height
    );

    String screenshotUrl = screenshotCanvas.toDataUrl();

    ImageElement screenshotImage = ImageElement(src: screenshotUrl)
      ..style.width = '150px'
      ..style.height = 'auto'
      ..style.marginRight = '10px';

    DivElement screenshotDiv = DivElement()
      ..className = 'screenshotDiv'
      ..style.display = 'inline-block'
      ..style.marginRight = '10px';

    screenshotDiv.append(screenshotImage);
    reportPopup!.querySelector('#screenshotList')!.append(screenshotDiv);

    screenshots.add(screenshotDiv);
    _showReportPopup();
  }
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