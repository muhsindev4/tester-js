import 'dart:html';
import 'dart:js' as js;
import 'dart:math';

class ScreenshotController {
  CanvasElement canvas;
  CanvasRenderingContext2D context;
  Point? start;
  Point? end;
  DivElement? selectionOverlay;
  CanvasElement? overlayCanvas;
  CanvasRenderingContext2D? overlayContext;
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
      ..style.zIndex = '10001'
      ..style.cursor = 'crosshair';

    overlayCanvas = CanvasElement()
      ..width = window.innerWidth
      ..height = window.innerHeight
      ..style.position = 'absolute'
      ..style.top = '0'
      ..style.left = '0';

    overlayContext = overlayCanvas!.context2D;
    selectionOverlay!.append(overlayCanvas!);
    document.body!.append(selectionOverlay!);

    selectionOverlay!.onMouseDown.listen((MouseEvent event) {
      start = Point(event.client.x + window.scrollX, event.client.y + window.scrollY);
      end = null;
    });

    selectionOverlay!.onMouseMove.listen((MouseEvent event) {
      if (start != null) {
        end = Point(event.client.x + window.scrollX, event.client.y + window.scrollY);
        _redrawOverlay();
        if (start != null && end != null) {
          _drawSelectionRectangle();
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

  void _redrawOverlay() {
    overlayContext!.clearRect(0, 0, overlayCanvas!.width!, overlayCanvas!.height!);
  }

  void _drawSelectionRectangle() {
    if (overlayContext != null && start != null && end != null) {
      final rectStartX = min(start!.x, end!.x) - window.scrollX;
      final rectStartY = min(start!.y, end!.y) - window.scrollY;
      final rectWidth = (end!.x - start!.x).abs();
      final rectHeight = (end!.y - start!.y).abs();

      overlayContext!.beginPath();
      overlayContext!.rect(rectStartX, rectStartY, rectWidth, rectHeight);
      overlayContext!.strokeStyle = 'rgba(255, 0, 0, 0.7)'; // Red for selection
      overlayContext!.lineWidth = 2;
      overlayContext!.stroke();
      overlayContext!.closePath();
    }
  }

  void _takeScreenshot(Point start, Point end) {
    final documentWidth = document.documentElement!.scrollWidth;
    final documentHeight = document.documentElement!.scrollHeight;

    js.context.callMethod('html2canvas', [document.body, js.JsObject.jsify({
      'width': documentWidth,
      'height': documentHeight,
      'onrendered': (canvas) {
        final fullImageUrl = canvas.toDataUrl('image/png');

        final cropCanvas = CanvasElement(
            width: (end.x - start.x).toInt(),
            height: (end.y - start.y).toInt()
        );
        final cropContext = cropCanvas.context2D;

        final image = ImageElement(src: fullImageUrl);
        image.onLoad.listen((_) {
          cropContext.drawImageScaledFromSource(
              image,
              start.x,
              start.y,
              end.x - start.x,
              end.y - start.y,
              0,
              0,
              (end.x - start.x).toInt(),
              (end.y - start.y).toInt()
          );

          final croppedImageUrl = cropCanvas.toDataUrl('image/png');

          if (onScreenshotTaken != null) {
            onScreenshotTaken!(croppedImageUrl);
          }

          final anchor = AnchorElement(href: croppedImageUrl)
            ..setAttribute('download', 'screenshot.png')
            ..dispatchEvent(Event('click'));

          _clearSelection();
        });
      }
    })]);
  }

  void _clearSelection() {
    _redrawOverlay();
    _removeSelectionOverlay();
  }
}
