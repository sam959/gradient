import processing.video.*;
import controlP5.*;

int numPixels;
int[] backgroundPixels;
int[] shiftColors;
int[] shiftBackColors;

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
int photoIndex;
float lfo;

int prevPix;
int pixel;

color currColor;
color bkgdColor; 

Slider shiftGradientSlider;

Movie video;

int shiftR;
int shiftG;

float lfoFreq;
float lfoAmplitude;

void setup() {
    size(480, 480); 
    colorMode(HSB);
    frameRate(30);
    cp5 = new ControlP5(this);
    shiftColors = new int[3];
    shiftBackColors = new int[3];
    shiftGradient = 0.0;
    displacement = 0;
    prevPix = 0;
    currR = 0;
    currB = 0;
    currG = 0;
    isVideoPlaying = false;
    coordX = 0.0;
    displacementOn = true;
    shiftR = 16;
    shiftG = 8;
    lfoFreq= 0.0;
    lfoAmplitude = 0.0;
    photoIndex = 0;
    lfo = 0.0;
    initVideo("electrik.mp4");
    setupOptions();

}

void draw() {
    //image(video, 0,0, width, height);
    loadPixels();
    if(isVideoPlaying && video.width > 0){
      video.loadPixels(); // Make the pixels of video available
      // Difference between the current frame and the stored background
      lfo =  sin(millis()* lfoFreq) * lfoAmplitude;

      for (int i = 0; i < numPixels; i++) { 
        coordX =  ((float)(i%width) + 1) / (float) width;
        
        //print("mod: " + coordX + "\n");
        gradients[i] = coordX * shiftGradient;

        currColor = video.pixels[i];
        shiftColors = bitShift(currColor, shiftR, shiftG);
        shiftBackColors = bitShift(bkgdColor, 16, 8);

        if(displacementOn){
          //gradient = i%map(mouseX, 0, video.width, 0, 1000);
          if(displacement == 0){
            gradient = 0;
          } else {
            gradient = i%(displacement + lfo);
          }
        } else {
          //print(String.format("Grandients: %f\n",gradients[i]));
          gradient = gradients[i];
        }

        diffR = abs(shiftColors[0] - gradient);
        diffG = abs(shiftColors[1] + gradient);
        diffB = abs(shiftColors[2] - gradient);

        //print("diff " + i%width + "\n");
        pixels[i] = color(diffR, diffG, diffB);
        int index = i == 0? 0 : i - 1;
        prevPix = pixels[index];
        pixel = pixels[i];
        //pixels[i] = color(prevR, prevG, prevB);
        // The following line does the same thing much faster, but is more technical
        //pixels[i] = 0xFF000000 | (diffR << 16) | (diffG << 8) | diffB;
      }
      updatePixels(); // Notify that the pixels[] array has changed
    }
    fill(100, 180, 200);
    text("Gradient: " + gradient, 10, 200);
    text("Tan: " + tan(lfo), 10, 220);
    text("prevPix: " + prevPix, 10, 240);
    text("pixel: " + pixel, 10, 260);

}
// ---------------- PIXELS -----------------//

int[] bitShift(color currColor, int shiftR, int shiftG){
  int r = (currColor >> shiftR) & 0xFF;
  int g = (currColor >> shiftG) & 0xFF;
  int b = currColor & 0xFF;

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
    saveFrame(String.format("/Users/samanthalovisolo/Documents/projects/stills/gradient-%d -####.jpg",photoIndex));
    photoIndex ++;
  } else if(key == 'p'){
    shiftGradientSlider = (Slider)cp5.getController("shiftGradient");
    if(shiftGradientSlider == null){
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
    isVideoPlaying = true;
  } 
}

void initVideo(String path){
    video = new Movie(this,path);
    delay(3000);
    video.loop();
    video.volume(0);

    numPixels = video.width * video.height;
    gradients = new float[numPixels];
    backgroundPixels = new int[numPixels];

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
    backgroundGuiGroup.addCloseButton();

    addSlider("lfoFreq", 0, 0, 0.02);
    addSlider("lfoAmplitude", 0, 15, 3.0);

    cp5.getController("lfoFreq").setGroup("LFO");
    cp5.getController("lfoAmplitude").setGroup("LFO");
}
