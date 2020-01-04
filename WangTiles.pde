// Code to stipple the image.
// Currently uses a Poisson disk to distribute points evenly over the image.
// Each point P is then evaluated for luminosity like so
//   L(P) <= random(255)
// and if they pass the test they are removed from the list.
// this tends to reject points in more lightly colored areas.
//
// The name of the file is WangTiles because they are the ideal right now in stippling technology.
// I don't have that system yet, but it would leave white areas completely empty.
import java.io.FileInputStream;
import java.io.BufferedInputStream;
import java.io.DataInputStream;


class Tile {
  int n, e, s, w;
  int numSubtiles, numSubdivs, numPoints, numSubPoints;
  int [][] subdivs;
  Point2D [] points;
  Point2D [] subPoints;
};

int numTiles, numSubtiles, numSubdivs;
Tile [] tiles;


class WangTileMachine {
  // magic numbers for clipping
  float mapX,mapY,mapZ;
  // clipping bounds [0...1]
  float clipMinX, clipMaxX, clipMinY, clipMaxY;
  // approximate max number of points
  float toneScale=30000;
  // store of stipple points
  ArrayList<Point2D> points = new ArrayList<Point2D>();


  // little endian to big endian 
  public int swap (int value) {
    int b1 = (value >>  0) & 0xff;
    int b2 = (value >>  8) & 0xff;
    int b3 = (value >> 16) & 0xff;
    int b4 = (value >> 24) & 0xff;
  
    return b1 << 24 | b2 << 16 | b3 << 8 | b4 << 0;
  }
  
  
  // little endian to big endian 
  public float swap (float value) {
    int intValue = Float.floatToIntBits (value);
    intValue = swap (intValue);
    return Float.intBitsToFloat (intValue);
  }


  void loadTileSet(final String fileName) {
    try {
      DataInputStream fin = new DataInputStream(new BufferedInputStream(new FileInputStream(fileName)));
        
      numTiles = swap(fin.readInt());
      numSubtiles = swap(fin.readInt());
      numSubdivs = swap(fin.readInt());
      println("numTiles="+numTiles);
      println("numSubtiles="+numSubtiles);
      println("numSubdivs="+numSubdivs);
      
      tiles = new Tile[numTiles];
    
      for (int i = 0; i < numTiles; i++) {
        tiles[i] = new Tile();
        
        tiles[i].n = swap(fin.readInt());
        tiles[i].e = swap(fin.readInt());
        tiles[i].s = swap(fin.readInt());
        tiles[i].w = swap(fin.readInt());
        
        println("Tile "+i);
        print("  n="+tiles[i].n);
        print("  s="+tiles[i].s);
        print("  e="+tiles[i].e);
        println("  w="+tiles[i].w);
    
        tiles[i].subdivs = new int[numSubdivs][];
        for (int j = 0; j < numSubdivs; j++) {
          print("  subdiv["+j+"]=");
          int [] subdiv = new int[(int)sq(numSubtiles)];
          for (int k = 0; k < sq(numSubtiles); k++) {
            subdiv[k] = swap(fin.readInt());
            print(subdiv[k]+",");
          }
          println();
          tiles[i].subdivs[j] = subdiv;
        }
    
        tiles[i].numPoints = swap(fin.readInt());
        println("  points="+tiles[i].numPoints);
        tiles[i].points = new Point2D[tiles[i].numPoints];
        for (int j = 0; j < tiles[i].numPoints; j++) {
          float x = swap(fin.readFloat());
          float y = swap(fin.readFloat());
          //println("    p x"+x+"\ty"+y);
          tiles[i].points[j]=new Point2D(x,y);
          fin.readInt();
          fin.readInt();
          fin.readInt();
          fin.readInt();
        }
    
        tiles[i].numSubPoints = swap(fin.readInt());
        println("  subpoints="+tiles[i].numSubPoints);
        tiles[i].subPoints = new Point2D[tiles[i].numSubPoints];
        for (int j = 0; j < tiles[i].numSubPoints; j++) {
          float x = swap(fin.readFloat());
          float y = swap(fin.readFloat());
          //println("    s x"+x+"\ty"+y);
          tiles[i].subPoints[j]=new Point2D(x,y);
          fin.readInt();
          fin.readInt();
          fin.readInt();
          fin.readInt();
        }
      }
      
      fin.close();
    }
    catch(IOException e) {
      e.printStackTrace();
    }
  }

  public WangTileMachine() {
    loadTileSet(sketchPath("tileset.dat"));
  }


