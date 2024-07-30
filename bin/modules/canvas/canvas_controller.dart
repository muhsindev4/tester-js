import 'dart:html';
import 'dart:math';
import 'models/shape.dart';
import 'widget/tool_bar.dart';



class CanvasController {
  CanvasElement? canvas;
  CanvasRenderingContext2D? context;

  DivElement? reportPopup;
  List<Shape> shapes = [];
  List<DivElement> screenshots = [];
  int circleCount = 0;
  List<Map<String, dynamic>> commentsList = [];
  bool isDrawing = false;
  Point? startPoint;

  ToolBar _toolBar=ToolBar();
  String get currentTool =>_toolBar.currentTool;


  void showCanvas() {
    canvas = CanvasElement(width: window.innerWidth, height:document.documentElement!.scrollHeight)
      ..id = 'feedbackCanvas'
      ..style.position = 'absolute'
      ..style.top = '0'
      ..style.left = '0'
      ..style.zIndex = '9998';

    context = canvas!.context2D;

    document.body!.append(canvas!);

    _toolBar.createToolBar();


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

    // Use pageX and pageY to account for scrolling
    final clickX = event.page.x;
    final clickY = event.page.y;

    DivElement handleDiv = DivElement();
    DivElement circleDiv = DivElement()
      ..className = 'circleDiv'
      ..style.position = 'absolute'
      ..style.left = '${clickX - 10}px'
      ..style.top = '${clickY - 10}px'
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
      ..style.left = '${clickX + 15}px'
      ..style.top = '${clickY - 10}px'
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
      ..id = "inputRemoveButton"
      ..innerHtml = '<i class="bi bi-x-circle-fill"></i>'
      ..style.background = 'none'
      ..style.border = 'none'
      ..style.cursor = 'pointer'
      ..style.color = '#6200ea';

    // Create a map to store the comment and its count
    Map<String, dynamic> commentMap = {
      "comment": "",
      "count": circleCount
    };

    commentsList.add(commentMap);
    _toolBar.commentsList.add(commentMap);

    input.onInput.listen((_) {
      input.style.height = 'auto';
      input.style.height = '${input.scrollHeight}px';

      // Update the comment in the list
      commentMap["comment"] = input.value!;
    });

    inputRemoveButton.onClick.listen((event) {
      circleCount--;
      handleDiv.remove();
      commentsList.remove(commentMap);
      _toolBar.commentsList.remove(commentMap);
    });

    circleDiv.append(countText);
    inputContainer.append(input);
    inputContainer.append(inputRemoveButton);

    handleDiv.append(circleDiv);
    handleDiv.append(inputContainer);
    document.body!.append(handleDiv);
  }





}