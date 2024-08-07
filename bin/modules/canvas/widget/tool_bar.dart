import 'dart:html';
import '../../reporter/reporter.dart';

class ToolBar {
  String currentTool = "";
  final Reporter _reporter = Reporter();
  final List<Map<String, dynamic>> commentsList = [];

  void createToolBar() {
    DivElement toolbar = DivElement()
      ..id = 'canvasToolbar'
      ..innerHtml = '''
      <button id="drawRect"><i class="bi bi-square"></i></button>
      <button id="drawArrow"><i class="bi bi-arrow-right"></i></button>
      <button id="pinButton"><i class="bi bi-crosshair"></i></button>
      <button id="reportButton"><i class="bi bi-file-earmark-text"></i> Report</button>
      <button id="removeToolbar"><i class="bi bi-x"></i></button>
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

    document.body!.append(toolbar);

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
      currentTool = "showReportBox";
      _reporter.showReportPopup(commentsList);
    });

    querySelector('#removeToolbar')!.onClick.listen((event) {
      removeToolbarAndCanvas();
    });
  }

  void removeToolbarAndCanvas() {
    DivElement? toolbar = querySelector('#canvasToolbar') as DivElement?;
    CanvasElement? canvas = querySelector('#feedbackCanvas') as CanvasElement?;

    if (toolbar != null) {
      toolbar.remove();
    }

    if (canvas != null) {
      canvas.remove();
    }
  }
}
