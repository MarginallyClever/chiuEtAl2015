/**
 * build a delaunay graph of the nearest neighbors between points
 *
 * https://github.com/jdiemke/delaunay-triangulator/blob/master/library/src/main/java/io/github/jdiemke/triangulation/DelaunayTriangulator.java#L2
 * is licensed under the MIT License (https://github.com/jdiemke/delaunay-triangulator/blob/master/LICENSE)
 */
class DelaunayTriangulation {
  // VARIABLES
  ArrayList<Point2D> pointsIn;  // the cluster centers
  ArrayList<Triangle2D> triangles;
  ArrayList<Edge2D> edges;
  int pi;  // pointsIn index
  
  Triangle2D superTriangle;


  // METHODS
  
  void render() {
    strokeWeight(1);
    float nt = triangles.size();
    for(int i=0;i<nt;++i) {
      Triangle2D t = triangles.get(i);
      rainbowColor((float)i/nt);

      // Draw the triangle slightly shrunken so that it isn't covered up by neighboring triangles.
      Point2D c = t.findGeometricCenter();
      beginShape();
      renderTrianglePoint(t.a,c);
      renderTrianglePoint(t.b,c);
      renderTrianglePoint(t.c,c);
      renderTrianglePoint(t.a,c);
      endShape();
    }
  }
  
  void renderTrianglePoint(Point2D a,Point2D b) {
    float dx=a.x-b.x;
    float dy=a.y-b.y;
    float d=sqrt(dx*dx + dy*dy);
    if(d>0) {
      dx/=d;
      dy/=d;
    }
    final float scale=1;
    clusterColor(a.cluster);
    vertex(a.x-dx*scale, a.y-dy*scale);
  }

  void prepare(ArrayList<Point2D> arg0) {
    if (arg0.size()<3) return;
    println("DelaunayTriangulation begin");

    pointsIn=arg0;
    triangles = new ArrayList<Triangle2D>();
    edges = new ArrayList<Edge2D>();

    superTriangle = new Triangle2D();
    // find the radius of all the pointsIn
    Point2D top=new Point2D(-MAX_FLOAT,-MAX_FLOAT);
    Point2D bot=new Point2D( MAX_FLOAT, MAX_FLOAT);
    for(int i=0;i<pointsIn.size();++i) {
      Point2D p = pointsIn.get(i);
      if(top.x<p.x) top.x = p.x;
      if(top.y<p.y) top.y = p.y;
      if(bot.x>p.x) bot.x = p.x;
      if(bot.y>p.y) bot.y = p.y;
    }
    float cx = (top.x+bot.x)/2;
    float cy = (top.y+bot.y)/2;
    
    float w=abs(top.x-bot.x);
    float h=abs(top.y-bot.y);
    float dd=max(w,h);
    // use the radius squared to build a triangle big enough to encompase every pointsIn.
    superTriangle.a = new Point2D( cx     , cy+3*dd );
    superTriangle.b = new Point2D( cx+3*dd, cy+0    );
    superTriangle.c = new Point2D( cx-3*dd, cy-3*dd );
    
    triangles.add(superTriangle);
    pi=0;
  }

  boolean step() {
    if(pi>=pointsIn.size()) return false;  // done!
    
    // there are more points to add.  get the next.
    final Point2D newPoint = pointsIn.get(pi);
    if(incrementalAddPoint(newPoint)) {
      pi++;
    } else {
      println(pi+" failed?!");
    }
    return true;
  }
  
  boolean incrementalAddPoint(Point2D newPoint) {
    stroke(255,255,255);
    strokeWeight(15);
    point(newPoint.x,newPoint.y);
    // find the triangle that contains the newPoint.
    Triangle2D t = findContainingTriangle(newPoint);
    if(t!=null) {
      //println(pi+" found tri");
      // split this triangle into three new triangles.
      Point2D a = t.a;
      Point2D b = t.b;
      Point2D c = t.c;
      Triangle2D first = new Triangle2D(a,b,newPoint);
      Triangle2D second = new Triangle2D(b,c,newPoint);
      Triangle2D third = new Triangle2D(c,a,newPoint);
      triangles.remove(t);
      triangles.add(first);
      triangles.add(second);
      triangles.add(third);
      // deal with an unusual edge case
      //println(pi + " legalizing ab");
      legalizeEdge(first, new Edge2D(a,b), newPoint);
      //println(pi + " legalizing bc");
      legalizeEdge(second, new Edge2D(b,c), newPoint);
      //println(pi + " legalizing ca");
      legalizeEdge(third, new Edge2D(c,a), newPoint);
      return true;
    }
    // Not found!  Check against all edges of all triangles for coincidence.
    Edge2D edge = findNearestEdge(newPoint);
    if(edge!=null) {
      println(pi+" found edge");
      // this edge is removed and four new edges are added
      Triangle2D first = findNeighbouringTriangle(null,edge);
      Triangle2D second = findNeighbouringTriangle(first,edge);
      
      Point2D firstNonEdgePoint = first.getNonEdgePoint(edge);
      Point2D secondNonEdgePoint = second.getNonEdgePoint(edge);
      
      triangles.remove(first);
      triangles.remove(second);

      Triangle2D triangle1 = new Triangle2D(edge.a, firstNonEdgePoint, newPoint);
      Triangle2D triangle2 = new Triangle2D(edge.b, firstNonEdgePoint, newPoint);
      Triangle2D triangle3 = new Triangle2D(edge.a, secondNonEdgePoint, newPoint);
      Triangle2D triangle4 = new Triangle2D(edge.b, secondNonEdgePoint, newPoint);

      triangles.add(triangle1);
      triangles.add(triangle2);
      triangles.add(triangle3);
      triangles.add(triangle4);

      legalizeEdge(triangle1, new Edge2D(edge.a, firstNonEdgePoint), newPoint);
      legalizeEdge(triangle2, new Edge2D(edge.b, firstNonEdgePoint), newPoint);
      legalizeEdge(triangle3, new Edge2D(edge.a, secondNonEdgePoint), newPoint);
      legalizeEdge(triangle4, new Edge2D(edge.b, secondNonEdgePoint), newPoint);
      return true;
    }
    
    return false;
  }
  
