/*
Various functions:
- checkOutOfBounds
- trimLineSeg
- sortedArrayIndices
- hilbertSort
- hilbertCurve
- reverseArray
- findLocalOrientation
*/

boolean checkOutOfBounds(float x,float y){
  // true if out of bounds.
  return (x<0 || x>=nx || y<0 || y>=ny);
}

float[] trimLineSeg(float[] lineSeg){ // lineSeg has {x1,y1,x2,y2}
  // this is simplified by the fact that at least one point is interior.
  boolean oob1 = checkOutOfBounds(lineSeg[0],lineSeg[1]);
  boolean oob2 = checkOutOfBounds(lineSeg[2],lineSeg[3]);
  
  if(oob1 && oob2){ // both out of bounds -> discard.
    return new float[0];
  }
  if(!oob1 && !oob2){ // both in-bounds -> retain original
    return lineSeg.clone();
  }
  
  // otherwise, we need to trim it.
  float[] lineSeg2 = lineSeg.clone();
  // rearrange to have the in-bounds point first.
  if(oob1 && !oob2){ // need to move oob1 toward oob2;
    lineSeg2[0] = lineSeg[2]+0;
    lineSeg2[1] = lineSeg[3]+0;
    lineSeg2[2] = lineSeg[0]+0;
    lineSeg2[3] = lineSeg[1]+0;
  }
  
  float x1,y1,x2,y2;
  x1 = lineSeg2[0]+0;
  y1 = lineSeg2[1]+0;
  x2 = lineSeg2[2]+0;
  y2 = lineSeg2[3]+0;
  
  // test the four edges
  float[] sVals = {-1,-1,-1,-1};
  if(abs(x2-x1)>1e-6){
    sVals[0] = (x1-0)/(x1-x2); // left
    sVals[1] = (x1-(nx-1))/(x1-x2); // right
  }
  if(abs(y2-y1)>1e-6){
    sVals[2] = (y1-0)/(y1-y2); // top
    sVals[3] = (y1-(ny-1))/(y1-y2); // bottom
  }

  // keep the closest
  float sMin = Float.MAX_VALUE;
  for(int i=0; i<4; i++){
    if(sVals[i]>=0 && sVals[i]<=1 && sVals[i]<sMin){
      sMin = sVals[i];
    }
  }

  lineSeg2[2] = x1+sMin*(x2-x1); // update x2
  lineSeg2[3] = y1+sMin*(y2-y1); // update y2
  
  return lineSeg2;
}


/////////////
// necessary stuff for sorting
// create a comparable object for sorting a 2D array, retaining indices
import java.util.Comparator;
import java.util.Arrays;
class sortableData implements Comparable{
  int index;
  float value;
  sortableData(int i, float v){
    index = i;
    value = v;
  }
  int compareTo(Object obj){
    sortableData obj2 = (sortableData) obj; // need to cast it as the right datatype
    return int(Math.signum(value-obj2.value));
  }
}


int[] sortedArrayIndices(float[] data){
  sortableData[] pathData = new sortableData[data.length];
  for(int i=0; i<data.length; i++){
    pathData[i] = new sortableData(i,data[i]+0); 
  }
  Arrays.sort(pathData);
  
  int[] sortedIndices = new int[data.length];
  for(int i=0; i<data.length; i++){
    sortedIndices[i] = pathData[i].index; 
  }
  return sortedIndices;
}


///////////////////////////////////////////////////////////////////////
// make a Hilbert curve
int[][] hilbertCurve(int n){
  int[][] H = new int[1][1];
  for(int i=0;i<n;i++){
    H = hilbertRep(H);
  }
  return H;
}
int[][] hilbertRep(int[][] H0){
  int nx = H0.length;
  int np = nx*nx;
  int[][] H2 = new int[2*nx][2*nx];
  for(int i=0; i<nx; i++){
    for(int j=0; j<nx; j++){
      H2[i][j] = H0[j][i]+0; // bottom left
      H2[i+nx][j] = H0[i][j]+np; // top-left
      H2[i+nx][j+nx] = H0[i][j]+np*2; //top-right
      H2[i][j+nx] = H0[nx-j-1][nx-i-1]+np*3; //bottom-right
    }
  }
  return H2;
}

int[] hilbertSort(float[] xs, float[] ys, float cellWidth){
  int wx = ceil(max(nx*1.0/cellWidth,ny*1.0/cellWidth));
  int hilbertOrder = ceil(log(wx)/log(2));
  
  int[][] H = hilbertCurve(hilbertOrder);
  int nxH = H.length;
  println("hilbert iterations: "+hilbertOrder+" -> width:"+nxH); 
  
  int np = points.length;
  float[] hIndex = new float[np];
  int x0, y0;
  for(int i=0; i<np; i++){
    x0 = floor(map(xs[i],0,max(nx,ny),0,nxH));
    y0 = floor(map(ys[i],0,max(nx,ny),0,nxH));
    hIndex[i] = H[y0][x0]+0; 
  }
  
  return sortedArrayIndices(hIndex);
}


float[] reverseArray(float[] a){
  float v;
  int n = a.length;
  for(int i=0; i<n/2; i++){
    v = a[i];
    a[i] = a[n-i-1];
    a[n-i-1] = v;
  }
  return a;
}

///////////////////////////////////////////////////////////////////////
// find the local image orientation
float findLocalOrientation(float x0, float y0){
  int x = constrain(round(x0),1,nx-2);
  int y = constrain(round(y0),1,ny-2);
  float dx = brightness(pic.pixels[(x+1)+(y-1)*nx])-brightness(pic.pixels[(x-1)+(y-1)*nx])
            +brightness(pic.pixels[(x+1)+(y  )*nx])-brightness(pic.pixels[(x-1)+(y  )*nx])
            +brightness(pic.pixels[(x+1)+(y+1)*nx])-brightness(pic.pixels[(x-1)+(y+1)*nx]);
  float dy = brightness(pic.pixels[(x-1)+(y+1)*nx])-brightness(pic.pixels[(x-1)+(y-1)*nx])
            +brightness(pic.pixels[(x  )+(y+1)*nx])-brightness(pic.pixels[(x  )+(y-1)*nx])
            +brightness(pic.pixels[(x+1)+(y+1)*nx])-brightness(pic.pixels[(x+1)+(y-1)*nx]);
  return atan2(dy,dx);
}
