import java.util.Scanner;
import java.lang.Thread;

import processing.video.*;
import controlP5.*;

int numPixels;
int[] backgroundPixels;
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
String path;
int photoIndex;
float lfo;

color currColor;
color bkgdColor; 

Slider shiftGradientSlider;
Slider backRSlider;

Movie video;

int shiftR;
int shiftG;

float lfoFreq;
float lfoAmplitude;

void setup() {
    size(640, 480); 
    colorMode(HSB);
    frameRate(30);
    cp5 = new ControlP5(this);
    path = "";
    shiftGradient = 0.0;
    displacement = 0;
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
    initVideo("makeamove.mp4");
    setupOptions();

}

void draw() {
    //image(video, 0,0, width, height);
    if(isVideoPlaying && video.width > 0){
      video.loadPixels(); // Make the pixels of video available
      // Difference between the current frame and the stored background
      //lfoFreq = map(lfoFreq, 0.0, 500, 0.00005, 2);
      lfo =  sin(millis()* lfoFreq) * lfoAmplitude;

      for (int i = 0; i < numPixels; i++) { 
        coordX =  ((float)(i%width) + 1) / (float) width;
        
        //print("mod: " + coordX + "\n");
        gradients[i] = coordX * shiftGradient;

        currColor = video.pixels[i];
        bkgdColor = backgroundPixels[i];
      
        currR = (currColor >> shiftR) & 0xFF;
        currG = (currColor >> shiftG) & 0xFF;
        currB = currColor & 0xFF;
     
        backR = (bkgdColor >> 16) & 0xFF;
        backG = (bkgdColor >> 8) & 0xFF;
        backB = bkgdColor & 0xFF;

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

        diffR = abs(currR - gradient);
        diffG = abs(currG + gradient);
        diffB = abs(currB - gradient);
        //print(String.format("Curent Red: %d, Red: %f\n", currR, diffR));

        //print("diff " + i%width + "\n");
        pixels[i] = color(diffR, diffG, diffB);
        // The following line does the same thing much faster, but is more technical
        //pixels[i] = 0xFF000000 | (diffR << 16) | (diffG << 8) | diffB;
      }
      updatePixels(); // Notify that the pixels[] array has changed
    }
}

// When a key is pressed, capture the background image into the backgroundPixels
// buffer, by copying each of the current frame's pixels into it.
void keyPressed() {
  if(key == 'n'){
    displacementOn = !displacementOn;
    if(!displacementOn){
      displacement = 0;
      video.loadPixels();
      arraycopy(video.pixels, backgroundPixels);
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

void movieEvent(Movie video){
  if(video.available()){
    video.read();
    isVideoPlaying = true;
  } 
}

void initVideo(String path){
    video = new Movie(this,path);
    video.loop();
    video.volume(0);

    numPixels = video.width * video.height;
    gradients = new float[numPixels];
    backgroundPixels = new int[numPixels];

    addSlider("displacement", 220, 10, 1000.0);
      
    print(String.format("Video size: %d, pixels: %d\n", video.width, numPixels));
    // Make the pixels[] array available for direct manipulation
    loadPixels();
}

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
