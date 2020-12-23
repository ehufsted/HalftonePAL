/*
Code for saving the output
- saveSVG
- saveTXT
- savePicture
*/

import processing.svg.*;
void saveSVG(){
  println("saving SVG...");
  String outputFilename = outputFilenameBase+"_"+year()+""+nf(month(),2)+""+nf(day(),2)+ "_"+nf(hour(),2)+""+nf(minute(),2)+""+nf(second(),2);
  PGraphics svg = createGraphics(nx, ny, SVG, outputFilename+".svg");
  svg.ellipseMode(RADIUS);
  svg.beginDraw();
  float wLine = rMin*wLineScale;
  svg.strokeWeight(wLine);
  svg.background(backgroundColor);
  svg.fill(fillColor);
  svg.stroke(strokeColor);
  svg.ellipseMode(RADIUS);
  outputPattern.drawToSVG(svg);
  svg.dispose();
  svg.endDraw();
  
  //// save a jpg as well.
  savePicture(outputFilename);
  
  println("saved to SVG!");
}

void saveTXT(){
  println("Saving TXT...");
  
  // for each shape in the pattern, get its string representation, add to an arraylist
  ArrayList<String> stringList = new ArrayList<String>(points.length);
  String[] tempStrings;
  for(int i=0; i<outputPattern.shapes.length; i++){
    tempStrings = outputPattern.shapes[i].getTextVersion();
    for(int j=0; j<tempStrings.length; j++){
      stringList.add(tempStrings[j]);
    }
  }
  tempStrings = stringList.toArray(new String[0]);

  String outputFilename = outputFilenameBase+"_"+year()+""+nf(month(),2)+""+nf(day(),2)+ "_"+nf(hour(),2)+""+nf(minute(),2)+""+nf(second(),2);
  saveStrings(outputFilename+".txt", tempStrings);
  
  // save a jpg as well.
  savePicture(outputFilename);
  
  println("Saved TXT file!");
}

void savePicture(String filenameBase){
  float sc = drawingScale;
  float x0 = drawingX0;
  float y0 = drawingY0;
  PImage imageOutput = get(ceil(x0)+1,ceil(y0)+1,floor(nx*sc)-1,floor(ny*sc)-1);
  imageOutput.save(filenameBase+".png");
}
