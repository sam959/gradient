import processing.video.*;
import controlP5.*;
import java.util.List;

int numPixels;
int[] backgroundPixels;
int[] shiftedColors;
int[] shiftBackColors;
int[] prevPixels;
List buffers;
float[] gradients;
float gradient;
boolean displacementOn;
float coordX;
boolean isVideoPlaying;
ControlP5 cp5;
float shiftGradient;
float displacement;
int currR;
int currB;
int currG;
int backR;
int backG;
int backB;
float diffR;
float diffG;
float diffB;
int photoprevI;
float lfo;
float funLfo;
float funDisplacement;
int acc;
int endOfColumn;
int prevIndex;

int pixel;
int pixPerColumn;
int numberOfPixelsInCol;

color originalColor;
color backColor; 
color previousColor;
color buffCol;

Movie video;

int shiftR;
int shiftG;

boolean shiftPrevious;
boolean shouldPrint;

float lfoFreq;
float lfoAmplitude;

void setup() {
    size(640, 480); 
    colorMode(HSB);
    frameRate(30);
    cp5 = new ControlP5(this);
    initVideo("makeamove.mp4");
    shiftedColors = new int[3];
    shiftBackColors = new int[3];
    shiftPrevious = false;
    buffers = new ArrayList<Integer>(10);
    acc = 0;
    prevIndex = 0;
    endOfColumn = 0;
    shiftGradient = 0.0;
    displacement = 0;
    previousColor = 0;
    currR = 0;
    currB = 0;
    currG = 0;
    funLfo = 0.0;
    funDisplacement = 0.0;
    isVideoPlaying = false;
    coordX = 0.0;
    displacementOn = true;
    shouldPrint = true;
    shiftR = 16;
    shiftG = 8;
    lfoFreq= 0.0;
    lfoAmplitude = 0.0;
    photoprevI = 0;
    lfo = 0.0;
    numberOfPixelsInCol = 0;
  
    setupOptions();
    loadPixels();
}

void draw() {
    //image(video, 0,0, width, height);
    loadPixels(); 
    PImage buffer = new PImage(width, height);
    buffer.loadPixels();

    if(isVideoPlaying && frameCount > 0){
    /*
      if(video.pixels != null){
        arrayCopy(video.pixels, prevPixels);
      }
      */

      lfo =  sin(millis()* lfoFreq) * lfoAmplitude;
      funLfo = tan(lfo);

      // ______________ FOR EVERY PIXEL PER FRAME... ______________ //
      for (int i = 0; i < numPixels; i++) { 
        prevIndex = i == 0? 0 : i - 1;

        coordX =  ((float)(i%width) + 1) / (float) width;
        gradients[i] = coordX * shiftGradient; 

      /*
        // If 0, a column has passed
        endOfColumn = i%height;
        if(endOfColumn == 0){
          acc++;
          // 4 columns of pixels have passed
          if(acc == height * 4){
              acc = 0;
              fill(255,200,200);
              rect(0, height, 100, 100);
              print("Freached 4th line\n");

          }
        }
      
        if((frameCount == 2 || frameCount == 3) && shouldPrint){
          print("Number of pixels in column per frame : " + acc + "\n");
          pixPerColumn = 0;
          if(frameCount == 3){
            shouldPrint = false;
          }
        }
        //print("endOfColumn: " + acc + "\n");
        */
  
        // ---- Color stuff ----- //

        originalColor = video.pixels[i];
        buffer.pixels[i] = 0xFF000000 | (video.pixels[i] << 16) | (video.pixels[i] << 8) | video.pixels[i];

        //buffer.pixels[i] = originalColor;
        buffer.updatePixels();
       
        if(displacementOn){
          //gradient = i%map(mouseX, 0, video.width, 0, 1000);
          if(displacement == 0){
            gradient = 0;
          } else {
          funDisplacement = i%(displacement + lfo);
            gradient = funDisplacement;
          }
        } else {
          //print(String.format("Grandients: %f\n",gradients[i]));
          gradient = gradients[i];
        }

        if(shiftPrevious){
    
        /*
          int[] prevRGB = bitShift(prevPixels[i], 16, 8);
          
          diffR = abs(prevRGB[0] - gradient);
          diffG = abs(prevRGB[1] + gradient);
          diffB = abs(prevRGB[2] - gradient);
          */

          //blend(src, sx, sy, sw, sh, dx, dy, dw, dh, mode)
          //copy(src, sx, sy, sw, sh, dx, dy, dw, dh)
          PImage p = (PImage)buffers.get((int) random(10));
          p.loadPixels();
          buffCol = p.pixels[prevIndex];

          int[]buffCols = bitShift(buffCol, 16, 8);
          diffR = abs(buffCols[0] + gradient);
          diffG = abs(buffCols[1] - gradient);
          diffB = abs(buffCols[2] + gradient);
          pixels[i] = color(diffR, diffG, diffB);

        } else {

          shiftedColors = bitShift(originalColor, shiftR, shiftG);
          diffR = abs(shiftedColors[0] - gradient);
          diffG = abs(shiftedColors[1] + gradient);
          diffB = abs(shiftedColors[2] - gradient);
          pixels[i] = color(diffR, diffG, diffB);
        }
        //pixels[i] = color(prevR, prevG, prevB);
        // The following line does the same thing much faster, but is more technical
        //pixels[i] = 0xFF000000 | (diffR << 16) | (diffG << 8) | diffB;
      }
      buffers.add(buffer);
        if(buffers.size() > 10){
          buffers.remove(0);
        }
      updatePixels(); // Notify that the pixels[] array has changed
    }
    fill(100, 180, 200);
    text("funDisplacement: " + funDisplacement, 10, 220);
    text("Buff: " + buffCol, 10, 240);
    text("pixel: " + originalColor, 10, 260);

}
// ---------------- PIXELS -----------------//

