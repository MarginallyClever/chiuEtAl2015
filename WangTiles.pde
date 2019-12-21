// Code to stipple the image.
// Currently uses a Poisson disk to distribute points evenly over the image.
// Each point P is then evaluated for luminosity like so
//   L(P) <= random(255)
// and if they pass the test they are removed from the list.
// this tends to reject points in more lightly colored areas.
//
// The name of the file is WangTiles because they are the ideal right now in stippling technology.
// I don't have that system yet, but it would leave white areas completely empty.

class PoissonDisk {
  boolean isValidPoint(Point2D[][] grid, float cellsize,
                       int gwidth, int gheight,
                       Point2D p, float radius) {
    /* Make sure the point is on the screen */
    if (p.x < 0 || p.x >= width || p.y < 0 || p.y >= height)
      return false;
  
    /* Check neighboring eight cells */
    int xindex = floor(p.x / cellsize);
    int yindex = floor(p.y / cellsize);
    int i0 = max(xindex - 1, 0);
    int i1 = min(xindex + 1, gwidth - 1);
    int j0 = max(yindex - 1, 0);
    int j1 = min(yindex + 1, gheight - 1);
  
    for (int i = i0; i <= i1; i++)
      for (int j = j0; j <= j1; j++)
        if (grid[i][j] != null)
          if (dist(grid[i][j].x, grid[i][j].y, p.x, p.y) < radius)
            return false;
  
    /* If we get here, return true */
    return true;
  }
  
  void insertPoint(Point2D[][] grid, float cellsize, Point2D point) {
    int xindex = floor(point.x / cellsize);
    int yindex = floor(point.y / cellsize);
    grid[xindex][yindex] = point;
  }
  
  ArrayList<Point2D> run(float radius, int k) {
    int N = 2;
    /* The final set of points to return */
    ArrayList<Point2D> points = new ArrayList<Point2D>();
    /* The currently "active" set of points */
    ArrayList<Point2D> active = new ArrayList<Point2D>();
    /* Initial point p0 */
    Point2D p0 = new Point2D(random(width), random(height));
    Point2D[][] grid;
    float cellsize = floor(radius/sqrt(N));
  
    /* Figure out no. of cells in the grid for our canvas */
    int ncells_width = ceil(width/cellsize) + 1;
    int ncells_height = ceil(height/cellsize) + 1;
  
    /* Allocate the grid an initialize all elements to null */
    grid = new Point2D[ncells_width][ncells_height];
    for (int i = 0; i < ncells_width; i++)
      for (int j = 0; j < ncells_height; j++)
        grid[i][j] = null;
  
    insertPoint(grid, cellsize, p0);
    points.add(p0);
    active.add(p0);
  
    while (active.size() > 0) {
      int random_index = int(random(active.size()));
      Point2D p = active.get(random_index);
      
      boolean found = false;
      for (int tries = 0; tries < k; tries++) {
        float theta = radians(random(360));
        float new_radius = random(radius, 2*radius);
        float pnewx = p.x + new_radius * cos(theta);
        float pnewy = p.y + new_radius * sin(theta);
        Point2D pnew = new Point2D(pnewx, pnewy);
        
        if (!isValidPoint(grid, cellsize,
                          ncells_width, ncells_height,
                          pnew, radius))
          continue;
        
        points.add(pnew);
        insertPoint(grid, cellsize, pnew);
        active.add(pnew);
        found = true;
        break;
      }
      
      /* If no point was found after k tries, remove p */
      if (!found)
        active.remove(random_index);
    }
  
    return points;
  }
}


class WangTiles {
  float RADIUS = 4;
  
  
  // VARIABLES
  
  ArrayList<Point2D> pointsOut;
  
  
  // METHODS
  
  WangTiles(float arg0) {
    RADIUS = arg0;
  }
  
  void prepare() {
    pointsOut = new ArrayList<Point2D>();
    
    File f = new File(sketchPath("wangTiles.txt"));
    if(f.exists()) {
      // read in the points from the file
      BufferedReader reader = createReader(sketchPath("wangTiles.txt"));
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
      
    } else {
      PoissonDisk poissonDisk = new PoissonDisk();
      pointsOut = poissonDisk.run(RADIUS, 30);
      
      ArrayList<Point2D> toRemove = new ArrayList<Point2D>();
      for(Point2D p : pointsOut ) {
        if(sampleLuminosity((int)p.x,(int)p.y)<=random(255)) {
          toRemove.add(p);
        }
      }
      pointsOut.removeAll(toRemove);
    }
  }
  
  void render() {
    strokeWeight(1);
    stroke(255,0,0);
    for( Point2D p : pointsOut ) {
      point(p.x,p.y);
    }
  }
  
  boolean step() {
    return false;
  }
  
  void finish() {
    PrintWriter output = createWriter(sketchPath("wangTiles.txt"));
    for( Point2D p : pointsOut ) {
      output.println(p.x+"\t"+p.y);
    }
    output.flush();
    output.close();
  }
}
