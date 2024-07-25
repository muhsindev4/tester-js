import 'dart:async';
import 'dart:html';

void main() {
  // Inject the CSS link into the head of the document
  final link = LinkElement()
    ..rel = 'stylesheet'
    ..href = 'style.css';
  document.head!.append(link);

  final body = document.body!;

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

  bool isDrawing = false;
  final canvas = CanvasElement(width: window.innerWidth, height: window.innerHeight)
    ..id = 'drawingCanvas';

  final context = canvas.context2D;
  body.append(canvas);

  body.append(drawButton);
  body.append(completeButton);
  body.append(reportButton);

  void startDrawing() {
    canvas.style.pointerEvents = 'auto';
    body.style.cursor = 'crosshair';
  }

  void stopDrawing() {
    canvas.style.pointerEvents = 'none';
    body.style.cursor = 'default';
  }

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
  final script = ScriptElement()
    ..text = '''
      html2canvas(document.body).then(function(canvas) {
        var dataUrl = canvas.toDataURL('image/png');
        var link = document.createElement('a');
        link.href = dataUrl;
        link.setAttribute('download', 'screenshot.png');
        link.click();
      });
    ''';

  document.body!.append(script);
  script.remove();
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
  });

  overlay.append(titleInput);
  overlay.append(descriptionInput);
  overlay.append(submitButton);

  document.body!.append(overlay);
}
