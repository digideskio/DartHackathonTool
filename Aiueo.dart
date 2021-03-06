#import('dart:html');
#import('dart:dom', prefix:"dom");

class Camera {
  
  var localVideo;
  var localCanvas;
  var ctx2;
  var prevImg = null;
  final int threshold = 3200000;
  
  void run() {
    localVideo = document.query("#selfView");
    localCanvas = document.query("#localCanvas");
    ctx2 = localCanvas.getContext('2d');
    startCamera();
    
  }
  
  var flg = false;
  void bossIsHere() {
    if (flg === false) {
      document.query("#cover").style.visibility = "visible";
      flg = true;
    }
  }
  
  void startCamera() {
    try {
      window.navigator.webkitGetUserMedia("video user", gotStream);
      
      // Detect MediaStream disabled.
      window.setTimeout(detectMediaStreamDisabled, 2 * 1000);
      
    } catch (var e) {
      print(e);
    }
  }
  
  bool started = false;
  
  void gotStream(var stream) {
    started = true;
    localVideo.src = new dom.DOMURL().createObjectURL(stream);
    startCanvasCopy();
  }

  void detectMediaStreamDisabled() {
    if (started) {
      return ;
    }
    
    document.query("#error").style.visibility = "visible";
  }

  void startCanvasCopy() {
    canvasCopy(100);
  }
  
  bool canvasCopy(num highResTime) {
    renderCanvas();
    window.requestAnimationFrame(canvasCopy);
  }
  
  int checkDiff(var prev, var img) {
    var pix = img.data;
    var prevPix = prev.data;
    int result = 0;
    for (var i = 0, n = pix.length; i < n; i += 4) {
      int diffR = pix[i] - prevPix[i];
      int diffG = pix[i] - prevPix[i + 1];
      int diffB = pix[i] - prevPix[i + 2];
      result += diffR.abs() + diffG.abs() + diffB.abs();
    }
    return result;
  }

  void binaryImage(var img) {
    var pix = img.data;
    for (var i = 0, n = pix.length; i < n; i += 4) {
      int color = (pix[i  ] + pix[i+1] + pix[i+2]) / 3;
      color = (color > 100) ? 255 : 0;
      pix[i  ] = color; // red
      pix[i+1] = color; // green
      pix[i+2] = color; // blue
      // i+3 is alpha (the fourth element)
    }
  }
  
  var prevDiff = 0;
  
  void renderCanvas() {
    ctx2.drawImage(localVideo, 0, 0, 200, 200);
    var imgd = ctx2.getImageData(0, 0, localCanvas.width, localCanvas.height);
    binaryImage(imgd);
    if (prevImg !== null) {
      int diff = checkDiff(prevImg, imgd);
      if (prevDiff > 0 && diff > threshold) {
        document.query('#status').innerHTML = "Boss is detected！" + diff;
        bossIsHere();
      } else {
        prevDiff = diff;
      }
      print("diff = " + diff);
    }
    prevImg = imgd;
    ctx2.putImageData(imgd, 0, 0);
  }
}

void main() {
  new Camera().run();
}
