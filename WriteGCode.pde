class WriteGCode {
  String filename;
  ArrayList<Point2D> pointsIn;
  PrintWriter f; 
  int index;
  
  // pen angles
  double zUp=90;
  double zDown=40;
  // A2 size is 420x592mm
  double paperWidth=420;
  double paperHeight=594;
  double paperMargin=0.9;  // 0.9=90% drawable or 10% border
  
  WriteGCode(String outputName) {
    filename=outputName;
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
    println("Writing to "+filename);
    f = createWriter(filename);
    f.println("; "+year()+"-"+month()+"-"+day()+" chiuEtAl2015");
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
    float v=(float)( (x-width/2)*(paperWidth/width)*paperMargin ); 
    return nf(v,0,2);
  }
  
  String ty(double y) {
    float v =(float)( (height/2-y)*(paperWidth/width)*paperMargin );
    return nf(v,0,2);
  }
};