  // Search all edges of all triangles and return the Edge2D that is coincident with p.
  Edge2D findNearestEdge(Point2D p) {
    ArrayList<EdgeDistancePack> edgeList = new ArrayList<EdgeDistancePack>();
    
    int ti;
    for(ti=0;ti<triangles.size();++ti) {
      edgeList.add(triangles.get(ti).findNearestEdge(p));
    }
    
    EdgeDistancePack[] edgeDistancePacks = new EdgeDistancePack[edgeList.size()];
    edgeList.toArray(edgeDistancePacks);

    java.util.Arrays.sort(edgeDistancePacks);
    return edgeDistancePacks[0].edge;
  }

  // Search all triangles for the one that contains newPoint.  
  // May fail due to numerical error if the newPoint is conincident with the edge of a triangle.
  Triangle2D findContainingTriangle(Point2D p) {
    for (Triangle2D t : triangles) {
      if(t.contains(p)) {
        return t;
      }
    }
    return null;
  }
  
  void finish() {
    //println(pi+" finish");
    removeTrianglesUsing(superTriangle.a);
    removeTrianglesUsing(superTriangle.b);
    removeTrianglesUsing(superTriangle.c);
  }
  
  // I have just split a triangle into three sub-triangles.
  // One of those new triangles might have an old neighbour.
  // the newPoint might be so close to the old neighbour that the new arragement is wrong.
  // If this is the case then fix the problem and build the correct triangles. 
  void legalizeEdge(Triangle2D triangle, Edge2D edge, Point2D p) {
    Triangle2D neighbour = findNeighbouringTriangle(triangle, edge);
    if (neighbour == null) return;

    // If the triangle has a neighbor, then legalize the edge
    if (neighbour.isPointInCircumCircle(p)) {
      //println(pi + " neighbour in circle");
      triangles.remove(triangle);
      triangles.remove(neighbour);

      Point2D nonEdgePoint = neighbour.getNonEdgePoint(edge);

      Triangle2D first  = new Triangle2D(nonEdgePoint, edge.a, p);
      Triangle2D second = new Triangle2D(nonEdgePoint, edge.b, p);

      triangles.add(first );
      triangles.add(second);

      //println(pi + " legalize(2) Xa");
      legalizeEdge(first , new Edge2D(nonEdgePoint, edge.a), p);
      //println(pi + " legalize(2) Xb");
      legalizeEdge(second, new Edge2D(nonEdgePoint, edge.b), p);
    }
  }

  Triangle2D findNeighbouringTriangle(Triangle2D t0,Edge2D e0) {
    // check all the triangles
    int c = triangles.size();
    for(int i=0;i<c;++i) {
      Triangle2D t1 = triangles.get(i);
      // except t0
      if(t1==t0) continue;
      // for the triangle that owns this edge.
      if(t1.includes(e0.a) && t1.includes(e0.b)) {
        // the one and only triangle is the one we seek.
        return t1;
      } 
    }
    // we found nothing!
    return null;
  }
  
  void removeTrianglesUsing(Point2D arg0) {
    ArrayList<Triangle2D> toBeRemoved = new ArrayList<Triangle2D>();
    
    for( Triangle2D t : triangles ) {
      if(t.includes(arg0)) {
        toBeRemoved.add(t);
      }
    }
    
    triangles.removeAll(toBeRemoved);
  }
  
  ArrayList<Point2D> findNeighbours(Point2D p) {
    ArrayList<Point2D> neighbours = new ArrayList<Point2D>();
    
    for(Triangle2D t : triangles) {
      if(t.includes(p)) {
        if(t.a!=p && !neighbours.contains(t.a)) neighbours.add(t.a);
        if(t.b!=p && !neighbours.contains(t.b)) neighbours.add(t.b);
        if(t.c!=p && !neighbours.contains(t.c)) neighbours.add(t.c);
      }
    }
    
    return neighbours;
  }
}
