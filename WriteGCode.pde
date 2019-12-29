class WriteGCode {
  String filename;
  ArrayList<Point2D> pointsIn;
  PrintWriter f; 
  int index;
  
  // CHANGE ME: pen angles for up and down.
  double zUp=90;
  double zDown=40;
  // CHANGE ME: A2 size is 420x592mm
  double paperWidth=420;
  double paperHeight=592;
  double paperMargin=0.9;  // CHANGE ME: 0.9=90% drawable or 10% border
  
  /**
   * Setup parameters for the gcode.
   * The image will be scaled to these dimensions, regardless of the original aspect ratio.
   * The up and down values MUST match the values in your makelangelo robot settings.
   * @param outputName name of file where gcode will be saved
   * @param w width of output.
   * @param h height of output.
   * @param m margin %
   * @param up z height when pen is up
   * @param down z height when pen is down
   */
  WriteGCode(String outputName,double up,double down) {
    filename=outputName;
    paperWidth=width;
    paperHeight=height;
    paperMargin=1;
    zUp=up;
    zDown=down;
  }
  
  void prepare(ArrayList<Point2D> arg0) {
    println("WriteGCode begin");
    pointsIn=arg0;
    
    if(paperHeight<paperWidth) {
      double testWidth = paperHeight*width/height;
      if(testWidth>paperWidth) {
        paperHeight = testWidth*height/width;
      }
    } else {
      double testHeight = paperWidth*height/width;
      if(testHeight>paperHeight) {
        paperWidth = testHeight*width/height;
      }
    }
    
    // write out gcode to trace the edge of the drawing
    println("Writing border.ngc");
    f = createWriter("border.ngc");
    f.println("; "+year()+"-"+month()+"-"+day()+" chiuEtAl2015");
    f.println("G28");
    f.println("G0 Z"+zUp);
    f.println("G0 X"+tx(    0)+" Y"+ty(     0)+"");
    f.println("G0 Z"+zDown);
    f.println("G0 X"+tx(width)+" Y"+ty(     0)+"");
    f.println("G0 X"+tx(width)+" Y"+ty(height)+"");
    f.println("G0 X"+tx(    0)+" Y"+ty(height)+"");
    f.println("G0 X"+tx(    0)+" Y"+ty(     0)+"");
    f.println("G0 Z"+zUp);
    f.flush();
    f.close();
    
    // now start writing the gcode for the drawing
    println("Writing to "+filename);
    f = createWriter(filename);
    f.println("; "+year()+"-"+month()+"-"+day()+" chiuEtAl2015");
    f.println("G28");
    f.println("G0 Z"+zUp);
    index=0;
  }
  
  boolean step() {
    int size=pointsIn.size();
    int pointsPerStep =size/200;
    
    println("  "+(100.0*(float)(size-index)/(float)size)+"%");
    for(int i=0;i<pointsPerStep;++i) {
      if(index<size) {
        Point2D p = pointsIn.get(index);
        f.println("G0 X"+tx(p.x)+" Y"+ty(p.y));
        if(index==0) {
          f.println("G0 Z"+zDown);
        }
        index++;
      }
    }
    
    float percent = index*100.0/size;
    f.println("M117 "+nf(percent,3,2)+"%");
    
    return index<size;
  }
  
  void finish() {
    f.println("G0 Z"+zUp);
    f.println("; EOF");
    f.flush();
    f.close();
    println("Writing done.");
  }
  
  String tx(double x) {
    double fromCenter = x-((double)width/2.0);
    float v=(float)( fromCenter ); 
    return nf(v,0,2);
  }
  
  String ty(double y) {
    double fromCenter = ((double)height/2.0)-y;
    float v=(float)( fromCenter ); 
    return nf(v,0,2);
  }
};