int[] bitShift(color originalColor, int shiftR, int shiftG){
  int r = (originalColor >> shiftR) & 0xFF;
  int g = (originalColor >> shiftG) & 0xFF;
  int b = originalColor & 0xFF;

  return new int[]{r, g, b};
}

// ---------------- EVENTS -----------------//

void keyPressed() {
  if(key == 'n'){
    displacementOn = !displacementOn;
    if(!displacementOn){
      displacement = 0;

      video.loadPixels();
      arrayCopy(video.pixels, backgroundPixels);
    } else {
      shiftGradient = 0.0;
    }
    print(String.format("DisplacementOn[%b]. Value: %f\n",  displacementOn, displacement));
  } else if(key == 's'){
    print("Saved!\n");
    saveFrame(String.format("/Users/samanthalovisolo/Documents/projects/stills/gradient-%d -####.jpg",photoprevI));
    photoprevI ++;
  } else if(key == 'p'){
    if(cp5.getController("shiftGradient") == null){
      addSlider("shiftGradient", 220, 20, 255.0);
    }
    if(shiftGradient > 0){
      shiftGradient = 0;
    }
  } else if (key == CODED) {
    if (keyCode == UP) {
      shiftR++;
    }
    if (keyCode == DOWN) {
      shiftR--;
    }
    if (keyCode == RIGHT) {
      shiftG++;
    }
    if (keyCode == LEFT) {
      shiftG--;
    }
  } else if(key == 32){
    if(isVideoPlaying){
      video.pause();
      isVideoPlaying = false;
      print("Video paused"+ "\n");
    } else {
      video.play();
      isVideoPlaying = true;
      print("Video replaying\n\n");
    }
  }
}

// ---------------- VIDEO -----------------//

void movieEvent(Movie video){
  if(video.available()){
    video.read();
    video.loadPixels();
    isVideoPlaying = true;
  } else {
    print("Video not available\n");  
  }
}

void initVideo(String path){
    video = new Movie(this,path);
    video.loop();
    video.volume(0);

    numPixels = video.width * video.height;
    gradients = new float[numPixels];
    backgroundPixels = new int[numPixels];
    prevPixels = new int[numPixels];

    addSlider("displacement", 220, 10, 1000.0);
      
    print(String.format("Video size: %d, pixels: %d\n", video.width, numPixels));
}

// ---------------- GUI -----------------//

void addSlider(String name, int posX, int posY, float max){
    cp5.addSlider(name)
       .setPosition(posX, posY)
       .setSize(150, 10)
       .setRange(0, max)
       .setValue(0.5)
       .setColorCaptionLabel(color(20,20,20));
}

void setupOptions(){
    ControlGroup backgroundGuiGroup = cp5.addGroup("LFO",0,10);
    backgroundGuiGroup.setMoveable(true);

    cp5.addButton("X")
    .setValue(1)
    .setPosition(width - 40, 10)
    .setColorBackground(color(255,150,150))
    .setSize(20, 19);   

    addSlider("lfoFreq", 0, 0, 0.002);
    addSlider("lfoAmplitude", 0, 15, 3.0);

    cp5.getController("lfoFreq").setGroup("LFO");
    cp5.getController("lfoAmplitude").setGroup("LFO");
}

void X(){
  if(frameCount > 0){
    shiftPrevious = !shiftPrevious;
  }
  print(String.format("shiftPrevious [%b] at frame [%d]\n", shiftPrevious, frameCount));
}
