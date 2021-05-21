/*
Code for saving the output
- saveSVG
- saveTXT
- savePicture
*/

String makeOutputFilename(){
  return outputFolder+ java.io.File.separatorChar +outputFilenameBase+"_"+year()+""+nf(month(),2)+""+nf(day(),2)+ "_"+nf(hour(),2)+""+nf(minute(),2)+""+nf(second(),2);
}

import processing.svg.*;
void saveSVG(){
  println("saving SVG...");
  String outputFilename = makeOutputFilename();
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
  
  println("saved to SVG! ", outputFilename);
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

  String outputFilename = makeOutputFilename();
  saveStrings(outputFilename+".txt", tempStrings);
  
  // save a jpg as well.
  savePicture(outputFilename);
  
  println("Saved TXT file! ", outputFilename);
}

void savePicture(String outputFilename){
  // render a high-resolution output
  int patternHeight = max(defaultPatternHeight,pic.height);
  int patternWidth = round(patternHeight * 1.0*pic.width/pic.height);
  generatePatternGraphics(patternWidth, patternHeight);
  outputPattern.draw();
  drawnPattern.save(outputFilename+".png");
  println("Saved image file! ", outputFilename);
  // go back to the standard size
  generatePatternGraphics();
  needToRedraw = true;
}
