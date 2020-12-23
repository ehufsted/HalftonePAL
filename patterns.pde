/////////////////////////////////////////////////////////////////////////////////////////////////////////
/* Outline

Patterns take in the points[] from the arrangePoints methods, and use them to make an array of HTShapes.

- patternDrawMinDots: draw the central dot, essentially.
- patternDrawCircles: draws the outlines of the circles
- patternScanSort: a simple approximation of the TSP, by scanning back and forth.
- patternTSPGreedy: One-way traveling salesman, greedy approximation.
- patternTSPGreedyLoop: Forms a traveling salseman loop, inserts points to grow. Better, but slower.
- patternNNearestNeighbors: slow, so don't use it.
- patternSingleHatched: A single line, tilted to show the local orientation. 
- patternVoronoi: Voronoi diagrams
- patternDelaunay: Delaunay triangulation
- patternDelaunayNN: Plots the k nearest neighbors, using the Delaunay triangulation. Practically, n<6
- patternDelaunayMST: minimum spanning tree, using the Delaunay triangulation and Prim's algorithm.

There are also a bunch of optimization functions:
- sortPolyLines
- sortSegs
- reorderCircles
- reorderPolyLine: for a single line, it tries to optimize the path by 
- reorderCircleData: checks if it finds a shorter path by reversing a section.

*/

