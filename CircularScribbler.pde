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
  float ANGULAR_VELOCITY_RAD=0.25;
  // max/min radius for scribble
  float RMAX=25;
  float RMIN=5;
  // max/min center velocity for scribble.  Best when center velocity < angular velocity
  float CVMAX=1;
  float CVMIN=0.5;
  
  
  // VARIABLES
  
  // list of points to convert
  ArrayList<Point2D> pointsIn, pointsOut;
  // point index (for incremental stepping)
  int pi;
  // last angle (to connect scribbles)
  float angle=0;

  int drawFirst,drawLast;

  // METHODS
  
  CircularScribbler(float angularVelocityDegrees,float rMax,float rMin,float cvMax,float cvMin) {
    ANGULAR_VELOCITY_RAD = radians(angularVelocityDegrees);
    CVMAX = ANGULAR_VELOCITY_RAD * cvMax;
    CVMIN = ANGULAR_VELOCITY_RAD * cvMin;
    RMAX=rMax;
    RMIN=rMin;
  }

  void prepare(ArrayList<Point2D> arg0) {
    println("CircularScribbler begin");
    
    pointsIn = arg0;
    pointsOut = new ArrayList<Point2D>();
    pi=0;
    
    background(255);
    strokeWeight(4);
    stroke(0);
  }
  
  void render() {
    beginShape();
    for( int i = drawFirst;i<drawLast;++i) {
      Point2D pk = pointsOut.get(i);
      vertex(pk.x,pk.y);
    }
    endShape();
    drawFirst=0;
    drawLast=pointsOut.size();
  }
  
  boolean step() {
    int count = pointsIn.size()/100;
    
    drawFirst=pointsOut.size();
    if(drawFirst>0) drawFirst--;

    int ps=pointsIn.size();
    for(int i=0;i<count;++i) {
      if(pi<ps) {
        scribbleLine(pi,(pi+1)%ps);
        pi++;
      }
    }
    
    drawLast=pointsOut.size();
    
    println("  "+((float)(ps-pi)*100.0/(float)ps)+"%");
    return (pi<ps);
  }

  // convert luminosity value p[0...255] into radius [RMIN...RMAX]
  float luminosityToRadius(float p) {
    return RMIN + (1.0f-p) * (RMAX-RMIN);
  }
  
  // convert luminosity value p[0...255] into center velocity [CVMIN...CVMAX]
  float luminosityToCenterVelocity(float p) {
    return CVMIN + (1.0f-p) * (CVMAX-CVMIN);
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
      float luminosity = sampleLuminosity(cpx,cpy);  // along center of line
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
    /*
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
    */
  }
}
