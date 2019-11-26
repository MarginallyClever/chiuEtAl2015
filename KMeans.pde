class KMeans {
  
  // CONSTANTS
  
  // must be a n*n where n is a whole number>0
  int NUM_CLUSTERS = 14*14;
  int M = 20;
  int MAX_ITERATIONS = 30;
  
  
  // VARIABLES
  
  int N;
  float S; 
  int iterations;

  ArrayList<Point2D> pointsIn, pointsOut;
  ArrayList<Point2D> clustersOut;
  
  
  // METHODS
  KMeans(int clusters,int m,int maxIter) {
    NUM_CLUSTERS = clusters*clusters;
    M=m;
    MAX_ITERATIONS=maxIter;
  }
  
  void prepare(ArrayList<Point2D> arg0) {
    println("KMeans begin");
    N = width*height;
    S = sqrt( (float)N / (float)NUM_CLUSTERS ); 
  
    pointsIn = arg0;
    pointsOut = new ArrayList<Point2D>();
    for(int j=0;j<pointsIn.size();++j) {
      pointsOut.add(new Point2D(pointsIn.get(j)));
    }
    
    clustersOut = new ArrayList<Point2D>();
    int j=0;
    int c = (int)sqrt(NUM_CLUSTERS);
    float w = width/(float)c;
    float h = height/(float)c;
    for(int y=0;y<c;++y) {
      for(int x=0;x<c;++x) {
        clustersOut.add(new Point2D(x*w+w/2,y*h+h/2,j++));
      }
    }
    iterations=MAX_ITERATIONS;
  }
  
  void render() {
    //background(0);
    
    // the clusters
    strokeWeight(5);
    for( Point2D c : clustersOut ) {
      clusterColor(c.cluster);
      point(c.x,c.y);
    }
    
    // the points in those clusters
    strokeWeight(2);
    for( Point2D p : pointsOut ) {
      clusterColor(p.cluster);
      point(p.x,p.y);
    }
  }
  
  boolean step() {
    assignClusters();
    float err=adjustClusters();
    println("  "+iterations+"="+err);
    iterations--;
    return (iterations >=0) && (err>=1);  // error term still high, points haven't settled yet.
  }
  
  void assignClusters() {
    for(int i=0;i<pointsOut.size();++i) {
      Point2D p = pointsOut.get(i);
      
      float minError = MAX_FLOAT;
      float pixelTone = sampleLuminosity((int)p.x,(int)p.y);
      int minIndex=0;
      for(int j=0;j<clustersOut.size();++j) {
        Point2D c = clustersOut.get(j);
        float len = distance2(c,p);
        float clusterTone = sampleLuminosity((int)c.x,(int)c.y);
        float lengthError = len/S;
        float toneError = (pixelTone - clusterTone)/M;
        float error = toneError*toneError + lengthError*lengthError;
        if(minError > error) {
          minError=error;
          minIndex=j;
        }
      }
      p.cluster=minIndex;
    }
  }
  
  float adjustClusters() {
    float error=0;
    for(int j=0;j<clustersOut.size();++j) {
      float x=0,y=0;
      int sum=0;
      for(int i=0;i<pointsOut.size();++i) {
        if(pointsOut.get(i).cluster==j) {
          x+=pointsOut.get(i).x;
          y+=pointsOut.get(i).y;
          sum++;
        }
      }
      float err=0;
      if(sum>0) {
        float nx=x/sum;
        float ny=y/sum;
        x=nx-clustersOut.get(j).x;
        y=ny-clustersOut.get(j).y;
        clustersOut.get(j).x=nx;
        clustersOut.get(j).y=ny;
        err=sqrt(x*x+y*y);
      }
      error+=err;
    }
    
    return error;
  }
  
  // remove any clusters that have no points
  void finish() {
    int [] data = new int[clustersOut.size()];
    
    for( Point2D p : pointsOut ) {
      data[p.cluster]++;
    }
    
    ArrayList<Point2D> clustersToRemove = new ArrayList<Point2D>();
    ArrayList<Point2D> pointsToRemove = new ArrayList<Point2D>();
    
    for(int i=0;i<clustersOut.size();++i) {
      //print("  cluster "+i+"="+data[i]);
      if(data[i]<2) {
        // a cluster with <3 points can't form a triangle.  
        // Remove the cluster and any related points.
        //println(" removed");
        clustersToRemove.add(clustersOut.get(i));

        for( Point2D p : pointsOut ) {
          if(p.cluster==i) {
            pointsToRemove.add(p);
          }
        }
      } else {
        //println();
      }
    }
    pointsOut.removeAll(pointsToRemove);
    clustersOut.removeAll(clustersToRemove);
  }
}
