/*
Define the basic shapes that make up the point and line halftoning
- HTShape
- Circle
- PolyLine
*/

class HTShape{
  float x,y; // "center" location
  void draw(){}
  void drawToSVG(PGraphics svg){}
  
  boolean equals(Object obj){
    return false;
  };
  
  // returns [x1,y1,xfinal,yfinal]
  float[] drawAirTime(){
    return new float[4];
  }
  
  String[] getTextVersion(){
    return new String[0]; 
  }
}


class Circle extends HTShape{
  float x,y;
  boolean filled = false;
  boolean actLikePoint = false;
  float r = rMin;
  float t = 0;
  float k = 0;
  Circle(){
    x = random(1)*pic.width;
    y = random(1)*pic.height;
  }
  Circle(float x0,float y0){
    x = x0+0;
    y = y0+0;
  }
  Circle(float x0,float y0,float r0){
    x = x0+0;
    y = y0+0;
    r = r0+0;
  }
  Circle(float x0,float y0,float r0, float k0){
    x = x0+0;
    y = y0+0;
    r = r0+0;
    k = k0+0;
  }
  
  void draw(){
    float rDrawMax = rDrawMaxCutoffScale*rMax;
    if(r<=rDrawMax){
      if(actLikePoint){
        drawnPattern.fill(fillColor);
        drawnPattern.noStroke();
        drawnPattern.ellipse(x,y,rMin*wLineScale,rMin*wLineScale);
      }
      else{
        if (filled){
          drawnPattern.fill(fillColor);
          drawnPattern.noStroke();
        }
        else{
          drawnPattern.strokeWeight(rMin*wLineScale);
          drawnPattern.stroke(strokeColor);
          drawnPattern.noFill();
        }
        drawnPattern.ellipse(x,y,r,r);
      }
    }
  }
  
  void drawToSVG(PGraphics svg){
    float rDrawMax = rDrawMaxCutoffScale*rMax;
    if(r<=rDrawMax){
      if (actLikePoint) { // draw a point
        svg.strokeWeight(rMin*wLineScale*2);
        svg.point(x,y);
      }
      else{
        if (filled){
          svg.fill(fillColor);
          svg.noStroke();
        }
        else{
          svg.strokeWeight(rMin*wLineScale);
          svg.stroke(strokeColor);
          svg.noFill();
        }
        svg.ellipse(x,y,r,r);
      }
    }
  }
  
  
  boolean equals(Object obj){
    Circle obj2 = (Circle)obj;
    return ( (abs(x-obj2.x)<roundingDistance) && 
             (abs(y-obj2.y)<roundingDistance) && 
             (abs(r-obj2.r)<roundingDistance));
  }
  
  void drawCenter(){
    drawnPattern.fill(fillColor);
    drawnPattern.noStroke();
    drawnPattern.ellipse(x,y,1.5,1.5);
  }
  
  float[] drawAirTime(){
    float rDrawMax = rDrawMaxCutoffScale*rMax;
    if(r<=rDrawMax){
      return(new float[]{x+0,y+0,x+0,y+0});
    }
    else
      return new float[0];
  }
  
  String[] getTextVersion(){
    return new String[]{x + "\t" + y + "\t" +  r}; 
  }
}


// use for points or circles
class PolyLine extends HTShape{
  float x,y;
  float[] xs,ys;
  boolean closed = false;
  
  PolyLine(){
    xs = new float[]{random(1)*pic.width,random(1)*pic.width};
    xs = new float[]{random(1)*pic.height,random(1)*pic.height};
  }
  
  PolyLine(float[] x0,float[] y0){
    
    xs = x0;
    ys = y0;
    x = xs[0];
    y = ys[0];
  }
  
  void smoothOnce(){
    int iMax = xs.length;
    int nNew = 2*xs.length;
    float[] xs2 = new float[nNew];
    float[] ys2 = new float[nNew];

    int iNext;
    int i2;
    // Chaikin smoothing
    for(int i=0; i<iMax;i++){
      iNext = (i+1)%xs.length;
      i2 = i*2;
      xs2[i2] = xs[i]+(xs[iNext]-xs[i])*0.25;
      ys2[i2] = ys[i]+(ys[iNext]-ys[i])*0.25;
      i2 = i*2+1;
      xs2[i2] = xs[i]+(xs[iNext]-xs[i])*0.75;
      ys2[i2] = ys[i]+(ys[iNext]-ys[i])*0.75;
    }
    if(closed){
      xs = xs2;
      ys = ys2;
    }
    else{
      float[] xs3 = new float[nNew-2];
      float[] ys3 = new float[nNew-2];
      for(int i=0; i<xs2.length-2;i++){
        xs3[i] = xs2[i+1];
        ys3[i] = ys2[i+1];
      }
      xs = xs3;
      ys = ys3;
    }
  }
  
