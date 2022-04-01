class WriteSVG {
  String filename;
  ArrayList<Point2D> pointsIn;
  PrintWriter f; 
  int index;
  
  /**
   * Setup parameters
   * The image will be scaled to these dimensions, regardless of the original aspect ratio.
   * @param outputName name of file where gcode will be saved
   */
  public WriteSVG(String outputName) {
    filename=outputName;
  }
  
  public void prepare(ArrayList<Point2D> arg0) {
    println("WriteSVG begin");
    pointsIn=arg0;
    
    // now start writing the gcode for the drawing
    println("Writing to "+filename);
    f = createWriter(filename);
    f.println("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>");
    f.println("<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\" \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">");
    f.println("<!-- "+year()+"-"+month()+"-"+day()+" chiuEtAl2015 -->");
    f.println("<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\" viewBox=\"0 0 "+img.width+" "+img.height+"\">");
    f.print("<path fill='none' stroke='black' d='");
    
    index=0;
  }
  
  public boolean step() {
    int size=pointsIn.size();
    int pointsPerStep=200;
    
    println("  "+(100.0*(float)(size-index)/(float)size)+"%");
    for(int i=0;i<pointsPerStep;++i) {
      if(index<size) {
        Point2D p = pointsIn.get(index);
        f.print(index==0?"M ":"L ");
        f.print(p.x+" "+p.y+" ");
        index++;
      }
    }
    f.println();
    return index<size;
  }  
  
  public void finish() {
    f.println("'/>");
    f.println("</svg>");
    f.flush();
    f.close();
    println("Writing done.");
  }
}