void generatePattern(){
  int t1 = millis();
  // does not use patternNNearestNeighbors, because it is slow and bad.
  switch(patternChoice){
    case 0:
      patternDrawMinDots();
      break;
    case 1:
      patternDrawCircles(false,false);
      break;
    case 2:
      patternSingleHatched(PI/2);
      break;
    case 3:
      patternScanSort();
      break;
    case 4:
      patternHilbertSort(rMin);
      break;
    case 5:
      patternTSPGreedy();
      break;
    case 6:
      patternTSPGreedyLoop();
      break;
    case 7:
      patternDelaunayMST();
      break;
    case 8:
      patternVoronoi(0);
      break;
    case 9:
      patternDelaunay();
      break;
    case 10:
      patternDelaunayNN(3);
      break;
    
    default:
      patternDrawMinDots();
      break;
  }
  int t2 = millis();
  println("Pattern found in "+(t2-t1)/1000.0+" s");
  continueOptimizing = false;
  ((Toggle)(cp5.get("toggleContinueOptimizing"))).setValue(false);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// general definition of a pattern: it holds an array of shapes
class Pattern{
  HTShape[] shapes;
  
  Pattern(HTShape[] newShapes){
    shapes = newShapes;
  }
  
  void draw(){
    for(int i=0; i<shapes.length;i++)
      shapes[i].draw();
  }
  
  void drawToSVG(PGraphics svg){
    for(int i=0; i<shapes.length;i++)
      shapes[i].drawToSVG(svg);
  }
  
  void drawAirTime(){
    float x1=-1,y1=0,x2,y2;
    float[] startAndFinish;
    for(int i=0; i<shapes.length; i++){
      // this also gets its first and last points
      startAndFinish = shapes[i].drawAirTime();
      if(startAndFinish.length>0){
        x2 = startAndFinish[0]+0;
        y2 = startAndFinish[1]+0;
        if(x1!=-1){
          noFill();
          stroke(airTimeColor);
          strokeWeight(airTimeWidth);
          if((abs(x2-x1)+abs(y2-y1))>roundingDistance){
            line(x1,y1,x2,y2);
          }
        }
        x1 = startAndFinish[2]+0;
        y1 = startAndFinish[3]+0;
      }
    }
    
  }
  
  void optimize(){
    if( shapes[0].getClass()==(new Circle()).getClass()  ){
      // array of Circles
      println("Trying to shorten path between Circles");
      shapes = reorderCircles(shapes);
    }
    if( shapes[0].getClass()==(new PolyLine()).getClass()  ){
      // array of PolyLines
      println("Trying to optimize PolyLines");
      if(shapes.length>1){
        shapes = sortPolyLines(shapes);
        // not helpful to keep sorting, with the current implementation.
        continueOptimizing = false;
        ((Toggle)(cp5.get("toggleContinueOptimizing"))).setValue(false);
      }
      else{
        //println("there's only one polyline, so need to sort that one");
        shapes[0] = reorderPolyLine((PolyLine)shapes[0]);
      }
    }
    needToRedraw = true;
  }
}

// making a greedy path between line segments, including reversing segments
HTShape[] sortPolyLines(HTShape[] shapes){
  float[][] segs = new float[shapes.length][4];
  PolyLine PL;
  for(int i=0; i<shapes.length; i++){
    PL = (PolyLine)shapes[i];
    segs[i][0] = PL.xs[0]+0;
    segs[i][1] = PL.ys[0]+0;
    segs[i][2] = PL.xs[PL.xs.length-1]+0;
    segs[i][3] = PL.ys[PL.xs.length-1]+0;
  }
  // sort the segments
  int[][] segInds = sortSegs(segs);
  HTShape[] newShapes = new HTShape[shapes.length];
  int i0;
  float[] xs,ys;
  
  // re-arrange, using the given order.
  for(int i=0; i<shapes.length; i++){
    i0 = segInds[i][0];
    PL = (PolyLine)shapes[i0];
    xs = PL.xs;
    ys = PL.ys;
    if(segInds[i][1]==1){ // reverse, if they need to be reversed
      xs = reverseArray(xs);
      ys = reverseArray(ys);
    }
    newShapes[i] = new PolyLine(xs.clone(),ys.clone());
  }
  println("sorted segments");
  return newShapes;
}


// returns an int array [i][reversed?]
// greedily finds the closest segment start/endpoint, goes to that one. 
int[][] sortSegs(float[][] segs){
  // do a greedy sort
  int[][] sortedSegs = new int[segs.length][2]; // [initial index, reversed?]
  
  ArrayList<Integer> tooBig = new ArrayList<Integer>(segs.length); //extra points get tacked onto the end.
  ArrayList<Integer> unused = new ArrayList<Integer>(segs.length);

  float LDrawMax2 = pow(2*rDrawMaxCutoffScale*rMax,2);
  float L2;
  for(int i=0; i<segs.length; i++){
    L2 = pow(segs[i][0]-segs[i][2],2)+pow(segs[i][1]-segs[i][3],2);
    if (L2<=LDrawMax2){
      unused.add(i);
    }
    else{
      tooBig.add(i);
    }
  }
  //println("made sorting arraylists");

  int ctr = 0;
  int iBest = floor(random(unused.size()));
  //int iBest = 0;
  float xPrev,yPrev;
  sortedSegs[ctr][0] = unused.get(iBest);
  xPrev = segs[unused.get(iBest)][2];
  yPrev = segs[unused.get(iBest)][3];
  ctr++;
  unused.remove(iBest);
  
  // greedy method: find the nearest unused point
  float d2,d2A,d2B,d2Best;
  int icu,ic2;
  boolean secondBest = false;
  
  //println("starting greediness");
  while(unused.size()>0){  
    d2Best = (width+height)*(width+height);
    iBest = 0;
    // for each seg that remains unused, find the min distance
    for(int i=0; i<unused.size(); i++){
      ic2 = unused.get(i);
      d2A = pow(xPrev-segs[ic2][0],2)+pow(yPrev-segs[ic2][1],2);
      d2B = pow(xPrev-segs[ic2][2],2)+pow(yPrev-segs[ic2][3],2); // reversed?
      d2 = min(d2A,d2B);
      if (d2<d2Best){
        d2Best = d2+0;
        secondBest = d2B<d2A; // what order?
        iBest = i+0;
      }
    }
    //println("Added a point",ctr,unused.get(iBest));
    sortedSegs[ctr][0] = unused.get(iBest);
    if(secondBest){
      sortedSegs[ctr][1] = 1;
      xPrev = segs[unused.get(iBest)][0];
      yPrev = segs[unused.get(iBest)][1];
    }
    else{
      xPrev = segs[unused.get(iBest)][2];
      yPrev = segs[unused.get(iBest)][3];
    }
    
    ctr++;
    unused.remove(iBest);   
  }
  
  for(int i=0; i<tooBig.size(); i++){
    icu = tooBig.get(i)+0;
    sortedSegs[ctr][0] = icu+0;
    ctr++;
  }
  
  //for(int i=0; i<sortedSegs.length; i++){
  //  println(i,sortedSegs[i][0]);
  //}
  
  return sortedSegs;
}



HTShape[] reorderCircles(HTShape[] circs){
  float[][] data = new float[circs.length][4]; // x, y, r, i0
  //println("made data array");
  Circle circ;
  for(int i=0; i<data.length; i++){
    circ = (Circle)(circs[i]);
    data[i][0] = circ.x+0;
    data[i][1] = circ.y+0;
    data[i][2] = circ.r+0;
    data[i][3] = i+0;
  }
  data = reorderCircleData(data).clone();
  
  Circle[] circs2 = new Circle[circs.length];
  for(int i=0; i<data.length; i++){
    circs2[i] = new Circle(data[i][0],data[i][1],data[i][2]);
    circs2[i].actLikePoint = ((Circle)circs[int(data[i][3])]).actLikePoint;
  }
  //println("made new circles");
  return circs2;
}


PolyLine reorderPolyLine(PolyLine pl){
  float[][] data = new float[pl.xs.length][4]; // x, y, r, i0
  //println("made data array");
  for(int i=0; i<data.length; i++){
    data[i][0] = pl.xs[i]+0;
    data[i][1] = pl.ys[i]+0;
  }
  data = reorderCircleData(data).clone();
  
  float[] xsNew = new float[data.length];
  float[] ysNew = new float[data.length];
  for(int i=0; i<data.length; i++){
    xsNew[i] = data[i][0];
    ysNew[i] = data[i][1];
  }
  return new PolyLine(xsNew,ysNew);
}


// additional sorting pass for circles.
// checks if it finds a shorter path by reversing a section.
// if that helps, make that the new order.
float[][] reorderCircleData(float[][] data){
  // data is [i][x,y,r,i0];
  int nIter = 10000;
  int iA0,iB0,temp,iA1,iB1;
  float d1,d2;
  float xtemp,ytemp,rtemp,itemp;
  
  // spiritually copied from StippleGen, since it's a good simple algorithm.
  for(int iIter=0; iIter<nIter; iIter++){
    // pick two random indices
    iA0 = floor(random(data.length-1));
    iB0 = floor(random(data.length-1));
    if(iA0>iB0){
      temp = iB0+0;
      iB0= iA0+0;
      iA0 = temp+0;
    }
    iA1 = iA0+1;
    iB1 = iB0+1;
    d1 = pow(data[iA0][0]-data[iA1][0],2)+pow(data[iA0][1]-data[iA1][1],2)+
         pow(data[iB0][0]-data[iB1][0],2)+pow(data[iB0][1]-data[iB1][1],2); //normal
    d2 = pow(data[iA0][0]-data[iB0][0],2)+pow(data[iA0][1]-data[iB0][1],2)+
         pow(data[iA1][0]-data[iB1][0],2)+pow(data[iA1][1]-data[iB1][1],2); //swapped
    
    if (d2<d1){
      //println("Success on",iIter);
      int iHigh = iB0;
      int iLow = iA0+1;
      
      while (iHigh>iLow){
        xtemp = data[iLow][0]+0;
        ytemp = data[iLow][1]+0;
        rtemp = data[iLow][2]+0;
        itemp = data[iLow][3]+0;
        data[iLow][0] = data[iHigh][0]+0;
        data[iLow][1] = data[iHigh][1]+0;
        data[iLow][2] = data[iHigh][2]+0;
        data[iLow][3] = data[iHigh][3]+0;
        data[iHigh][0] = xtemp+0;
        data[iHigh][1] = ytemp+0;
        data[iHigh][2] = rtemp+0;
        data[iHigh][3] = itemp+0;
        iHigh--;
        iLow++;
      }
    }
  }
  
  return data;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Treat the points like point-ish things.
void patternDrawMinDots(){ 
  Circle[] points2 = new Circle[points.length];;
  for(int i=0; i<points.length; i++){ 
    points2[i] = new Circle(points[i].x,points[i].y,points[i].r);
    points2[i].actLikePoint = true;
  }
  outputPattern = new Pattern(points2);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Fill the circles with black, if so desired
void patternDrawCircles(boolean rescaleCircles, boolean fillCircles){ 
  Circle[] points2 = points.clone();
  for(int i=0; i<points.length; i++){
    points2[i].filled = fillCircles;
    if(rescaleCircles){
      points2[i].r = points2[i].r*sqrt(points2[i].k);
    }
  }
  outputPattern = new Pattern(points2);
}




/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Connect the points in the back-and-forth way.
void patternScanSort(){
  float[] dataToSort = new float[points.length];
  int iys;
  float v;
  float rowWidth = sqrt(nx*ny/(1.0*points.length))*1.5;
  for(int i=0; i<points.length; i++){
    iys = round(points[i].y/rowWidth);
    v = iys*nx*2;
    if ((iys%2)==1)
      v += points[i].x;
    else
      v += nx-points[i].x;   
    dataToSort[i] = v; 
  }
  int[] sortedIndices = sortedArrayIndices(dataToSort);
  
  float[] xs = new float[points.length];
  float[] ys = new float[points.length];
  int i2;
  for(int i=0; i<points.length; i++){
    i2 = sortedIndices[i];
    xs[i] = points[i2].x;
    ys[i] = points[i2].y;
  }
  
  HTShape[] shapes = new HTShape[1];
  shapes[0] = new PolyLine(xs,ys);
  outputPattern = new Pattern(shapes);
  
  println("Sorted back-and-forth");
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Greedy TSP
void patternTSPGreedy(){ // the greedy way
  ArrayList<Integer> used = new ArrayList<Integer>(points.length);
  ArrayList<Integer> unused = new ArrayList<Integer>(points.length);

  //float rDrawMax = rMax*rDrawMaxCutoffScale;
  for(int i=0; i<points.length; i++){
    //if (points[i].r<=rDrawMax){
      unused.add(i);
    //}
  }
  int iInit = floor(random(points.length));
  used.add(unused.get(iInit));
  unused.remove(iInit);
  // greedy method: find the nearest unused point
  int iBest;
  float d2,d2Best;
  float x0,y0;
  int icu,ic2;
  while(unused.size()>0){
    icu = used.get(used.size()-1);
    
    x0 = points[icu].x;
    y0 = points[icu].y;
    
    d2Best = (width+height)*(width+height);
    iBest = 0;
    // for each circle that remains unused, find the min distance
    for(int i=0; i<unused.size(); i++){
      ic2 = unused.get(i);
      d2 = pow(x0-points[ic2].x,2)+pow(y0-points[ic2].y,2);
      //d2 = circles[ic2][1];
      if (d2<d2Best){
        d2Best = d2+0;
        iBest = i+0;
      }
    }
    used.add(unused.get(iBest));
    unused.remove(iBest);
  }

  float[] xs = new float[points.length];
  float[] ys = new float[points.length];
  int i2;
  for(int i=0; i<points.length; i++){
    i2 = used.get(i);
    xs[i] = points[i2].x;
    ys[i] = points[i2].y;
  }

  HTShape[] shapes = new HTShape[1];
  shapes[0] = new PolyLine(xs,ys);
  outputPattern = new Pattern(shapes);
  println("Sorted via greedy TSP");
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Greedy loop TSP
void patternTSPGreedyLoop(){ // the loop-insertion way
  ArrayList<Integer> used = new ArrayList<Integer>(points.length);
  ArrayList<Integer> unused = new ArrayList<Integer>(points.length);
  ArrayList<Float> segLengths = new ArrayList<Float>(points.length);

  // only sort the points that will be drawn
  //float rDrawMax = rMax*rDrawMaxCutoffScale;
  for(int i=0; i<points.length; i++){
    //if (points[i].r<=rDrawMax){
      unused.add(i);
    //}
  }
  // add the initial two points.
  int iu1,iu2;
  iu1 = 0;
  iu2 = unused.size()/2; // somewhere in the middle of the list.
  used.add(unused.get(iu2));
  unused.remove(iu2);
  used.add(unused.get(iu1));
  unused.remove(iu1);
  
  // compute the segment length between them
  int icu1 = used.get(0);
  int icu2 = used.get(1);
  float d0 = sqrt(pow(points[icu2].x-points[icu1].x,2)+pow(points[icu2].y-points[icu1].y,2));
  // save the lengths of each segment.
  segLengths.add(d0);
  segLengths.add(d0);

    
  int iBest;
  float d,dBest;
  
  float dNew;
  float x0,y0;
  int ic0;
  
  int iuu0;
  while(unused.size()>0){
    // pick the point to add. A random index works better than sequential
    // because this spreads out the points
    iuu0 = floor(random(unused.size()));
    ic0 = unused.get(iuu0);
    
    x0 = points[ic0].x;
    y0 = points[ic0].y;
    
    // for each circle that remains unused, find the total added distance that results from insertion
    dBest = (width+height)*(width+height)*4;
    iBest = 0;
    for(int iu=0; iu<used.size(); iu++){
      // check the segment that ENDS at iu.
      iu1 = iu-1;
      if (iu1<0)
        iu1 = used.size()-1;
      iu2 = iu;
      
      icu1 = used.get(iu1);
      icu2 = used.get(iu2);
      
      d0 = segLengths.get(iu);
      //d0 = sqrt(pow(circles[icu2][0]-circles[icu1][0],2)+pow(circles[icu2][1]-circles[icu1][1],2));
      //println(ic0,iu,iu1,segLengths.get(iu)-d0);
      
      // exact:
      dNew = sqrt(pow(x0-points[icu1].x,2)+pow(y0-points[icu1].y,2))+
             sqrt(pow(x0-points[icu2].x,2)+pow(y0-points[icu2].y,2));
      // approx: aim for midpoint of line
      d = dNew-d0; // added distance
      if (d<dBest){
        dBest = d+0;
        iBest = iu+0;
      }
    }
    
    // insert the new point, update the segment lengths.
    iu1 = iBest-1;
    if (iu1<0)
      iu1 = used.size()-1;
    iu2 = iBest;
    icu1 = used.get(iu1);
    icu2 = used.get(iu2);
    d0 =   sqrt(pow(points[ic0].x-points[icu1].x,2)+pow(points[ic0].y-points[icu1].y,2)); // updated length of the first new segment
    dNew = sqrt(pow(points[ic0].x-points[icu2].x,2)+pow(points[ic0].y-points[icu2].y,2)); // length of the second new segment
    //println(d0,dNew);
    segLengths.set(iBest,dNew);
    segLengths.add(iBest,d0);
    
    used.add(iBest,ic0+0);
    unused.remove(iuu0);
  }
  
  float[] xs = new float[points.length+1];
  float[] ys = new float[points.length+1];
  int i2;
  for(int i=0; i<points.length; i++){
    i2 = used.get(i);
    xs[i] = points[i2].x;
    ys[i] = points[i2].y;
  }
  // close the loop
  xs[points.length] = points[used.get(0)].x;
  ys[points.length] = points[used.get(0)].y;

  HTShape[] shapes = new HTShape[1];
  shapes[0] = new PolyLine(xs,ys);
  outputPattern = new Pattern(shapes);
  println("Sorted via loop insertion");
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////
// N-nearest neighbors, done badly

void patternNNearestNeighbors(int nNearest){
  ArrayList<PolyLine> lineSegs = new ArrayList<PolyLine>(points.length*nNearest); // indices of nearest neighbors
  float[] xs,ys;
  xs = new float[2];
  ys = new float[2];
  int[] sortedIndices;
  float[] dataToSort = new float[points.length];
  int[] inds;
  PolyLine newLS;
  for(int i=0; i<points.length; i++){
    xs[0] = points[i].x+0;
    ys[0] = points[i].y+0;
    for(int j=0; j<points.length; j++){
      //v = 
      if(i==j){
        dataToSort[j] = nx*nx+ny*ny;
      }
      else{
        dataToSort[j] = pow(points[i].x-points[j].x,2)+pow(points[i].y-points[j].y,2);
      }
    }
    //int[] inds = {1,2,3};
    sortedIndices = sortedArrayIndices(dataToSort);
    inds = Arrays.copyOfRange(sortedIndices,0,nNearest);

    for(int j=0; j<inds.length; j++){
      xs[1] = points[inds[j]].x+0;
      ys[1] = points[inds[j]].y+0;
      newLS = new PolyLine(xs.clone(),ys.clone());
      if (! lineSegs.contains(newLS)){
        lineSegs.add(newLS);
      }
    }
  }

  PolyLine[] lineSegsTemp = new PolyLine[1];
  //lineSegs2 = lineSegs.toArray(lineSegs2);
  outputPattern = new Pattern(lineSegs.toArray(lineSegsTemp));
  
  println("Inefficient nearest neighbors!");
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////
// single tilted lines
void patternSingleHatched(float dTheta){
  ArrayList<PolyLine> lineSegs = new ArrayList<PolyLine>(points.length); // indices of nearest neighbors
  float[] xs,ys;
  xs = new float[2];
  ys = new float[2];
  float t,x,y,r;
  for(int i=0; i<points.length; i++){
    x = points[i].x;
    y = points[i].y;
    r = points[i].r;
    t = findLocalOrientation(points[i].x,points[i].y)+dTheta;
    xs[0] = x+r*cos(t);
    xs[1] = x-r*cos(t);
    ys[0] = y+r*sin(t);
    ys[1] = y-r*sin(t);
    lineSegs.add(new PolyLine(xs.clone(),ys.clone()));
  }

  PolyLine[] lineSegsTemp = new PolyLine[1];
  //lineSegs2 = lineSegs.toArray(lineSegs2);
  outputPattern = new Pattern(lineSegs.toArray(lineSegsTemp));
  
  println("Pattern: Tilted lines");
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////
// voronoi diagram
// using mesh from https://leebyron.com/mesh/
import megamu.mesh.*; 

void patternVoronoi(int nSmoothIter){
  float t0 = millis();
  println((millis()-t0)/1000.0,"starting voronoi");
  //statusText = "starting voronoi";
  
  ArrayList<PolyLine> lineSegs = new ArrayList<PolyLine>(points.length*10); // each line segment. 
  //println((millis()-t0)/1000.0,"lineSegs empty list made");
  
  float[][] pointsArray = new float[points.length][2];
  for(int i=0; i<points.length; i++){
    pointsArray[i][0]=points[i].x+0;
    pointsArray[i][1]=points[i].y+0;
  }
  Voronoi myVoronoi = new Voronoi( pointsArray );
  
  
  
  if(nSmoothIter==0){
    float[][] myEdges = myVoronoi.getEdges();
    // now save the segments.
    float[] xs = new float[2];
    float[] ys = new float[2];
    PolyLine lineSeg;
    float[] tempLineSeg = new float[4];
    for(int i=0; i<myEdges.length; i++) {
      tempLineSeg = trimLineSeg(myEdges[i]);
      if(tempLineSeg.length>0){
        xs[0] = tempLineSeg[0];
        ys[0] = tempLineSeg[1];
        xs[1] = tempLineSeg[2];
        ys[1] = tempLineSeg[3];
        lineSeg = new PolyLine(xs.clone(),ys.clone());
        // slows things down to include the check on re-use.
        if(! lineSegs.contains(lineSeg)){
          lineSegs.add(lineSeg);
        }
      }
    }
    // now add borders:
    lineSegs.add(new PolyLine(new float[]{0,nx-1},new float[]{0,0}));
    lineSegs.add(new PolyLine(new float[]{nx-1,nx-1},new float[]{0,ny-1}));
    lineSegs.add(new PolyLine(new float[]{nx-1,0},new float[]{ny-1,ny-1}));
    lineSegs.add(new PolyLine(new float[]{0,0},new float[]{ny-1,0}));
  }
  else{ // add a closed loop, 
    MPolygon[] myRegions = myVoronoi.getRegions();
    PolyLine polyTemp;
    float[][] coords;
    float[] xs;
    float[] ys;
    
    for(int i=0; i<myRegions.length; i++)
    {
      // an array of points
      coords = myRegions[i].getCoords();
      int np = coords.length;
      xs =  new float[np];
      ys =  new float[np];
      for(int j=0; j<np; j++){
        xs[j] = coords[j][0]+0;
        ys[j] = coords[j][1]+0;
      }
      
      
      polyTemp = new PolyLine(xs.clone(),ys.clone());
      polyTemp.closed = true;
      for(int s=0; s<nSmoothIter;s++){
        polyTemp.smoothOnce();
      }
      lineSegs.add(polyTemp);
    }
  }
  
  //println((millis()-t0)/1000.0,"voronoi line segs added");
  //statusText = "found voronoi line segments";
  
  PolyLine[] lineSegsTemp = new PolyLine[1];
  //lineSegs2 = lineSegs.toArray(lineSegs2);
  outputPattern = new Pattern(lineSegs.toArray(lineSegsTemp));
  //println((millis()-t0)/1000.0,"copied to output");
  
  println((millis()-t0)/1000.0,"finished voronoi");
  println("Pattern: Voronoi finished.");
  //statusText = "finished voronoi";
  println();
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Delaunay triangulation
// using mesh from https://leebyron.com/mesh/
void patternDelaunay(){
  float t0 = millis();
  println((millis()-t0)/1000.0,"starting voronoi");
  //statusText = "starting voronoi";
  
  ArrayList<PolyLine> lineSegs = new ArrayList<PolyLine>(points.length*10); // each line segment. 
  //println((millis()-t0)/1000.0,"lineSegs empty list made");
  
  float[][] pointsArray = new float[points.length][2];
  for(int i=0; i<points.length; i++){
    pointsArray[i][0]=points[i].x+0;
    pointsArray[i][1]=points[i].y+0;
  }
  Delaunay myDelaunay= new Delaunay( pointsArray );
  
  
  float[][] myEdges = myDelaunay.getEdges();
  
  // now save the segments.
  float[] xs = new float[2];
  float[] ys = new float[2];
  PolyLine lineSeg;
  float[] tempLineSeg = new float[4];
  for(int i=0; i<myEdges.length; i++) {
    tempLineSeg = trimLineSeg(myEdges[i]);
    if(tempLineSeg.length>0){
      xs[0] = tempLineSeg[0];
      ys[0] = tempLineSeg[1];
      xs[1] = tempLineSeg[2];
      ys[1] = tempLineSeg[3];
      lineSeg = new PolyLine(xs.clone(),ys.clone());
      // slows things down to include the check on re-use.
      if(! lineSegs.contains(lineSeg)){
        lineSegs.add(lineSeg);
      }
    }
  }

  
  //println((millis()-t0)/1000.0,"voronoi line segs added");
  //statusText = "found Delaunay line segments";
  
  PolyLine[] lineSegsTemp = new PolyLine[1];
  //lineSegs2 = lineSegs.toArray(lineSegs2);
  outputPattern = new Pattern(lineSegs.toArray(lineSegsTemp));
  //println((millis()-t0)/1000.0,"copied to output");
  
  println((millis()-t0)/1000.0,"finished Delaunay");
  //statusText = "finished Delaunay";
  println();
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////
// N-nearest neighbors from the Delaunay triangulation
// using mesh from https://leebyron.com/mesh/
void patternDelaunayNN(int nNearest){
  float t0 = millis();
  println((millis()-t0)/1000.0,"starting voronoi");
  //statusText = "starting voronoi";
  
  ArrayList<PolyLine> lineSegs = new ArrayList<PolyLine>(points.length*10); // each line segment. 
  //println((millis()-t0)/1000.0,"lineSegs empty list made");
  
  float[][] pointsArray = new float[points.length][2];
  for(int i=0; i<points.length; i++){
    pointsArray[i][0]=points[i].x+0;
    pointsArray[i][1]=points[i].y+0;
  }
  Delaunay myDelaunay= new Delaunay( pointsArray );
  
  int[] neighbors;
  float[] dists;
  int[] sortedIndices; 
  PolyLine lineSeg;
  float[] xs = new float[2];
  float[] ys = new float[2];
  int nnMax;
  int i2;
  for(int i=0; i<points.length; i++){
    xs[0] = points[i].x;
    ys[0] = points[i].y;
    neighbors = myDelaunay.getLinked(i);
    
    
    nnMax = neighbors.length;
    
    // the initialized matrix puts zeros where it lacks links
    // so we need to figure out how long the array should actually be.
    if(neighbors[nnMax-1] ==0){ // check backwards
      for(int j=nnMax-2; j>=0; j--){
        if(neighbors[j]!=0){
          nnMax = j+1;
          break;
        }
      }
    }
    
    
    // find distances to these connected neighbors
    dists = new float[nnMax];
    for(int j=0; j<nnMax; j++){
      dists[j] = pow(xs[0]-points[neighbors[j]].x,2)+
                 pow(ys[0]-points[neighbors[j]].y,2);
    }
    // sort the distances.
    sortedIndices = sortedArrayIndices(dists);
    
    // use the closest ones 
    for(int j=0; j<min(nNearest,nnMax); j++){
      i2 = neighbors[sortedIndices[j]];
      xs[1] = points[i2].x;
      ys[1] = points[i2].y;
      lineSeg = new PolyLine(xs.clone(),ys.clone());
      // slows things down to include the check on re-use.
      if(! lineSegs.contains(lineSeg)){
        lineSegs.add(lineSeg);
      }
    }
  }
  
  
  //println((millis()-t0)/1000.0,"voronoi line segs added");
  //statusText = "found Delaunay line segments";
  
  PolyLine[] lineSegsTemp = new PolyLine[1];
  //lineSegs2 = lineSegs.toArray(lineSegs2);
  outputPattern = new Pattern(lineSegs.toArray(lineSegsTemp));
  //println((millis()-t0)/1000.0,"copied to output");
  
  println((millis()-t0)/1000.0,"finished Delaunay nearest neighbor");
  //statusText = "finished Delaunay";
  println();
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Minimum spanning tree from the Delaunay triangulation
// using mesh from https://leebyron.com/mesh/
void patternDelaunayMST(){
  // make the delaunay triangulation
  int np = points.length;
  float[][] pointsArray = new float[np][2];

  for(int i=0; i<np; i++){
    pointsArray[i][0]=points[i].x+0;
    pointsArray[i][1]=points[i].y+0;
  }
  Delaunay myDelaunay= new Delaunay( pointsArray );

  boolean[] visited = new boolean[np];
  int[] parents = new int[np];
  float[] keys = new float[np];
  for(int i=0; i<np; i++){
    keys[i] = Float.MAX_VALUE/2;
  }
  
  int iInit = round(random(0,np-1));
  println("first point:",iInit);
  keys[iInit] = 0; // first value;
  parents[iInit] = iInit;
  
  
  ArrayList<PolyLine> lineSegs = new ArrayList<PolyLine>(points.length*2); // each line segment.
  int[] neighbors;
  PolyLine lineSeg;
  float[] xs = new float[2];
  float[] ys = new float[2];
  int i0,i1,i2;
  int jAL,j2;
  float d;
  
  // remaining indices to check
  ArrayList<Integer> unvisited = new ArrayList<Integer>(np); 
  for(int i=0; i<np; i++){
    unvisited.add(i);
  }
  
  for(int iIter=0; iIter<np; iIter++){
     // find the index of the minimum key (unvisited)
    i1=0;
    jAL = 0;
    float keyMin = Float.MAX_VALUE;
    for(int j=0; j<unvisited.size(); j++){
      j2 = unvisited.get(j);
      if(keys[j2]<=keyMin) {
        jAL = j+0;
        i1 = j2+0;
        keyMin = keys[j2]+0;
      }
    }
    // update the chosen point
    visited[i1] = true;
    unvisited.remove(jAL);
    
    // if you're beyond the first iteration, save the segment
    if(iIter>0){
      i0 = parents[i1];
      xs[0] = pointsArray[i0][0];
      ys[0] = pointsArray[i0][1];
      xs[1] = pointsArray[i1][0];
      ys[1] = pointsArray[i1][1];
      lineSeg = new PolyLine(xs.clone(),ys.clone());
      lineSegs.add(lineSeg);
    }

    // find its neighbors
    neighbors = myDelaunay.getLinked(i1);
    // find distances to these connected neighbors
    // and update their keys
    d = 0;
    for(int j=0; j<neighbors.length; j++){
      i2 = neighbors[j];
      if(!visited[i2]){
        d = pow(pointsArray[i1][0]-pointsArray[i2][0],2)+
            pow(pointsArray[i1][1]-pointsArray[i2][1],2);
        if(d<keys[i2]){
          parents[i2] = i1+0;
          keys[i2] = d+0;
        }
      }
    }
  }
  
  PolyLine[] lineSegsTemp = new PolyLine[1];
  //lineSegs2 = lineSegs.toArray(lineSegs2);
  outputPattern = new Pattern(lineSegs.toArray(lineSegsTemp));
  //println((millis()-t0)/1000.0,"copied to output");
  
  //statusText = "finished Delaunay-Prim MST";
  println();
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Hilbert-indexing
void patternHilbertSort(float cellWidth){
  
  float[] xs =new float[points.length];
  float[] ys =new float[points.length];
  for(int i=0; i<points.length; i++){;
    xs[i] = points[i].x;
    ys[i] = points[i].y;
  }
  int[] sortedIndices = hilbertSort(xs, ys, cellWidth);
  int i2;
  for(int i=0; i<points.length; i++){
    i2 = sortedIndices[i];
    xs[i] = points[i2].x;
    ys[i] = points[i2].y;
  }
  
  HTShape[] shapes = new HTShape[1];
  shapes[0] = new PolyLine(xs,ys);
  outputPattern = new Pattern(shapes);
  
  println("Sorted hilbert-wise");
}
