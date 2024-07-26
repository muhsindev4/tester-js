import 'dart:html';
import 'dart:js' as js;

class ScreenshotController {
  CanvasElement canvas;
  CanvasRenderingContext2D context;
  Point? start;
  Point? end;
  DivElement? selectionOverlay;
  ImageData? backupImageData;
  Function(String)? onScreenshotTaken;

  ScreenshotController(this.canvas, {this.onScreenshotTaken}) : context = canvas.context2D;

  void startSelection() {
    // Save the current canvas content
    backupImageData = context.getImageData(0, 0, canvas.width!, canvas.height!);

    selectionOverlay = DivElement()
      ..style.position = 'fixed'
      ..style.top = '0'
      ..style.left = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = 'rgba(0, 0, 0, 0.5)'
      ..style.zIndex = '10001';

    document.body!.append(selectionOverlay!);

    selectionOverlay!.onMouseDown.listen((MouseEvent event) {
      start = Point(event.client.x, event.client.y);
    });

    selectionOverlay!.onMouseMove.listen((MouseEvent event) {
      if (start != null) {
        end = Point(event.client.x, event.client.y);
        _redrawCanvas(); // Redraw previously drawn shapes
        if (start != null && end != null) {
          // Draw the selection rectangle
          _drawSelectionRectangle(start!, end!);
        }
      }
    });

    selectionOverlay!.onMouseUp.listen((MouseEvent event) {
      if (start != null && end != null) {
        _clearSelection();
        _takeScreenshot(start!, end!);
      }
      _removeSelectionOverlay();
    });
  }

  void _removeSelectionOverlay() {
    selectionOverlay?.remove();
    selectionOverlay = null;
  }

  void _redrawCanvas() {
    if (backupImageData != null) {
      // Restore the canvas content
      context.putImageData(backupImageData!, 0, 0);
    }
  }

  void _drawSelectionRectangle(Point start, Point end) {
    context.beginPath();
    context.rect(start.x, start.y, end.x - start.x, end.y - start.y);
    context.strokeStyle = 'rgba(255, 0, 0, 0.7)'; // Red for selection
    context.lineWidth = 2;
    context.stroke();
    context.closePath();
  }

  void _takeScreenshot(Point start, Point end) {
    final width = end.x - start.x;
    final height = end.y - start.y;

    // Call JavaScript function html2canvas
    js.context.callMethod('html2canvas', [document.body, js.JsObject.jsify({
      'x': start.x,
      'y': start.y,
      'width': width,
      'height': height,
      'onrendered': (canvas) {
        final imageUrl = canvas.toDataUrl('image/png');

        // Call the callback function with the image data
        if (onScreenshotTaken != null) {
          onScreenshotTaken!(imageUrl);
        }

        // Optional: Log or handle the screenshot URL
        print('Screenshot taken and image URL is $imageUrl');

        // Clear the selection rectangle and the overlay
        _clearSelection();
      }
    })]);
  }

  void _clearSelection() {
    // Restore the canvas to its original state
    _redrawCanvas();

    // Remove the selection overlay
    _removeSelectionOverlay();
  }
}
