import controlP5.*;    
Button invertColors;
ControlP5 cp5; 

/*
There are four sections ot the UI:
- Load/save: load image, save as text, save as svg
- Re-runs if changed: choose parameters that require re-computing the points and/or pattern
- Optimization: show the pen path, optimize, keep optimizing, remove hidden points.
- Appearance: Change cut-off size, line width, show the source image

- setupGUI: sets up all the buttons, sliders, toggles.
- drawGUIBackground: 
- mousePressed: 
- all the other functions: particular functions for each button/slider/toggle
*/


PFont pfont;
ControlFont  cfont;
void setupGUI() {
  float y0 = height-guiBarHeight;

  float xLoadSave = 10;
  float xParams = 140;
  float xAppear = width-200;
  float xOptimize = 370;


  cp5 = new ControlP5(this);
  pfont = createFont("verdana", 12);
  cp5.setFont(pfont);


  
  // LOAD/SAVE
  cp5.addButton("buttonChooseImage")
    .setBroadcast(false)
    .setValue(0)
    .setPosition(xLoadSave, y0+30)
    .setSize(100, 20)
    .setCaptionLabel("Load image")
    .setBroadcast(true)
    ;     
  cp5.addButton("saveAsTXT")
    .setBroadcast(false)
    .setValue(0)
    .setPosition(xLoadSave, y0+60)
    .setSize(100, 20)
    .setCaptionLabel("Save TXT")
    .setBroadcast(true)
    ;
  cp5.addButton("saveAsSVG")
    .setBroadcast(false)
    .setValue(0)
    .setPosition(xLoadSave, y0+90)
    .setSize(100, 20)
    .setCaptionLabel("Save SVG")
    .setBroadcast(true)
    ;
  cp5.addButton("saveImage")
    .setBroadcast(false)
    .setValue(0)
    .setPosition(xLoadSave, y0+120)
    .setSize(100, 20)
    .setCaptionLabel("Save Image")
    .setBroadcast(true)
    ;
  

  // RE-RUNS IF CHANGED
  cp5.addToggle("toggleInvertColors")
    .setBroadcast(false)
    .setPosition(xParams, y0+30)
    .setSize(20, 20)
    .setValue(true)
    .setMode(ControlP5.DEFAULT)
    .setCaptionLabel("Use Black ink?")
    .setBroadcast(true)
    ;
  ((Toggle)(cp5.get("toggleInvertColors"))).getCaptionLabel().setPadding(28, -17);
  cp5.addSlider("rMaxScale")
    .setBroadcast(false)
    .setPosition(xParams, y0+120)
    .setSize(100, 20)
    .setValue(rMaxScale+0)
    .setRange(2, 20)
    .setCaptionLabel("Max radius")
    .setBroadcast(true)
    ;
  cp5.addSlider("nxScaleSlider")
    .setBroadcast(false)
    .setPosition(xParams, y0+150)
    .setSize(100, 20)
    .setValue(nxScale+0)
    .setRange(10, 400)
    .setCaptionLabel("Detail level")
    .setBroadcast(true)
    ;   
  //cp5.addToggle("toggleAreaScaling")
  //   .setBroadcast(false)
  //   .setPosition(xParams,y0+180)
  //   .setSize(50,20)
  //   .setValue(true)
  //   .setMode(ControlP5.SWITCH)
  //   .setCaptionLabel("scale by area/length")
  //   .setBroadcast(true);
  //   ;
  //((Toggle)(cp5.get("toggleAreaScaling"))).getCaptionLabel().setPadding(58,-17);
  cp5.addDropdownList("dropdownPattern")
    .setBroadcast(false)
    .setPosition(xParams, y0+90)
    .setSize(200, 100)
    .setCaptionLabel("Pattern style")
    .setItemHeight(20)
    .setBarHeight(20)
    .addItem("Dots", 0)
    .addItem("Circles", 1)
    .addItem("Tilted lines", 2)
    .addItem("Scanning path", 3)
    .addItem("Hilbert path", 4)
    .addItem("Greedy path", 5)
    .addItem("Greedy loop", 6)
    .addItem("Min Tree", 7)
    .addItem("Voronoi", 8)
    .addItem("Delaunay", 9)
    .addItem("Nearest Pts", 10)
    .setOpen(false)
    .setBackgroundColor(color(60))
    .setBroadcast(true)
    ;
  cp5.addDropdownList("dropdownPoints")
    .setBroadcast(false)
    .setPosition(xParams, y0+60)
    .setSize(200, 100)
    .setCaptionLabel("Point style")
    .setItemHeight(20)
    .setBarHeight(20)
    .addItem("Circle pack", 0)
    .addItem("Circles (less dense)", 1)
    .addItem("Random dither", 2)
    .addItem("Quadtree", 3)
    .addItem("Grid 1D dither", 4)
    .addItem("Grid 2D dither", 5)
    .addItem("Grid random dither", 6)
    .addItem("Hex 1D dither", 7)
    .addItem("Hex 2D dither", 8)
    .addItem("Hex random dither", 9)
    .setOpen(false)
    .setBackgroundColor(color(60))
    .setBroadcast(true)
    ;





  
  // OPTIMIZATION
  cp5.addToggle("toggleShowAirTime")
    .setBroadcast(false)
    .setValue(false)
    .setPosition(xOptimize, y0+30)
    .setMode(ControlP5.DEFAULT)
    .setSize(20, 20)
    .setCaptionLabel("show pen path")
    .setBroadcast(true)
    ;
  ((Toggle)(cp5.get("toggleShowAirTime"))).getCaptionLabel().setPadding(28, -17);
  cp5.addButton("buttonOptimizePattern")
    .setBroadcast(false)
    .setValue(0)
    .setPosition(xOptimize, y0+60)
    .setSize(100, 20)
    .setCaptionLabel("Optimize")
    .setBroadcast(true)
    ;    
  cp5.addToggle("toggleContinueOptimizing")
    .setBroadcast(false)
    .setValue(false)
    .setPosition(xOptimize, y0+90)
    .setMode(ControlP5.DEFAULT)
    .setSize(20, 20)
    .setCaptionLabel("Keep optimizing")
    .setBroadcast(true)
    ;
  ((Toggle)(cp5.get("toggleContinueOptimizing"))).getCaptionLabel().setPadding(28, -17);
  cp5.addButton("buttonDiscardLargeCircles")
    .setBroadcast(false)
    .setValue(0)
    .setPosition(xOptimize, y0+120)
    .setSize(140, 20)
    .setCaptionLabel("Remove hidden pts")
    .setBroadcast(true)
    ;   
    
  
  // APPEARANCE
  cp5.addSlider("rDrawMaxCutoffScale")
    .setBroadcast(false)
    .setPosition(xAppear, y0+30)
    .setSize(100, 20)
    .setValue(rDrawMaxCutoffScale+0)
    .setRange(0, 5)
    .setCaptionLabel("Size cutoff")
    .setBroadcast(true)
    ;
  cp5.addSlider("wLineScale")
    .setBroadcast(false)
    .setPosition(xAppear, y0+60)
    .setSize(100, 20)
    .setValue(wLineScale+0)
    .setRange(0.01, 3)
    .setCaptionLabel("Line width")
    .setBroadcast(true)
    ;
  cp5.addToggle("toggleShowImage")
    .setBroadcast(false)
    .setPosition(xAppear, y0+90)
    .setSize(20, 20)
    .setValue(false)
    .setMode(ControlP5.DEFAULT)
    .setCaptionLabel("show image")
    .setBroadcast(true);
  ;
  ((Toggle)(cp5.get("toggleShowImage"))).getCaptionLabel().setPadding(28, -17);
  
  
  
  cp5.draw();
}


