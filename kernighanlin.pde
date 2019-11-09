// Kernighan-Lin pathfinding with K means clustering demo with HSV coloring
// 2019-11-09 dan@marginallyclever.com
// CC-BY-NC-SA

//https://en.wikipedia.org/wiki/Kernighan%E2%80%93Lin_algorithm


// CONSTANTS
final int NUM_POINTS = 5000;
final int NUM_CLUSTERS = 20;


// STRUCTURES
class Point2D {
  public float x,y;
  int cluster;
  
  Point2D(float xx,float yy) {
    x=xx;
    y=yy;
  }
}


// GLOBALS
Point2D [] points;
Point2D [] clusters;
float r,g,b;  // cluster color;
int mode;


boolean KLfirst=true;
int [] KLindex;


// METHODS
void setup() {
  size(800,800);
  
  points = new Point2D[NUM_POINTS];
  for(int i=0;i<points.length;++i) {
    points[i] = new Point2D(random(width),random(height));
  }

  clusters = new Point2D[NUM_CLUSTERS];
  for(int j=0;j<clusters.length;++j) {
    clusters[j] = new Point2D(random(width),random(height));
  }
  
  mode=0;
}


// Give j [0....NUM_CLUSTERS-1]
// sets globals {r,g,b} to a rainbow color.
void clusterColor(int j) {
  float v = (float)(j+1) / (float)NUM_CLUSTERS; // (0...1]

  if(false) {
    // naive
    long c = (long)(v*(float)0xffffff);
    r = (c>>16)&0xff;
    g = (c>> 8)&0xff;
    b = (c    )&0xff;
  } else {
    // index as hsv to rgb
    // https://en.wikipedia.org/wiki/HSL_and_HSV#HSV_to_RGB
    // Assume Hue=v/360, saturation=1, value=1.
    float C = 1;// C=V*S
    float H = v*6;
    float X = C * (1-abs((H % 2) - 1));
         if(H<1) { r=C; g=X; b=0; }
    else if(H<2) { r=X; g=C; b=0; }
    else if(H<3) { r=0; g=C; b=X; }
    else if(H<4) { r=0; g=X; b=C; }
    else if(H<5) { r=X; g=0; b=C; }
    else         { r=C; g=0; b=X; }  // H<6
    r*=255;
    g*=255;
    b*=255;
  }
}


void draw() {
  switch(mode) {
    case 0: kmeans();  break;
    case 1: KernighanLin();  break;
    case 2: 
  }
}


// swap any two points in the sequence.  Is the sequence shorter?  Then keep the change.
void KernighanLin() {
  if(KLfirst) {
    KLfirst=false;
    KLindex = new int[NUM_POINTS];
    int k=0;
    for(int j=0;j<clusters.length;++j) {
      for(int i=0;i<points.length-1;++i) {
        if(points[i].cluster==j) {
          KLindex[k++]=i;
        }
      }
    }
  }
  
  if(!KLStep()) mode++;
  
  background(0);
  strokeWeight(1);
  int lastCluster=-1;
  
  for(int k=1;k<KLindex.length;++k) {
    int i = KLindex[k];
    if(points[i].cluster!=lastCluster) {
      lastCluster=points[i].cluster;
      clusterColor(lastCluster);
      stroke(r,g,b);
    } else {
      int i1 = KLindex[k-1];
      line(
        points[i1].x,points[i1].y,
        points[i ].x,points[i ].y
        );
    }
  }
}


//int KLhits=0;
boolean KLStep() {
  int found=0;
  for(int i=0;i<KLindex.length-2;++i) {
    int w=KLindex[i];
    int x=KLindex[i+1];
    if(points[w].cluster != points[x].cluster) continue;  // only consider points in this cluster
    
    float wx = distance2(points[w],points[x]);
    float biggestCost = 0;
    int biggestIndex=-1;
    
    for(int j=i+2;j<KLindex.length;++j) {
      int y=KLindex[j];
      int z=KLindex[j-1];
      if(points[y].cluster != points[z].cluster) continue;  // only consider points in this cluster
      if(points[w].cluster != points[z].cluster) continue;  // only consider points in this cluster
      
      float yz = distance2(points[y],points[z]);
      // cost of original sequence is wx+yz
      
      float wz = distance2(points[w],points[z]);
      float yx = distance2(points[y],points[x]);
      // cost of new sequence is wz+yx
      float cost = (wx+yz) - (wz+yx);
      if(biggestCost<cost) {
        biggestCost=cost;
        biggestIndex=j;
      }
    }

    if(biggestIndex!=-1) {
      // we've found the route change that gets the biggest impact.  swap x and z.
      //++KLhits;
      found++;
      int start = i+1;
      int end = biggestIndex;
      int half = (end-start)/2;
      //println(KLhits+": swapping "+KLindex[start]+" through "+KLindex[end]);
      for(int swap=0;swap<half;swap++) {
        int temp = KLindex[start+swap];
        KLindex[start+swap] = KLindex[end-1-swap];
        KLindex[end-1-swap] = temp;
      }
      if(found>50) return true;
    }
  }
  
  return found>0;
}


void kmeans() {
  assignClusters();
  float err=adjustClusters();
  println(err);
  if(err<1) mode=1;  // we're done with this mode.
    
  background(0);
  
  // the clusters
  strokeWeight(4);
  for(int j=0;j<clusters.length;++j) {
    clusterColor(j);
    stroke(r,g,b);
    point(clusters[j].x,clusters[j].y);
  }
  
  // the points in those clusters
  strokeWeight(1);
  for(int i=0;i<points.length;++i) {
    clusterColor(points[i].cluster);
    stroke(r/2,g/2,b/2);
    point(points[i].x,points[i].y);
  }
}

float distance2(Point2D a,Point2D b) {
  float dx=a.x-b.x;
  float dy=a.y-b.y;
  
  return dx*dx+dy*dy; 
}


void assignClusters() {
  for(int i=0;i<points.length;++i) {
    double minLen = distance2(clusters[0],points[i]);
    int minIndex=0;
    for(int j=1;j<clusters.length;++j) {
      double len = distance2(clusters[j],points[i]);
      if(minLen > len) {
        minLen=len;
        minIndex=j;
      }
    }
    points[i].cluster=minIndex;
  }
}

float adjustClusters() {
  float error=0;
  for(int j=0;j<clusters.length;++j) {
    float x=0,y=0;
    int sum=0;
    for(int i=0;i<points.length;++i) {
      if(points[i].cluster==j) {
        x+=points[i].x;
        y+=points[i].y;
        sum++;
      }
    }
    if(sum<1) sum=1;
    float nx=x/sum;
    float ny=y/sum;
    x=nx-clusters[j].x;
    y=ny-clusters[j].y;
    clusters[j].x=nx;
    clusters[j].y=ny;
    float err=sqrt(x*x+y*y);
    error+=err;
  }
  
  return error;
}
