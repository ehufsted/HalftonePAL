/////////////////////////////////////////////////////////////////////////////////////////////////////////
/* Outline

These functions fill in the points[] with Circles. 
Ideally, they should be able to act as halftoning methods, with just their central points. 

- pointsWhiteNoiseGrid:
- pointsWhiteNoiseHT:
- pointsPhylloSpiral:
- pointsGrid:
- pointsErrorDiffusion1D:
- pointsErrorDiffusion2D:
- pointsCirclePackLazy:
- pointsQuadtree:
- pointsCirclePackClimb:

For testing:
- pointsWhiteNoise:
- pointsPhylloSpiral:
- pointsGrid:

*/

// need to use point distributions that act like pointwise halftoning.
void generatePoints(){
  int t0 = millis();
  switch(pointsChoice){
    case 0:
      pointsCirclePackClimb(rMin*0.6);
      break;
    case 1:
      pointsCirclePackLazy(3);
      break;
    case 2:
      pointsWhiteNoiseHT(rMin);
      break;
    case 3:
      pointsQuadtree();
      break;
    case 4:
      pointsErrorDiffusion1D(false,rMin*2);
      break;
    case 5:
      pointsErrorDiffusion2D(false,rMin*2);
      break;
    case 6:
      pointsWhiteNoiseGrid(false,rMin*2);
      break;  
    case 7:
      pointsErrorDiffusion1D(true,rMin*2);
      break;
    case 8:
      pointsErrorDiffusion2D(true,rMin*2);
      break;
    case 9:
      pointsWhiteNoiseGrid(true,rMin*2);
      break;  
      
    default:
      pointsCirclePackClimb(rMin*0.6);
      break;
  }
  
  // only for testing:
  //pointsWhiteNoise(10000);
  //pointsPhylloSpiral(1000,2*rMin);
  //pointsGrid(2);
  
  continueOptimizing = false;
  ((Toggle)(cp5.get("toggleContinueOptimizing"))).setValue(false);
  sortPoints();
  println("points sorted");
  
  int t1 = millis();
  println(points.length," points found in "+(t1-t0)/1000.0+" s");
  println();
}