  public ArrayList<Point2D> run(int maxPoints) {
    toneScale = maxPoints;
    mapX=0f;
    mapY=0f;
    mapZ=1f;
    clipMinX = mapX;
    clipMaxX = mapX+mapZ;
    clipMinY = mapY;
    clipMaxY = mapY+mapZ;
    points.clear();
    
    float startTime = millis()/1000.0;
  
    int numTests = min((int)tiles[0].numPoints, int(pow(mapZ, -2.f)*toneScale));
    float factor = 1.f/pow(mapZ, -2)/toneScale;
    for (int i = 0; i < numTests; i++)
    {
      float px = tiles[0].points[i].x;
      float py = tiles[0].points[i].y; 
  
      // skip point if it lies outside of the clipping window
      if ((px < clipMinX) || (px > clipMaxX) || (py < clipMinY) || (py > clipMaxY))
        continue;
  
      // reject point based on its rank
      if (sampleImageAt(px*img.width,py*img.height) < i*factor)
        continue;
  
      // "draw" point
      points.add(new Point2D(px*img.width,py*img.height));
      point(px*img.width,py*img.height);
    }
  
    // recursion
    recurseTile(tiles[0], 0, 0, 0);
  
    float endTime = millis()/1000.0;
  
    println(points.size()+" points in "+(int)((endTime-startTime)*1000)+" ms = "+(points.size()/(endTime-startTime))+" points/s\n");
    return points;
  }


  void recurseTile(Tile t, float x, float y, int level) {
    float tileSize = 1.f/pow(float(numSubtiles), float(level));
    if ((x+tileSize < clipMinX) || (x > clipMaxX) || (y+tileSize < clipMinY) || (y > clipMaxY))
      return;
  
    int numTests = min(t.numSubPoints, int(pow(mapZ, -2.f)/pow(float(numSubtiles), 2.f*level)*toneScale-t.numPoints));
    float factor = 1.f/pow(mapZ, -2.f)*pow(float(numSubtiles), 2.f*level)/toneScale;
  
    for (int i = 0; i < numTests; i++) {
      float px = x+t.subPoints[i].x*tileSize;
      float py = y+t.subPoints[i].y*tileSize;
  
      // skip point if it lies outside of the clipping window
      if ((px < clipMinX) || (px > clipMaxX) || (py < clipMinY) || (py > clipMaxY))
        continue;
  
      // reject point based on its rank
      if (sampleImageAt(px*img.width,py*img.height) < (i+t.numPoints)*factor)
        continue;
  
      // "draw" point
      points.add(new Point2D(px*img.width,py*img.height));
      point(px*img.width,py*img.height);
    }
  
    // recursion
    if (pow(mapZ, -2.f)/pow(float(numSubtiles), 2.f*level)*toneScale-t.numPoints > t.numSubPoints)
    {
      for (int ty = 0; ty < numSubtiles; ty++)
        for (int tx = 0; tx < numSubtiles; tx++)
          recurseTile(tiles[t.subdivs[0][ty*numSubtiles+tx]], x+tx*tileSize/numSubtiles, y+ty*tileSize/numSubtiles, level+1);
    }
  }
}


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


class WangTiles {
  int maxPoints=100;
  
  ArrayList<Point2D> pointsOut;
  
  WangTiles(int maxPoints0) {
    maxPoints=maxPoints0;
    println("WangTiles points="+maxPoints);
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
          float x = float(pieces[0]);
          float y = float(pieces[1]);
          pointsOut.add(new Point2D(x, y));
        }
        reader.close();
      } catch (IOException e) {
        e.printStackTrace();
      }
      
    } else {
      WangTileMachine wangTileMachine = new WangTileMachine();
      pointsOut = wangTileMachine.run(maxPoints);
    }
  }
  
  void render() {
    strokeWeight(2);
    stroke(255,0,0);
    for( Point2D p : pointsOut ) {
      point(p.x,p.y);
    }
    strokeWeight(1);
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


class PoissonStipples {
  // VARIABLES
  
  float RADIUS = 4;
  ArrayList<Point2D> pointsOut;
  
  
  // METHODS
  
  PoissonStipples(float arg0) {
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
          float x = float(pieces[0]);
          float y = float(pieces[1]);
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
        if(sampleLuminosity(p.x,p.y)<=random(255)) {
          toRemove.add(p);
        }
      }
      pointsOut.removeAll(toRemove);
    }
  }
  
  void render() {
    strokeWeight(2);
    stroke(255,0,0);
    for( Point2D p : pointsOut ) {
      point(p.x,p.y);
    }
    strokeWeight(1);
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
