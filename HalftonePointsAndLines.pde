/*
General idea: Find an arrangement of circles (Circle[] points), then make a halftoning pattern (Pattern outputPattern).
Allows for changing which circles are shown, the algorithm for finding points, the pattern style, and more.

Libraries:
- controlP5
- mesh: https://leebyron.com/mesh/


Functions:
- setup
- draw
- drawPoints
- prepareForNewRun: loads image, generates points and pattern
- loadAndPrepareImage

Outline:
- setup() 
-- calls setupGUI() to prepare the GUI
-- calls prepareForNewRun()
- prepareForNewRun() defines the colors of the background, ink.
-- calls loadAndPrepareImage() to load and resize the image
-- calls generatePoints() to find the circles that divide up the image
-- calls generatePattern() to use those circles to make a pattern.

- draw() displays the GUI on every frame, and the pattern when needed

*/


// Parameters that are controllable via GUI:
boolean blackBackground = false; // black vs white background
float rMaxScale = 8; // Ratio between the smallest, largest circles
float rDrawMaxCutoffScale = 1.0; // Circles larger than this are not drawn
float wLineScale = 1; // at most 1. line width = rMin*wLineScale
float nxScale = 100; // Detail level: can fit nxScale*2*rmin circles across the image
boolean continueOptimizing = false;

// for the appearance of the plots, GUI.
int guiBarHeight = 200;
color strokeColor = 0;
color fillColor = 0;
color backgroundColor = 255;
color imagelessColor = color(128,128,255);
color airTimeColor = color(255,120,0);
float airTimeWidth = 2;


int pointsChoice = 0;
int patternChoice = 1;

// Parameters that aren't immediately controllable.
int nIterationsOptimizationSwap = 20000;
String imageFilename = "rhino.jpg";
// initial base filename for outputs.
String outputFilenameBase = "rhinoHTPAL";
boolean needToRedraw;
boolean showAirTime = false; // whether or not to draw the toolpath when raised
float roundingDistance = 0.001; // to check if points are coincident.
float rMin = 3; // in pixels, used for computing packings.
float rMax;
int nx,ny;
// needed for rendering the dots, lines
float drawingScale = 1;
float drawingX0 = 0;
float drawingY0 = 0;
boolean useAreaScaling = true; //not actually useful. change the white balance of the image, if you'd prefer.


Circle[] points; // store the points
Pattern outputPattern; // store the halftoning pattern 
PImage pic; // store the loaded image.

void setup() {
  size(770, 800);
  //randomSeed(10);
  ellipseMode(RADIUS);
  strokeJoin(ROUND);
  
  setupGUI();
  prepareForNewRun();
}




void draw() {
  
  drawGUIBackground(); // since the GUI is drawn every time.
  
  // optimize as needed
  if(continueOptimizing){
    outputPattern.optimize();
  }
  
  // only redraw the pattern when necessary
  if (needToRedraw){
    fill(imagelessColor);
    noStroke();
    rect(0,0,width,height-guiBarHeight);
    
    // rescale to draw the dots, circles, image, whatever.
    pushMatrix();
    translate(drawingX0,drawingY0);
    scale(drawingScale);
    noStroke();
    fill(backgroundColor);
    rect(0,0,nx,ny);
    
    println("drawing pattern");
    outputPattern.draw();
    if(showAirTime){
      outputPattern.drawAirTime();
    }
    
    popMatrix();
    ((Toggle)(cp5.get("toggleShowImage"))).setValue(false);
    needToRedraw = false;
  }
}



// gotta recalculate all the things to start anew
void prepareForNewRun(){
  if(blackBackground){
    strokeColor = 255;
    fillColor = 255;
    backgroundColor = 0;
  }
  else{
    strokeColor = 0;
    fillColor = 0;
    backgroundColor = 255;
  }
  rMax = rMin*rMaxScale;
  
  loadAndPrepareImage();
  
  generatePoints();
  generatePattern();
  needToRedraw = true;
  continueOptimizing = false;
  ((Toggle)(cp5.get("toggleContinueOptimizing"))).setValue(false);
}




void loadAndPrepareImage() {
  pic = loadImage(imageFilename);
  println(pic);
  if(pic == null){
    println("file does NOT exist");
    generateDefaultImage();
  }
  
  nx = ceil(nxScale*2*rMin);
  ny = round(pic.height*nx*1.0/pic.width);
  println("Image size:",nx,ny);
  pic.resize(nx, ny);
  pic.filter(GRAY);
  pic.filter(BLUR,rMin/2);
  pic.loadPixels();

  // for drawing on screen
  drawingScale = min(1.0*width/(nx),1.0*(height-guiBarHeight)/(ny));
  drawingX0 = (width-drawingScale*nx)/2;
  drawingY0 = (height-drawingScale*ny-guiBarHeight)/2;
}

void generateDefaultImage(){
  int nx0= 100;
  int ny0 = 100;
  pic = createImage(100,100,RGB);
  outputFilenameBase = "defaultHTPAL";
  pic.loadPixels();
  float x = 0;
  float y = 0;
  float b = 0;
  for(int i=0; i<ny0; i++){
    //y = map(i,0,ny0-1,-1,1);
    y = (ny0-i)*1.0/nx0;
    for(int j=0; j<nx0; j++){
      //x = map(j,0,nx0-1,0.0,1);
      x = j*1.0/nx0-0.5;
      b= (sin(sqrt(x*x+y*y)*TWO_PI*2)/2+0.5);
      b = pow(b,0.1)*255;
      pic.pixels[i*nx0+j] = color(b);
    }
  }
}