void toggleInvertColors(boolean theFlag) {
  if (theFlag==false) {
    blackBackground = true;
  } else {
    blackBackground = false;
  }
  prepareForNewRun();
}


//void toggleAreaScaling(boolean theFlag) {
//  useAreaScaling = theFlag;
//  prepareForNewRun();
//}

void toggleShowImage(boolean theFlag) {
  if (theFlag==true) {
    println("showing image");
    pushMatrix();
    translate(drawingX0, drawingY0);
    scale(drawingScale);
    image(pic, 0, 0);
    popMatrix();
  } else {
    needToRedraw = true;
  }
}




// discard circles larger than the cutoff value
void buttonDiscardLargeCircles(int theValue) {
  int nOK = 0;
  float rDrawMax = rMax*rDrawMaxCutoffScale;
  for(int i=0; i<points.length; i++){
    if(points[i].r<=rDrawMax){
      nOK++;
    }
  }
  Circle[] newPoints = new Circle[nOK];
  int ctr = 0;
  for(int i=0; i<points.length; i++){
    if(points[i].r<=rDrawMax){
      newPoints[ctr] = points[i];
      ctr++;
    }
  }
  points = newPoints;
  println("large circles discarded");
  generatePattern();
  
}

void buttonOptimizePattern(int theValue) {
  outputPattern.optimize();
}
void toggleContinueOptimizing(boolean theFlag) {
  continueOptimizing = theFlag;
}


