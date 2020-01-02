class Kernighan_Lin {
  // VARIABLES

  DelaunayTriangulation dt;
  ArrayList<Point2D> pointsIn, pointsOut;
  ArrayList<Edge2D> connections;

  int KLi;
  int mode;

  // METHODS

  void prepare(ArrayList<Point2D> arg0, DelaunayTriangulation dt0) {
    println("Kernighan_Lin begin");
    dt = dt0;
    pointsIn = arg0;
    
    pointsOut = new ArrayList<Point2D>();
      
    File f = new File(sketchPath("kernighanLin.txt"));
    if(f.exists()) {
      // read in the points from the file
      BufferedReader reader = createReader(sketchPath("kernighanLin.txt"));
      String line = null;
      try {
        while ((line = reader.readLine()) != null) {
          String[] pieces = split(line, TAB);
          int x = int(pieces[0]);
          int y = int(pieces[1]);
          pointsOut.add(new Point2D(x, y));
        }
        reader.close();
      } catch (IOException e) {
        e.printStackTrace();
      }
      
      KLi=dt.pointsIn.size();
      mode=1;
    } else {
      // does not exists
      for (Point2D p : pointsIn ) {
        pointsOut.add(p);
      }

      java.util.Collections.sort(pointsOut);
    
      KLi=0;
      mode=0;
    }
  }

  void render() {
    //background(0);
    strokeWeight(1);
    int lastCluster=-1;

    if (mode==0) {
      beginShape();
      for ( Point2D pk : pointsOut ) { 
        if (pk.cluster!=lastCluster) {
          endShape();
          lastCluster=pk.cluster;
          clusterColor(lastCluster);
          beginShape();
        } else {
          vertex(pk.x, pk.y);
        }
      }
      endShape();
    } else {
      // mode=1
      for( Edge2D e : connections ) {
        clusterColor(e.a.cluster);
        line(e.a.x,e.a.y,e.b.x,e.b.y);
      }
    }
  }

  // swap any two points in the sequence.  Is the sequence shorter?  Then keep the swap.
  boolean step() {
    if (mode==0) {
      boolean keepGoing=stepOptimize();
      if (!keepGoing) {
        buildEdgeList();
        println("  Begin Kernighan_Lin.connect()");
        KLi=0; 
        mode++;
      }
      return true;
    } else {
      return stepConnect();
    }
  }

  void buildEdgeList() {
    println("  buildEdgeList()");
    connections = new ArrayList<Edge2D>();
    for ( Point2D c : dt.pointsIn ) {
      // find all the points for a given cluster and build a list of the edges that connect them.
      int cluster = c.cluster;
      int edgeCount=0;
      Point2D first=null;
      Point2D prev=null;
      for ( Point2D p : pointsOut ) {
        if(cluster == p.cluster) {
          if(first==null) first=p;
          if(prev!=null) {
            connections.add(new Edge2D(prev,p));
            edgeCount++;
          }
          prev=p;
        }
      }
      // then add the last edge from the end of the list back to the first point to close the loop.
      if(first!=null && first!=prev) {
        connections.add(new Edge2D(prev,first));
        edgeCount++;
      }
      //println("    cluster "+cluster+"="+edgeCount);
    }
    
    testEveryPointHasExactlyTwoEdges();
  }
  
  boolean stepConnect() {
    int size=dt.pointsIn.size();
    println("  "+(100.0*(size-1-KLi)/size)+"%");
    // go through all the clusters
    if(KLi>=dt.pointsIn.size()) return false;  // we're done here!
    
    Point2D c = dt.pointsIn.get(KLi); 
    KLi++; 
    
    boolean once=false;

    ArrayList<MinimumEnergyPack> packs = new ArrayList<MinimumEnergyPack>(); 

    // find the neighbors
    ArrayList<Point2D> neighbours = dt.findNeighbours(c);
    // find one neighbor that connects really good.
    for (Point2D n : neighbours ) {
      if (c.cluster<n.cluster) {
        //println("  "+c.cluster + "->" + n.cluster);
        MinimumEnergyPack mep = connect(c.cluster, n.cluster);
        if(mep!=null) packs.add(mep);
      }
    }
    
    java.util.Collections.sort(packs);
    if(packs.isEmpty()) {
      println("  connect() panic");
    } else {      
      MinimumEnergyPack mep = packs.get(0);
      
      connections.remove(mep.bestF);
      connections.remove(mep.bestS);
      if (mep.isCrossed) {
        // Edges FaSb and SaFb are shorter than edges FaFb and SaSb.
        //println("  X"+biggestCostSavings);
        connections.add(new Edge2D(mep.bestF.a,mep.bestS.b));
        connections.add(new Edge2D(mep.bestF.b,mep.bestS.a));
      } else {  // isUncrossed
        // Edges FaSa and SbFb are shorter than edges FaFb and SaSb.
        //println("  ||"+biggestCostSavings);
        connections.add(new Edge2D(mep.bestF.a,mep.bestS.a));
        connections.add(new Edge2D(mep.bestF.b,mep.bestS.b));
      }
    }
    return true;
  }

  // connect two clusters at the nearest edges
  MinimumEnergyPack connect(int c1, int c2) {
    // extract the clusters for faster searching
    ArrayList<Edge2D> first = new ArrayList<Edge2D>(); 
    ArrayList<Edge2D> second = new ArrayList<Edge2D>(); 
    for (Edge2D e : connections ) {
      if (e.a.cluster==c1) first.add(e); 
      if (e.b.cluster==c2) second.add(e); 
      //if(p.cluster>c2) break; // maybe?
    }
    
    // to find the nearest edges
    float biggestCostSavings = MAX_FLOAT; 
    Edge2D bestF=null;
    Edge2D bestS=null;
    boolean isCrossed=false;
    
    //  go through all possible combinations of groups.    
    for( Edge2D f : first ) {
      float fLen = distance2(f.a, f.b);
      for( Edge2D s : second ) {
        if(s==f) {
          // don't compare edges to themselves.  (how is this even possible?!)
          //println("  connect() anxiety 1 c1="+c1+" c2="+c2);
          continue;
        }
        if(s.a==f.a||s.b==f.b||
           s.a==f.b||s.b==f.a)
        {
          // don't compare edges that share a point.  (how is this even possible?!)
          //println("  connect() anxiety 2 c1="+c1+" c2="+c2);
          continue;
        }
        
        float er = fLen + distance2(s.a, s.b);
        // the length of the new edges - the length of the old edges.
        float erCrossed = distance2(f.a, s.b) 
                        + distance2(f.b, s.a)
                        - er; 
        float erUncrossed = distance2(f.a, s.a) 
                          + distance2(f.b, s.b)
                          - er;
        // the biggest savings will be from the er* with the lowest value.
        if(biggestCostSavings>erCrossed) {
          // the best so far
          biggestCostSavings = erCrossed;
          bestF=f;
          bestS=s;
          isCrossed=true;
        }
        if(biggestCostSavings>erUncrossed) {
          // the best so far
          biggestCostSavings = erUncrossed;
          bestF=f;
          bestS=s;
          isCrossed=false;
        }
      }
    }
    
    // I *MUST* find a connection, even if the connection makes the final loop
    // a little longer.  if(biggestCostSavings<0) would limit me to only changes
    // that are more efficient than the original two loops.  I don't care!  I'm
    // only visiting once and I need to connect these two loops.
    // found the closest two AND the edges to swap.
    if(bestF==null || bestS==null) {
      //println("  connect() panic c1="+c1+" c2="+c2+" first="+first.size()+" second="+second.size()+" test="+testCount);
      return null;
    }
    
    return new MinimumEnergyPack(c1,c2,bestF,bestS,isCrossed,biggestCostSavings);
  }

  Edge2D findEdgeWithPoint(Point2D p) {
    for( Edge2D e : connections ) {
      if(e.includes(p)) return e;
    }
    //println("  findEdgeWithPoint() panic. ");
    return null;
  }
  
  void testEveryPointHasExactlyTwoEdges() {
    println("  testEveryPointHasExactlyTwoEdges()");
    // test all pointsOut connect to two edges.
    for(Point2D pN : pointsOut ) {
      int hits=0;
      for(Edge2D e : connections ) {
        if(e.includes(pN)) hits++;
      }
      if(hits!=2) {
        println("    uh oh ("+hits+")");
      }
    }
    println("    ...done.");
  }

  boolean stepOptimize() {
    //println("test "+KLi);
    int size=pointsOut.size()-2;
    println("  "+(100.0*(size-1-KLi)/size)+"%");
    
    int found=0; 
    for (; KLi<pointsOut.size()-2; ++KLi) {
      int w = KLi; 
      int x = KLi+1; 
      if (pointsOut.get(w).cluster != pointsOut.get(x).cluster) {  // only consider points in this cluster
        ++KLi; 
        return true; // keep going
      }
  
      // find the change with the biggest impact
      float wx = distance2(pointsOut.get(w), pointsOut.get(x)); 
      float biggestCostSavings = 0; 
      int biggestIndex=-1; 

      for (int j=KLi+2; j<pointsOut.size(); ++j) {
        int y=j; 
        int z=j-1; 
        if (pointsOut.get(w).cluster != pointsOut.get(z).cluster) break; // only consider points in this cluster
        if (pointsOut.get(y).cluster != pointsOut.get(z).cluster) break; // only consider points in this cluster

        float yz = distance2(pointsOut.get(y), pointsOut.get(z)); 
        // cost of original sequence is wx+yz

        float wz = distance2(pointsOut.get(w), pointsOut.get(z)); 
        float yx = distance2(pointsOut.get(y), pointsOut.get(x)); 
        // cost of new sequence is wz+yx
        float costSavings = (wx+yz) - (wz+yx); 
        if (biggestCostSavings<costSavings) {
          biggestCostSavings=costSavings; 
          biggestIndex=j;
        }
      }

      if (biggestIndex!=-1) {
        // we've found the route change that gets the biggest impact.  swap x and z.
        //++KLhits;
        found++; 
        int start = KLi+1; 
        int end = biggestIndex; 
        int half = (end-start)/2; 
        //println(KLhits+": swapping "+KLindex[start]+" through "+KLindex[end]);
        for (int swap=0; swap<half; swap++) {
          Point2D temp = pointsOut.get(start+swap); 
            pointsOut.set( start+swap, pointsOut.get(end-1-swap) ); 
            pointsOut.set( end-1-swap, temp );
        }
        if (found>50) return true; 
          KLi--;
      }
    }

    return found>0;
  }
  
  // our points are drawn in the old numerical order.
  // the changed list of edges can be used to calculate the new numerical order.
  // every point is connected with two edges.  every edge with two points.
  // take p0, the first point of the first line
  // while( connections is not empty ) {
  //   add p0 to the new list.
  //   find e, the first edge attached to p0
  //   remove e from connections.
  //   find p1, the point in e that is not p0
  //   make p0=p1
  // };
  void finish() {
    println("  finish() ");
    if(connections==null || connections.size()==0) return;
    
    testEveryPointHasExactlyTwoEdges();
    
    ArrayList<Point2D> newList = new ArrayList<Point2D>();
    Point2D p0 = connections.get(0).a;
    //connections.remove(0);
    
    // the KL solution should be one continuous loop.  Count how many loops were made
    int [] hit = new int[pointsOut.size()];
    int loopID=1;
    int hitCount=0;
        
    while(!connections.isEmpty()) {
      hitCount++;
      hit[pointsOut.indexOf(p0)]=loopID;
      newList.add(p0);
      Edge2D e = findEdgeWithPoint(p0);
      connections.remove(e);
      if(e==null) {
        println("  finish panic "+hitCount+" ("+loopID+")");
        p0 = connections.get(0).a;
        loopID++;
      } else {
        Point2D p1 = (e.a==p0) ? e.b : e.a;
        p0=p1;
      }
    }
    newList.add(p0);
    
    println("  "+(int)(loopID)+" loops.");
    
    // replace the old list
    pointsOut = newList;

    // write
    println("Writing "+newList.size()+" points.");
    PrintWriter output = createWriter(sketchPath("kernighanLin.txt"));
    for( Point2D p : newList ) {
      output.println(p.x+"\t"+p.y);
    }
    output.flush();
    output.close();
  }
}
