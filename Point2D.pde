
class Point2D implements Comparable<Point2D> {
  
  
  // VARIABLES
  public float x,y;
  int cluster;
  
  
  // METHODS
  
  Point2D(float xx,float yy) {
    x=xx;
    y=yy;
  }
  
  Point2D(float xx,float yy,int cc) {
    x=xx;
    y=yy;
    cluster=cc;
  }
  
  Point2D(Point2D arg0) {
    x=arg0.x;
    y=arg0.y;
    cluster=arg0.cluster;
  }
  
  int compareTo(Point2D n) {
    return cluster - n.cluster;
  }
}


float distance2(Point2D a,Point2D b) {
  float dx=a.x-b.x;
  float dy=a.y-b.y;
  
  return dx*dx+dy*dy; 
}
