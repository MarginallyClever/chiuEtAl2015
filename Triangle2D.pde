
class Triangle2D {
  
  
  // VARIABLES
  Point2D a,b,c;
  
  
  // METHODS
  
  Triangle2D() {}
  Triangle2D(Point2D aa,Point2D bb,Point2D cc) {
    a=aa;
    b=bb;
    c=cc;
  }
  
  boolean contains(Point2D p) {/*
    Edge2D ab = new Edge2D(a,b);
    Edge2D bc = new Edge2D(b,c);
    Edge2D ca = new Edge2D(c,a);
    int abn = ab.whereAmI(p);
    int bcn = bc.whereAmI(p);
    int can = ca.whereAmI(p);
    int side = Edge2D.LEFT_SIDE|Edge2D.RIGHT_SIDE;
    if((abn & side) == (bcn & side)
    && (abn & side) == (can & side))
    {
      // in
      return true;
    }
    // else
    return false;*/
    float pax=p.x-a.x;
    float pay=p.y-a.y;
    float bax=b.x-a.x;
    float bay=b.y-a.y;
    float pbx=p.x-b.x;
    float pby=p.y-b.y;
    float cbx=c.x-b.x;
    float cby=c.y-b.y;
    float pab = pax*bay - pay*bax;
    float pbc = pbx*cby - pby*cbx;
    if (!hasSameSign(pab, pbc)) {
      return false;
    }
    
    float pcx=p.x-c.x;
    float pcy=p.y-c.y;
    float acx=a.x-c.x;
    float acy=a.y-c.y;
    float pca = pcx*acy - pcy*acx;    
    if (!hasSameSign(pab, pca)) {
      return false;
    }
    
    return true;
  }
  
  boolean hasSameSign(float a, float b) {
    return Math.signum(a) == Math.signum(b);
  }
  
  boolean includes(Point2D arg0) {
    return a==arg0 || b==arg0 || c==arg0;
  }
  
  // find the center of the circle with three points a,b,c
  // It is *not* the point in the middle of all three.
  Point2D findCircumCenter() {
    // lines can be represented as ax+by+c=0.  get abc for lines AB and BC.
    // AB
    float a1 = b.y-a.y;
    float b1 = a.x-b.x;
    float c1 = a1*a.x+b1*a.y;
    // BC
    float a2 = c.y-b.y;
    float b2 = b.x-c.x;
    float c2 = a2*b.x+b2*b.y;
    // get perpendicular lines
    {
      // ABn
      float cx=(a.x+b.x)/2;
      float cy=(a.y+b.y)/2;
      c1 = -b1*cx+ a1*cy;
      float temp = a1;
      a1= -b1;
      b1= temp;      
    }
    {
      // BCn
      float cx=(b.x+c.x)/2;
      float cy=(b.y+c.y)/2;
      c2 = -b2*cx+ a2*cy;
      float temp = a2;
      a2= -b2;
      b2= temp;      
    }
    // the intersection of lines abc1 and abc2 is the center point.
    float determinant = a1*b2 - a2*b1; 
    if (determinant == 0) 
    { 
        // The lines are parallel. This is simplified 
        // by returning a pair of FLT_MAX 
        return new Point2D(MAX_FLOAT, MAX_FLOAT); 
    } 
  
    else
    { 
        float x = (b2*c1 - b1*c2) / determinant; 
        float y = (a1*c2 - a2*c1) / determinant; 
        return new Point2D(x, y); 
    } 
  }

  boolean isPointInCircumCircle(Point2D p) {
    float a11 = a.x - p.x;
    float a21 = b.x - p.x;
    float a31 = c.x - p.x;

    float a12 = a.y - p.y;
    float a22 = b.y - p.y;
    float a32 = c.y - p.y;

    float a13 = (a.x - p.x) * (a.x - p.x) + (a.y - p.y) * (a.y - p.y);
    float a23 = (b.x - p.x) * (b.x - p.x) + (b.y - p.y) * (b.y - p.y);
    float a33 = (c.x - p.x) * (c.x - p.x) + (c.y - p.y) * (c.y - p.y);

    float det = a11 * a22 * a33 
              + a12 * a23 * a31
              + a13 * a21 * a32
              - a13 * a22 * a31
              - a12 * a21 * a33
              - a11 * a23 * a32;

    if (isOrientedCCW()) {
        return det > 0.0d;
    }

    return det < 0.0d;
  }
    
  boolean isOrientedCCW() {
    float a11 = a.x - c.x;
    float a21 = b.x - c.x;
  
    float a12 = a.y - c.y;
    float a22 = b.y - c.y;
  
    float det = a11 * a22 - a12 * a21;
  
    return det > 0.0;
  }
  
  // return which p[n] is not part of e0.
  Point2D getNonEdgePoint(Edge2D e0) {
    if(!e0.includes(a)) return a;
    if(!e0.includes(b)) return b;
    // if(!e0.includes(b) must be true
                        return c;
  }
  
  EdgeDistancePack findNearestEdge(Point2D p) {
    Edge2D e1 = new Edge2D(a,b);
    Edge2D e2 = new Edge2D(b,c);
    Edge2D e3 = new Edge2D(c,a);
    Point2D p1 = findClosestPoint(e1,p);
    Point2D p2 = findClosestPoint(e2,p);
    Point2D p3 = findClosestPoint(e3,p);
    
    EdgeDistancePack [] edges = new EdgeDistancePack[3];
    edges[0] = new EdgeDistancePack(e1,distance2(p1,p));
    edges[1] = new EdgeDistancePack(e2,distance2(p2,p));
    edges[2] = new EdgeDistancePack(e3,distance2(p3,p));
    java.util.Arrays.sort(edges);
    return edges[0];
  }

  /**
   * find the closest point to p within the range a-b.
   */
  Point2D findClosestPoint(Edge2D edge, Point2D p) {
    float abx = b.x-a.x;
    float aby = b.y-a.y;
    
    float pax = p.x-a.x;
    float pay = p.y-a.y; 
    
    float t = ( pax*abx + pay*aby ) / (abx*abx + aby*aby);
    if(t<0) t=0;
    else if(t>1) t=1;
    
    return new Point2D(edge.a.x+abx*t,edge.a.y+aby*t);
  }
  
  Point2D findGeometricCenter() {
    return new Point2D(
      (a.x+b.x+c.x)/3,
      (a.y+b.y+c.y)/3);
  }
}