// do an initial Hilbert sort to have a decent path between points
void sortPoints(){
  float[] xs =new float[points.length];
  float[] ys =new float[points.length];
  float[] rs =new float[points.length];
  for(int i=0; i<points.length; i++){;
    xs[i] = points[i].x;
    ys[i] = points[i].y;
  }
  float cellWidth = rMin*2;
  int[] sortedIndices = hilbertSort(xs, ys, cellWidth);
  int i2;
  for(int i=0; i<points.length; i++){
    i2 = sortedIndices[i];
    xs[i] = points[i2].x+0;
    ys[i] = points[i2].y+0;
    rs[i] = points[i2].r+0;
  }
  for(int i=0; i<points.length; i++){
    i2 = sortedIndices[i];
    points[i].x = xs[i];
    points[i].y = ys[i];
    points[i].r = rs[i];
  }
  
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// White noise dithering, on a hex/square grid
void pointsWhiteNoiseGrid(boolean useHex,float gridSize){
  float dxCol = gridSize;
  float dyRow = gridSize;
  if(useHex)
    dyRow = gridSize*sqrt(3)/2;
  
  int nyRows = floor((ny-gridSize)/dyRow);
  int nxCols = floor((nx-gridSize)/dxCol);
  int ixIm,iyIm;
  float x,y,k;
  
  ArrayList<Circle> circles = new ArrayList<Circle>();
  
  for (int iy=0; iy<=nyRows; iy++) {
    y = gridSize/2+iy*dyRow;
    for (int ix=0; ix<=nxCols; ix++) {
      x = gridSize/2+ix*dxCol;
      if ((iy%2==1) && useHex)
        x+= gridSize/2;
      if(x<nx){
        ixIm = constrain(round(x),0,nx-1);
        iyIm = constrain(round(y),0,ny-1);
        k = 1-brightness(pic.pixels[ixIm+iyIm*nx])/255.0;
        if (blackBackground){
          k = 1-k;
        }
        if (k>random(1)){
          circles.add(new Circle(x,y,gridSize/2,k));
        }
      }
    }
  }
  points = new Circle[1];
  points = circles.toArray(points);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// pointwise white noise for filled halftoning. Could get expensive.
void pointsWhiteNoiseHT(float r){
  ArrayList<Circle> circles = new ArrayList<Circle>();
  float k,p;
  for (int iy=0; iy<ny; iy++) {
    for (int ix=0; ix<nx; ix++) {
      k = 1-brightness(pic.pixels[ix+iy*nx])/255.0;
      if (blackBackground){
        k = 1-k;
      }
      k = k*0.99; // don't let it compute log(0)
      p = -log(1-k)*1*1/(PI*r*r);
      p = constrain(p,0,1/(PI*r*r));// limit p, keep from using too many points.

      if (p>random(1)){
        circles.add(new Circle(ix+(random(1)*2-1)*0.25,iy+(random(1)*2-1)*0.25,r,k));
      }
    }
  }
  points = new Circle[1];
  points = circles.toArray(points);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// pointwise white noise, given number of points.
void pointsWhiteNoise(int np){
  ArrayList<Circle> circles = new ArrayList<Circle>();
  float k;
  float x,y,r;
  for (int i=0; i<np; i++) {
    x = random(1)*nx;
    y = random(1)*ny;
    k = 1-brightness(pic.pixels[floor(x)+floor(y)*nx])/255.0; 
    r = rMin;
    if (blackBackground){
      k = 1-k;
    }
    circles.add(new Circle(x,y,r,k));
  }
  points = new Circle[1];
  points = circles.toArray(points);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// points laid out as a phyllotactic spiral
void pointsPhylloSpiral(int np,float rCirc){
  ArrayList<Circle> circles = new ArrayList<Circle>();
  float dth = PI*(3-sqrt(5));
  float k;
  float x,y,r,th;
  for (int i=1; i<np; i++) {
    th = i*dth;
    r = rCirc*sqrt(i);
    x = nx/2+r*cos(th);
    y = ny/2+r*sin(th);
    k = 0;
    if(! checkOutOfBounds(x,y)){
      circles.add(new Circle(x,y,rCirc,k));
    }
  }
  
  points = new Circle[1];
  points = circles.toArray(points);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// uniform square grid.
void pointsGrid(float rCirc){
  ArrayList<Circle> circles = new ArrayList<Circle>();
  float k;
  float x,y;
  int nxp = floor(nx/rCirc);
  int nyp = floor(ny/rCirc);
  for (int i=0; i<nyp; i++) {
    for (int j=0; j<nxp; j++) {
      x = j*rCirc;
      y = i*rCirc;
      k = 0;
      circles.add(new Circle(x,y,rCirc,k));
    }
  }
  
  points = new Circle[1];
  points = circles.toArray(points);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// 1D error diffusion
void pointsErrorDiffusion1D(boolean useHex, float gridSize){
  float dxCol = gridSize;
  float dyRow = gridSize;
  if(useHex)
    dyRow = gridSize*sqrt(3)/2;
    
  int nyRows = floor((ny-gridSize)/dyRow);
  int nxCols = floor((nx-gridSize)/dxCol);
  int ixIm,iyIm;
  float x,y,k;
  float err = 0;
  ArrayList<Circle> circles = new ArrayList<Circle>();
  
  for (int iy=0; iy<=nyRows; iy++) {
    y = gridSize/2+iy*dyRow;
    for (int ix=0; ix<=nxCols; ix++) {
      x = gridSize/2+ix*dxCol;
      if (useHex && (iy%2==1))
        x+= gridSize/2;
      if(x<nx){
        ixIm = constrain(round(x),0,nx-1);
        iyIm = constrain(round(y),0,ny-1);
        k = 1-brightness(pic.pixels[ixIm+iyIm*nx])/255.0;
        if (blackBackground){
          k = 1-k;
        }
        err +=k;
        if (err>0.5){
          circles.add(new Circle(x,y,gridSize/2,k));
          err--;
        }
      }
    }
  }
  points = new Circle[1];
  points = circles.toArray(points);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// 2D error diffusion
void pointsErrorDiffusion2D(boolean useHex, float gridSize){
  float dxCol = gridSize;
  float dyRow = gridSize;
  if(useHex)
    dyRow = gridSize*sqrt(3)/2;
    
  int nyRows = floor((ny-gridSize)/dyRow);
  int nxCols = floor((nx-gridSize)/dxCol);
  int ixIm,iyIm;
  float x,y,k;
  float[][] K = new float[nyRows+1][nxCols+1];
  
  
  float err = 0;
  ArrayList<Circle> circles = new ArrayList<Circle>();
  
  for (int iy=0; iy<=nyRows; iy++) {
    y = gridSize/2+iy*dyRow;
    for (int ix=0; ix<=nxCols; ix++) {
      x = gridSize/2+ix*dxCol;
      if (useHex && (iy%2==1))
        x+= gridSize/2;
      if(x<nx){
        ixIm = constrain(round(x),0,nx-1);
        iyIm = constrain(round(y),0,ny-1);
        k = 1-brightness(pic.pixels[ixIm+iyIm*nx])/255.0;
        
        if (blackBackground){
          k = 1-k;
        }
        K[iy][ix] += k;
        
        err +=K[iy][ix];
        if (err>0.5){
          circles.add(new Circle(x,y,gridSize/2,k));
          err--;
        }
        // redistribute error
        if (ix<nxCols-1)
          K[iy][ix+1] += err*7.0/16;
        if ((ix>0) && (iy<nyRows))
          K[iy+1][ix-1] += err*3.0/16;
        if (iy<nyRows)
          K[iy+1][ix] += err*5.0/16;
        if ((ix<nxCols) && (iy<nyRows))
          K[iy+1][ix+1] += err*1.0/16;
        err = 0;
      }
    }
  }
  points = new Circle[1];
  points = circles.toArray(points);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// greedy circle packing
void pointsCirclePackLazy(float npMultFactor){
  int np = round(nx*ny/(PI*rMin*rMin)*npMultFactor);
  ArrayList<Circle> unused = new ArrayList<Circle>();
  float k;
  float x,y,r;
  float dWall;
  float q = rMax/rMin;
  for (int i=0; i<np; i++) {
    x = random(1)*nx;
    //y = random(1)*ny;
    y = map(i,0,np-1,0,ny-1); // to work from top to bottom
    k = 1-brightness(pic.pixels[floor(x)+floor(y)*nx])/255.0; 
    if (blackBackground){
      k = 1-k;
    }
    r = q*rMin/sqrt(1+k*(q*q-1));
    dWall = min(x,y, min(nx-x,ny-y));
    if(dWall>r){
      unused.add(new Circle(x,y,r,k));
    }
  }
  

  ArrayList<Circle> used = new ArrayList<Circle>();
  int n;
  float d;
  float x0,y0,r0;
  while(unused.size()>0){
    used.add(unused.get(0));
    x0 = unused.get(0).x;
    y0 = unused.get(0).y;
    r0 = unused.get(0).r;
    unused.remove(0);
    
    n = unused.size();
    for(int i=n-1; i>=0; i--){
      d = pow(x0-unused.get(i).x,2)+pow(y0-unused.get(i).y,2)-pow(r0+unused.get(i).r,2);
      if(d<0){
        unused.remove(i);
      }
    }
  }

  points = new Circle[1];
  points = used.toArray(points);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// quadtree circles. Ignores rMax.
void pointsQuadtree(){
  // rescale the image to be in terms of 2*rmin
  int nx2 = round(nx/(2*rMin));
  int ny2 = round(ny/(2*rMin));
  PImage pic2 = pic.copy();
  pic2.resize(nx2,ny2);
  pic2.loadPixels();
  
  
  
  int maxPow2 = ceil(log(max(nx2,ny2))/log(2));
  int L = int(pow(2,maxPow2));
  float[][] K = new float[L][L];
  float Ksum = 0;
  for(int ix=0; ix<nx2; ix++){
    for(int iy=0; iy<ny2; iy++){
      K[iy][ix] = 1-brightness(pic2.pixels[iy*nx2+ix])/255.0;
      if(blackBackground)
        K[iy][ix] = 1-K[iy][ix];
      Ksum+=K[iy][ix];
    }
  }
  // rescale to have unit dots
  float scaleK = round(Ksum)/Ksum;
  for(int ix=0; ix<nx2; ix++){
    for(int iy=0; iy<ny2; iy++){
      K[iy][ix] *= scaleK;
    }
  }
  Ksum = Ksum*scaleK;
  //println("Estimated number of circles", Ksum);
  
  ArrayList<int[]> unfinished = new ArrayList<int[]>();
  ArrayList<int[]> finished = new ArrayList<int[]>();
  // [x1,x2,y1,y2]. The region is ( x1 <= x < x2 ), etc
  int[] bound = {0,L,0,L};
  unfinished.add(bound.clone());
  int[] newBound = new int[4];
  
  
  int x1,x2,y1;
  float[][] ks = new float[2][2];
  int[][] Ns = new int[2][2];
  int xa,xb,ya,yb;
  int LHere;
  float[] errs;
  int nExtra;
  
  while(unfinished.size()>0){
    bound = unfinished.get(0);
    unfinished.remove(0);
    x1 = bound[0];
    x2 = bound[1];
    y1 = bound[2];
    //y2 = bound[3];
    LHere = x2-x1;
    
    // find the total darkness in each subdivision
    for(int i=0; i<2; i++){
      ya = y1+LHere/2*i;
      yb = y1+LHere/2+ LHere/2*i;
      for(int j=0; j<2; j++){
        xa = x1+LHere/2*j;
        xb = x1+LHere/2+ LHere/2*j;
        ks[i][j] = arraySum(K, ya,yb, xa,xb)+0;
        Ns[i][j] = floor(ks[i][j]);
      }
    }
    
    // only keep an integer amount of darkness in each section.
    //redistribute rounding errors
    errs = new float[4];
    errs[0] = ks[0][0]-Ns[0][0];
    errs[1] = ks[1][0]-Ns[1][0];
    errs[2] = ks[0][1]-Ns[0][1];
    errs[3] = ks[1][1]-Ns[1][1];
    nExtra = round(errs[0]+errs[1]+errs[2]+errs[3]); 
    if(nExtra>0){
      int[] sortedIndices = sortedArrayIndices(errs);
      int[] dns = new int[4];
      // want to give it to the divisions with the MOST error
      for(int i=0;i<nExtra;i++){
        dns[sortedIndices[3-i]] = 1; 
      }
      Ns[0][0] += dns[0];
      Ns[1][0] += dns[1];
      Ns[0][1] += dns[2];
      Ns[1][1] += dns[3];
    }
  
    // rescale darkness to match the numbers in each division
    for(int i=0; i<2; i++){
      ya = y1+LHere/2*i;
      yb = y1+LHere/2+ LHere/2*i;
      for(int j=0; j<2; j++){
        xa = x1+LHere/2*j;
        xb = x1+LHere/2+ LHere/2*j;
        // rescale to remove error
        for(int i2=ya; i2<yb; i2++)
          for(int j2=xa; j2<xb; j2++)
            K[i2][j2] *= Ns[i][j]/ks[i][j]; 
        
        // store new point if needed.
        if (Ns[i][j]>0){
          newBound[0] = xa;
          newBound[1] = xb;
          newBound[2] = ya;
          newBound[3] = yb;
          if((Ns[i][j]==1) && (yb<ny2) && (xb<nx2))
            finished.add(newBound.clone());
          else
            unfinished.add(newBound.clone());
        }
      }
    }
  }
   
  
  // return to the original sizes, save circles
  float scaleSize = nx*1.0/nx2;
  points = new Circle[finished.size()];
  float x,y,r,k;
  int ix,iy;
  for(int i=0; i<points.length; i++){
    x = (finished.get(i)[0]+finished.get(i)[1])/2.0;
    y = (finished.get(i)[2]+finished.get(i)[3])/2.0;
    r = (finished.get(i)[1]-finished.get(i)[0])/2.0;
    ix = int(constrain(x,0,nx-1));
    iy = int(constrain(y,0,ny-1));
    k = brightness(pic.pixels[iy*nx+ix])/255.0;
    points[i] = new Circle(x*scaleSize,y*scaleSize,r*scaleSize,k);
  }

  println("Quadtree points found");
}

float arraySum(float[][] array, int i1, int i2, int j1, int j2){
  float s = 0;
  for(int i=i1; i<i2; i++)
    for(int j=j1; j<j2; j++)
      s+=array[i][j];
  return s;
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////
// circle packing, climbing in y
void pointsCirclePackClimb(float gridSpacing){
  
  ArrayList<Circle> activeCircs = new ArrayList<Circle>();
  ArrayList<Circle> finishedCircs = new ArrayList<Circle>();
  
  int nx2 = round(nx/gridSpacing);
  int ny2 = round(ny/gridSpacing);
  PImage pic2 = pic.copy();
  pic2.resize(nx2,ny2);
  pic2.loadPixels();
  
 
  float rMin2 = rMin*nx2/nx;
  float rMax2 = rMax*nx2/nx;
  float[][] D = new float[ny2][nx2];
  float[][] R = new float[ny2][nx2];
  float[][] K = new float[ny2][nx2];
  int[][] I = new int[ny2][nx2]; // index map
  
  float q = rMax2/rMin2;
  float k;
  
  for(int ix=0; ix<nx2; ix++){
    for(int iy=0; iy<ny2; iy++){
      k = 1-brightness(pic2.pixels[iy*nx2+ix])/255.0;
      if(blackBackground)
        k = 1-k; 
      
      K[iy][ix] = k;
      D[iy][ix] = min(ix,iy, min(nx2-ix,ny2-iy));
      if(useAreaScaling){
        R[iy][ix] = q*rMin2/sqrt(1+k*(q*q-1));
      }
      else{
        R[iy][ix] = q*rMin2/(1+k*(q-1));
      }
      I[iy][ix] = -1;
    }
  }
  
  int ixa,ixb;
  int icTemp;
  float[] dTemp;
  float x0,y0,r0,d,dy;
  for(int iy=0; iy<ny2; iy++){
    // for each active circle, compute its distance to the points in this row
    // and update D, I
    for(int ic=0; ic<activeCircs.size(); ic++){
      dTemp = D[iy].clone();
      x0 = activeCircs.get(ic).x;
      y0 = activeCircs.get(ic).y;
      r0 = activeCircs.get(ic).r;
      ixa = floor(constrain(x0-(r0+rMax),0,nx2));
      ixb = ceil(constrain(x0+(r0+rMax),0,nx2));
      for (int ix=ixa; ix<ixb; ix++) {
        d = sqrt( pow( (x0-ix) ,2) + pow( (y0-iy) ,2) )-r0;
        if(d<D[iy][ix]){
          D[iy][ix] = d+0;
          I[iy][ix] = ic+0;
        }
      }
    }
    
    // scan across
    for(int ix=0; ix<nx2; ix++){
      // find the first point with (D-R)>0, add a circle.
      // update D,I
      if((D[iy][ix]-R[iy][ix])>0){
        //activeCircs.add(new Circle(
        x0 = ix+0;
        y0 = iy+0;
        r0 = R[iy][ix]+0;
        
        // shift y0 a bit, for a better fit:
        dy = -(D[iy][ix]-R[iy][ix])/(D[iy][ix]-D[iy-1][ix]);
        dy = constrain(dy,-rMin,0);
        y0 +=dy;
        
        activeCircs.add(new Circle(x0,y0,r0,K[iy][ix]));
        icTemp = activeCircs.size()-1;
        ixa = floor(constrain(x0-(r0+rMax),0,nx2));
        ixb = ceil(constrain(x0+(r0+rMax),0,nx2));
        // update D,I
        for (int ixTemp=ixa; ixTemp<ixb; ixTemp++) {
          d = sqrt( pow( (x0-ixTemp) ,2) + pow( (y0-iy) ,2) )-r0;
          if(d<D[iy][ixTemp]){
            D[iy][ixTemp] = d+0;
            I[iy][ixTemp] = icTemp+0;
          }
        }
      }
    }
    
    // check for inactive circles
    boolean[] active = new boolean[activeCircs.size()];
    for(int ix=0; ix<nx2; ix++){
      icTemp = I[iy][ix];
      if(icTemp>-1)
        if(!active[icTemp])
          active[icTemp] = true;
    }
    // remove inactive circles
    for(int ic=activeCircs.size()-1; ic>=0; ic--){
      if(!active[ic]){
        finishedCircs.add(activeCircs.get(ic));
        activeCircs.remove(ic);
      }
    }
    //println(iy,activeCircs.size(),finishedCircs.size());
  }
  
  
  // any remaining active circles must be removed
  finishedCircs.addAll(activeCircs);
  
  // and rescale
  float scaleDist = nx*1.0/nx2;
  // rescale the circles
  for(int i=0; i<finishedCircs.size(); i++){
    finishedCircs.get(i).x *= scaleDist;
    finishedCircs.get(i).y *= scaleDist;
    finishedCircs.get(i).r *= scaleDist;
  }
  
  points = new Circle[1];
  points = finishedCircs.toArray(points);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// circle packing, climbing in y
