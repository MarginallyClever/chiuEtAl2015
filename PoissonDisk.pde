

// old method, poisson disk
class PoissonDisk {
  boolean isValidPoint(Point2D[][] grid, float cellsize,
                       int gwidth, int gheight,
                       Point2D p, float radius) {
    /* Make sure the point is on the screen */
    if (p.x < 0 || p.x >= img.width || p.y < 0 || p.y >= img.height)
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
    Point2D p0 = new Point2D(random(img.width), random(img.height));
    Point2D[][] grid;
    float cellsize = floor(radius/sqrt(N));
  
    /* Figure out no. of cells in the grid for our canvas */
    int ncells_width = ceil(img.width/cellsize) + 1;
    int ncells_height = ceil(img.height/cellsize) + 1;
  
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
