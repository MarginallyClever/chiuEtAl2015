// circular scribble
// 2019-11-22 dan@marginallyclever.com
// based on http://cgv.cs.nthu.edu.tw/~seanyhl/project/CircularScribbleArt/Chiu_et_al-2015-Computer_Graphics_Forum.pdf
// CC-BY-NC-SA

/**
 * prepare() with an ArrayList<Point2D> of straight lines.
 * will step through entire list and generate a list of pointsOut forming the circular scribble.
 */
class CircularScribbler {
  // CONSTANTS 
  
  // angular velocity in radians. 'ω' in the literature.  Best when >0 and <1.
  float ANGULAR_VELOCITY_RAD=0.5;
  // max/min radius for scribble
  float RMAX=15;
  float RMIN=2;
  // max/min center velocity for scribble.  Best when center velocity < angular velocity
  float CVMAX=PI*2*ANGULAR_VELOCITY_RAD;
  float CVMIN=CVMAX/20;
  
  
  // VARIABLES
  
  // list of points to convert
  ArrayList<Point2D> pointsIn, pointsOut;
  // point index (for incremental stepping)
  int pi;
  // last angle (to connect scribbles)
  float angle=0;
  

  // METHODS
  
  CircularScribbler(float angularVelocityRadians,float rMax,float rMin) {
    ANGULAR_VELOCITY_RAD =angularVelocityRadians;
    RMAX=rMax;
    RMIN=rMin;
  }

  void prepare(ArrayList<Point2D> newList) {
    println("CircularScribbler begin");
    pointsIn = newList;
    pointsOut = new ArrayList<Point2D>();
    pi=0;
  }
  
  void render() {
    background(255);
    strokeWeight(1);
    stroke(0,0,0,64);

    Point2D prev=null;
    for( Point2D pk : pointsOut ) {
      if(prev!=null) {
        line(prev.x,prev.y,pk.x,pk.y);
      }
      prev=pk;
    }
  }
  
  boolean step() {
    int count = pointsIn.size()/200;
    
    int ps=pointsIn.size();
    for(int i=0;i<count;++i) {
      if(pi<ps) {
        scribbleLine(pi,(pi+1)%ps);
        pi++;
      }
    }
    
    println("  "+((float)(ps-pi)*100.0/(float)ps)+"%");
    return (pi<ps);
  }

  // convert luminosity value p[0...255] into radius [RMIN...RMAX]
  float luminosityToRadius(float p) {
    return RMIN + ((255-p)/255.0) * (RMAX-RMIN);
  }
  
  // convert luminosity value p[0...255] into center velocity [CVMIN...CVMAX]
  float luminosityToCenterVelocity(float p) {
    return CVMIN + ((255-p)/255.0) * (CVMAX-CVMIN);
  }
  
  
  void scribbleLine(int arg0,int arg1) {
    Point2D a = pointsIn.get(arg0);
    Point2D b = pointsIn.get(arg1);
    float dx=b.x-a.x;
    float dy=b.y-a.y;
    float D = sqrt(distance2(a,b));
    //println("D="+D);
  
    if(D==0) return;
    
    // accumulated distance
    float td=0;
    // center velocity
    float cv=0;
    
    // travel from a to b, sampling as we go.
    for(td=0;td<D;td+=cv) {
      //print("\ttd="+td);
      float t = td/D;
      //print("\tt="+t);
      float cpx = a.x + t * dx;
      float cpy = a.y + t * dy;
      float luminosity = sampleLuminosity((int)cpx,(int)cpy);  // along center of line
      //print("\tluminosity="+luminosity);
      cv = luminosityToCenterVelocity(luminosity);
      //print("\tcv="+cv);
      float r = luminosityToRadius(luminosity);
      //print("\tr="+r);
      float epx = cpx + cos(angle)*r;
      float epy = cpy + sin(angle)*r;
      //print("\tepx="+epx);
      //print("\tepy="+epy);
      angle += ANGULAR_VELOCITY_RAD;
      //print("\tangle="+angle);
      pointsOut.add(new Point2D(epx,epy,a.cluster));
      //println();
    }
  }
  
  void finish() {
    background(255);
    strokeWeight(1);
    stroke(0,0,0,64);

    Point2D prev=null;
    for( Point2D pk : pointsOut ) {
      if(prev!=null) {
        line(prev.x,prev.y,pk.x,pk.y);
      }
      prev=pk;
    }
  }
}