  void drawToSVG(PGraphics svg){
    findSegsToDraw();
    svg.stroke(fillColor);
    svg.strokeWeight(rMin*wLineScale);
    svg.noFill();
    for(float[] lineSeg : segsToDraw){
      svg.line(lineSeg[0],lineSeg[1],lineSeg[2],lineSeg[3]);
    }
  }
  void draw(){
    findSegsToDraw();
    drawnPattern.stroke(fillColor);
    drawnPattern.strokeWeight(rMin*wLineScale);
    drawnPattern.noFill();
    for(float[] lineSeg : segsToDraw){
      drawnPattern.line(lineSeg[0],lineSeg[1],lineSeg[2],lineSeg[3]);
    }
  }
  
  // find the segments that must be drawn.
  // so that it can be used for drawing on screen or SVG
  ArrayList<float[]> segsToDraw;
  void findSegsToDraw(){
    segsToDraw = new ArrayList<float[]>(xs.length);

    if(closed){
      // just based on area
      float areaMax = PI*pow(rDrawMaxCutoffScale*rMax,2);
      float area = 0;
      int i2;
      for(int i=0; i<xs.length; i++){
        i2 = (i+1)%xs.length;
        //area+= (xs[i]+xs[i2])*(ys[i2]-ys[i]);
        area+= xs[i]*ys[i2]-ys[i]*xs[i2];
      }
      area = abs(area)/2;
      if(area<=areaMax){
        float[] lineSeg = new float[4];
        float[] lineSeg2;
        for(int i=0; i<xs.length; i++){
          i2 = (i+1)%xs.length;
          lineSeg[0] = xs[i];
          lineSeg[1] = ys[i];
          lineSeg[2] = xs[i2];
          lineSeg[3] = ys[i2];
          lineSeg2 = trimLineSeg(lineSeg);
          if(lineSeg2.length>0){
            segsToDraw.add(lineSeg2.clone());
          }
        }
      }
    }
    else{
      float rDrawMax2 = pow(rDrawMaxCutoffScale*rMax,2);
      float d2;
      float[] lineSeg = new float[4];
      for(int i=0; i<xs.length-1; i++){
        d2 = pow(xs[i+1]-xs[i],2)+pow(ys[i+1]-ys[i],2);
        if(d2<=4*rDrawMax2){
          lineSeg[0] = xs[i];
          lineSeg[1] = ys[i];
          lineSeg[2] = xs[i+1];
          lineSeg[3] = ys[i+1];
          segsToDraw.add(lineSeg.clone());
        }
      }
    }
  }
  
  boolean equals(Object obj){
    PolyLine obj2 = (PolyLine)obj;
    if(xs.length != obj2.xs.length){
      return false;
    }
    else{
      // check in the forward direction
      boolean equalForward = true;
      boolean thisCheck = false;
      for(int i=0; i<xs.length; i++){
        thisCheck =  (abs(xs[i]-obj2.xs[i])<roundingDistance) &&
                     (abs(ys[i]-obj2.ys[i])<roundingDistance);
        if(!thisCheck){
          equalForward = false;
          break;
        }
      }
      if(equalForward){
        return true;
      }
      else{ // check backward
        boolean equalBackward = true;
        for(int i=0; i<xs.length; i++){
          thisCheck =  (abs(xs[i]-obj2.xs[xs.length-1-i])<roundingDistance) &&
                       (abs(ys[i]-obj2.ys[xs.length-1-i])<roundingDistance);
          if(!thisCheck){
            equalBackward = false;
            break;
          }
        }
        return equalBackward;
      }
    }
  }
  
  float[] drawAirTime(){
    findSegsToDraw();
    if(segsToDraw.size()>0){
      //drawnPattern.beginDraw();
      drawnPattern.noFill();
      drawnPattern.stroke(airTimeColor);
      drawnPattern.strokeWeight(airTimeWidth);
      float x1,y1,x2,y2;
      for(int i=0; i<segsToDraw.size()-1; i++){
        x1 = segsToDraw.get(i)[2];
        y1 = segsToDraw.get(i)[3];
        x2 = segsToDraw.get(i+1)[0];
        y2 = segsToDraw.get(i+1)[1];
        if((abs(x2-x1)+abs(y2-y1))>roundingDistance){
          drawnPattern.line(x1,y1,x2,y2);
          drawnPattern.ellipse(x1,y1,5,5);
        }
      }
      //drawnPattern.endDraw();
      return(new float[]{segsToDraw.get(0)[0]+0,segsToDraw.get(0)[1]+0,
                         segsToDraw.get(segsToDraw.size()-1)[2]+0,segsToDraw.get(segsToDraw.size()-1)[3]+0});
    }
    else{
      return new float[0];
    }
  }
  
  String[] getTextVersion(){
    String[] outputText = new String[segsToDraw.size()];
    for(int i=0; i<segsToDraw.size(); i++){
      outputText[i] = segsToDraw.get(i)[0] + "\t"
                      +segsToDraw.get(i)[1] + "\t"
                      +segsToDraw.get(i)[2] + "\t"
                      +segsToDraw.get(i)[3];
    }
    
    return outputText; 
  }
}