void dropdownPattern(int theValue) {
  //println("dropdown pattern "+theValue);
  // be able to repeat stochastic ones.
  if (patternChoice != theValue || theValue==5|| theValue==6) {
    patternChoice = theValue+0;
    generatePattern();
    needToRedraw = true;
  }
}

void dropdownPoints(int theValue) {
  //println("dropdown points "+theValue);
  // be able to repeat stochastic ones.
  //if (pointsChoice != theValue || theValue==2 || theValue==6 || theValue==9) {
    pointsChoice = theValue+0;
    generatePoints();
    generatePattern();
    needToRedraw = true;
  //}
}

void toggleShowAirTime(boolean theFlag) {
  showAirTime = theFlag;
  //if(showAirTime){
  needToRedraw = true;
  //}
}


void nxScaleSlider(float theVal) {
  nxScale = theVal;
  prepareForNewRun();
}
void rMaxScale(float theVal) {
  rMaxScale = theVal;
  prepareForNewRun();
}
void rDrawMaxCutoffScale(float theVal) {
  rDrawMaxCutoffScale = theVal;
  //println("new cutoff:",theVal,rDrawCutoffScale);
  //drawCircles();
  needToRedraw = true;
}
void wLineScale(float theVal) {
  //println("change wLineScale");
  wLineScale = theVal;
  //drawCircles();
  needToRedraw = true;
}


void buttonRecomputeCircles(int theValue) {
  println("recompute circles");
  prepareForNewRun();
}

void saveAsSVG(int theValue) {
  saveSVG();
}

void saveAsTXT(int theValue) {
  saveTXT();
}

void saveImage(int theValue) {
  String outputFilename = outputFilenameBase+"_"+year()+""+nf(month(),2)+""+nf(day(),2)+ "_"+nf(hour(),2)+""+nf(minute(),2)+""+nf(second(),2);
  savePicture(outputFilename);
}

void buttonChooseImage(int theValue) {
  selectInput("Select a file to process:", "fileSelected");
}



void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected " + selection.getAbsolutePath());
    String tempFilename = selection.getAbsolutePath();


    String tempFilename2 = tempFilename.toLowerCase();

    String[] okExts = {".gif", ".png", ".jpeg", ".jpg", ".tiff", ".tif", ".bmp"};
    boolean pathOK = false;
    for (int i=0; i<okExts.length; i++) {
      if (tempFilename2.endsWith(okExts[i])) {

        imageFilename = tempFilename;
        //outputFilenameBase = (tempFilename+"").replaceFirst("[.][^.]+$", "");
        int i1 = tempFilename.lastIndexOf("\\");
        if (i1==-1) {
          outputFilenameBase = tempFilename+"";
        } else {
          int i2 = tempFilename.lastIndexOf(".");
          outputFilenameBase = tempFilename.substring(i1+1, i2);
        }
        outputFilenameBase = outputFilenameBase+"HTPAL";
        //println("testing stripping the extension:",outputFilenameBase);
        pathOK = true;
        break;
      }
    }
    if (pathOK) {
      println("Image loaded successfully");
      prepareForNewRun();
      needToRedraw = true;
    } else
      println("Image loading FAILED. Bad filename.");
  }
}


void mousePressed() {
  if (mouseX>=width-180 && mouseX<=width-5 && mouseY>=height-25 && mouseY<=height-3) { 
    link("www.EstebanHufstedler.com");
  }
}

void drawGUIBackground() {
  noStroke();
  fill(80);
  rect(0, height-guiBarHeight, width, height);
  fill(255);
  textAlign(LEFT);
  text("LOAD/SAVE", 10, height-guiBarHeight+20);
  text("RE-RUNS IF CHANGED", 140, height-guiBarHeight+20);
  text("OPTIMIZATION", 370, height-guiBarHeight+20);
  text("APPEARANCE", width-200, height-guiBarHeight+20);


  text("TOTAL POINTS: " + points.length, 370, height-34);

  textAlign(RIGHT);
  text("CircleStackPack 1.0", width-10, height-30); 
  text("www.EstebanHufstedler.com", width-10, height-10);
}
