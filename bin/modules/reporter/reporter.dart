import 'dart:convert';
import 'dart:html';
import '../asana/task_controller.dart';
import '../../modules/screenshot/screenshot_controller.dart';

class Reporter {
  DivElement? reportPopup;
  List<Map<String, dynamic>> _commentsList = [];
  List<ImageElement> _screenshots = []; // Store the screenshots here

  void showReportPopup(List<Map<String, dynamic>> commentsList) {
    _hideCommentBoxes();
    _commentsList = commentsList;
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

      // Define the styles programmatically
      StyleElement styles = StyleElement()
        ..innerHtml = '''
          #reportPopup {
              max-width: 400px;
              width: 100%;
          }
          #reportPopup h3 {
              margin-top: 0;
          }
          #reportPopup input, #reportPopup textarea {
              width: 100%;
              padding: 10px;
              margin-bottom: 10px;
              border-radius: 5px;
              border: 1px solid #ddd;
          }
          #reportPopup button {
              display: block;
              width: 100%;
              padding: 10px;
              margin-bottom: 10px;
              border-radius: 5px;
              border: 1px solid #6200ea;
              background-color: #6200ea;
              color: white;
              cursor: pointer;
          }
          #reportPopup button:last-of-type {
              margin-top: 10px;
              border: 1px solid #ddd;
              background-color: #f5f5f5;
              color: #6200ea;
          }
          #screenshotList {
              margin-bottom: 10px;
              display: flex;
              overflow-x: auto; /* Enable horizontal scrolling */
              gap: 10px; /* Add space between screenshots */
          }
          #screenshotList img {
              max-height: 100px; /* Adjust height as needed */
              border: 1px solid #ddd;
              border-radius: 5px;
          }
          #commentSection {
              margin-top: 20px;
              max-height: 200px; /* Adjust height as needed */
              overflow-y: auto; /* Enable vertical scrollbar */
          }
          #commentSection h4 {
              margin-top: 0;
          }
          .comment {
              display: flex;
              align-items: center;
              margin-bottom: 10px;
          }
          .comment .commentCounter {
              width: 30px;
              height: 30px;
              border-radius: 50%;
              background-color: #6200ea;
              color: white;
              display: flex;
              align-items: center;
              justify-content: center;
              margin-right: 10px;
          }
          .comment .commentText {
              flex: 1;
          }
        ''';

      document.head!.append(styles);
      document.body!.append(reportPopup!);

      // Add comments to the comment section
      if (_commentsList.isEmpty) {
        querySelector("#commentSection")!.style.visibility = "hidden";
      }
      DivElement commentSection = querySelector('#commentSection') as DivElement;
      for (var comment in _commentsList) {
        commentSection.append(_createCommentElement(comment['comment'], comment['count']));
      }

      querySelector('#addScreenshotButton')!.onClick.listen((event) {
        _hideReportPopup();
        _hideCommentBoxes();
        _hideToolBar();

        CanvasElement canvas = querySelector('#feedbackCanvas') as CanvasElement;

        // Create a ScreenshotController instance with a callback
        ScreenshotController screenshotController = ScreenshotController(canvas, onScreenshotTaken: (imageUrl) {
          ImageElement img = ImageElement(src: imageUrl);
          img.style.maxHeight = '100px'; // Set image height
          img.style.marginRight = '10px'; // Add space between images
          DivElement screenshotList = querySelector('#screenshotList') as DivElement;
          screenshotList.append(img); // Add the new screenshot to the list
          _screenshots.add(img); // Store the screenshot
          print(imageUrl);
          _lazyShowPopup();
        });
        screenshotController.startSelection();
      });

      querySelector('#reportSubmitButton')!.onClick.listen((event) async {
        final String title = (querySelector('#reportTitle') as InputElement).value!;
         String description = (querySelector('#reportDescription') as TextAreaElement).value!;






        _closeReporter();
       final res=await TaskController().createTask(title: title, notes: description,);
       if(res is bool){
         //show a error message
       }else{
         String taskId=res['data']['gid'];
         List<String>imageUrls=[];
         String htmlNote="";
         print("sad=${taskId}");
         for( ImageElement screenshot in _screenshots){
           final String base64Data = screenshot.src!.split(',').last;
           final uploadImage=await TaskController().addAttachmentToTask(taskId: taskId, base64Image:base64Data,);
           imageUrls.add(uploadImage['data']['gid']);
         }


         htmlNote=htmlNote+"""
         <body>
          <h1>Task Description</h1>
        <strong>Web URL Path:</strong> <a href='${window.location.href}' target="_blank">${window.location.href}</a>
         """;

         htmlNote=htmlNote+"""
          <h2>Attached screenshot with marked points:</h2>
             <ol>
         """;
         for (var comment in _commentsList) {
           htmlNote=htmlNote+"""
                <li>${comment['count']} : ${comment['comment']} </li>
         """;
         }

         // String imageHtml="";
         // for (var image in imageUrls) {
         //   imageHtml=imageHtml+"""
         //        <img src="https://app.asana.com/app/asana/-/get_asset?asset_id=$image" alt="screenshot" data-asana-gid="$image" data-src-width="800" data-src-height="600">
         // """;
         // }
         //
         // htmlNote=htmlNote+imageHtml;

         htmlNote=htmlNote+"""
                </ol>
                 </body>
         """;



         final updateTask=await TaskController().updateTaskHtmlNotes(taskId: taskId, htmlNotes: htmlNote);
       }
        // Handle report submission
      });

      querySelector('#closePopupButton')!.onClick.listen((event) {
        _closeReporter();
        _showToolBar();
        _showCommentBoxes();
      });
    });
  }

  DivElement _createCommentElement(String commentText, int count) {
    DivElement commentElement = DivElement()..className = 'comment';
    DivElement commentCounter = DivElement()
      ..className = 'commentCounter'
      ..text = '$count';
    DivElement commentTextElement = DivElement()
      ..className = 'commentText'
      ..text = commentText;

    commentElement.append(commentCounter);
    commentElement.append(commentTextElement);

    return commentElement;
  }

  void _closeReporter() {
    reportPopup!.remove();
  }

  void _hideReportPopup() {
    querySelector("#reportPopup")!.style.visibility = "hidden";
  }

  void _lazyShowPopup() {
    querySelector("#reportPopup")!.style.visibility = "visible";
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
