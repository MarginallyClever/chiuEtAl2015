class WriteGCode {
  String filename;
  ArrayList<Point2D> pointsIn;
  PrintWriter f; 
  int index;
  
  // CHANGE ME: pen angles for up and down.
  double zUp=90;
  double zDown=40;
  
  /**
   * Setup parameters for the gcode.
   * The image will be scaled to these dimensions, regardless of the original aspect ratio.
   * The up and down values MUST match the values in your makelangelo robot settings.
   * @param outputName name of file where gcode will be saved
   * @param upAngle z height when pen is up
   * @param downAngle z height when pen is down
   */
  public WriteGCode(String outputName,double upAngle,double downAngle) {
    filename=outputName;
    zUp=upAngle;
    zDown=downAngle;
  }
  
  public void prepare(ArrayList<Point2D> arg0) {
    println("WriteGCode begin");
    pointsIn=arg0;
    
    // write out gcode to trace the edge of the drawing
    println("Writing border.ngc");
    f = createWriter("border.ngc");
    f.println("; "+year()+"-"+month()+"-"+day()+" chiuEtAl2015");
    f.println("G28");
    f.println("G0 Z"+nf2(zUp,0,0));
    f.println("G0 X"+tx(        0)+" Y"+ty(         0)+"");
    f.println("G0 Z"+nf2(zDown,0,0));
    f.println("G0 X"+tx(img.width)+" Y"+ty(         0)+"");
    f.println("G0 X"+tx(img.width)+" Y"+ty(img.height)+"");
    f.println("G0 X"+tx(        0)+" Y"+ty(img.height)+"");
    f.println("G0 X"+tx(        0)+" Y"+ty(         0)+"");
    f.println("G0 Z"+nf2(zUp,0,0));
    f.flush();
    f.close();
    
    // now start writing the gcode for the drawing
    println("Writing to "+filename);
    f = createWriter(filename);
    f.println("; "+year()+"-"+month()+"-"+day()+" chiuEtAl2015");
    f.println("G28");
    f.println("G0 Z"+nf2(zUp,0,0));
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
          f.println("G0 Z"+nf2(zDown,0,0));
        }
        index++;
      }
    }
    
    float percent = index*100.0/size;
    f.println("M117 "+nf2(percent,3,2)+"%");
    
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
    double fromCenter = x-((double)img.width/2.0);
    float v=(float)( fromCenter ); 
    return nf(v,0,2);
  }
  
  String ty(double y) {
    double fromCenter = ((double)img.height/2.0)-y;
    float v=(float)( fromCenter ); 
    return nf(v,0,2);
  }
  
  // replace default nf() with one that doesn't add european conventions.
  String nf2(double number,int left,int right) { //<>//
    String result = nf((float)number,left,right);
    return result;
  }  
};
