// Implementation of [Chiu_et_al-2015-Computer_Graphics_Forum.pdf]
// 2019-11-25 dan@marginallyclever.com
// CC-BY-NC-SA
//
// https://github.com/jdiemke/delaunay-triangulator/blob/master/library/src/main/java/io/github/jdiemke/triangulation/DelaunayTriangulator.java#L2
// is licensed under the MIT License (https://github.com/jdiemke/delaunay-triangulator/blob/master/LICENSE)
//
// see also https://en.wikipedia.org/wiki/Kernighan%E2%80%93Lin_algorithm

import java.util.Locale;

// CONSTANTS


// GLOBALS

PImage img;
WangTiles wangTiles;
KMeans kMeans;
Kernighan_Lin kernighanLin;
DelaunayTriangulation delaunayTriangulation; 
CircularScribbler scribbler;
WriteGCode writeGCode = new WriteGCode("output.ngc",90,40);
WriteSVG writeSVG = new WriteSVG("output.svg");
int mode;

int maxSize=4000;
float scaleNow=1;

String sourceName = "";

// METHODS

PImage prepareImage(String filename) {
  if(filename.indexOf('.')!= -1) {
    sourceName = filename.substring(0, filename.lastIndexOf('.')) + '-';
  }
  return loadImage(filename);
}


void setup() {
  size(1040,1040, P2D);  // size of the window

  // CHANGE ME: choose any one of these for a starter image, or use your own.
  // The size(x,y) should match the size of your image.
  //img = loadImage("mandrill.jpg");
  //img = loadImage("A4000x2135.jpg");
  //img = loadImage("elon smoking.jpg");
  //img = loadImage("elon smoking 2.jpg");
  //img = loadImage("2JOOhneHimmel.jpg");
  //img = loadImage("cropped.jpg");
  //img = loadImage("mona-lisa.jpg");
  //img = loadImage("morenaBaccarin.jpg");
  //img = loadImage("phillipineEagle.jpg");
  img = loadImage("shortHair.jpg");

  // adjust the luminosity once for everywhere.  much faster.
  img.filter(GRAY);
  adjustTone();
  // set number format to US.
  Locale.setDefault(Locale.US);
  
  if(img.width > img.height) {
    int v = (int)( (float)img.height * (float)maxSize / (float)img.width );
    img.resize(maxSize,v);
  } else {
    int v = (int)( (float)img.width * (float)maxSize / (float)img.height );
    img.resize(v,maxSize);
  }
  
  scaleNow = (float)width / (float)maxSize;

  // CHANGE ME: parameters here control each step
  wangTiles = new WangTiles(40000);  // estimated maximum number of points
  kMeans = new KMeans(14,20,30);  // sqrt(clusters)[14],M(1...40)[20],max iterations.  Probably don't change this.
  delaunayTriangulation = new DelaunayTriangulation(); 
  kernighanLin = new Kernighan_Lin();
  // Drawing controls.  Angular velocity (degrees), max spiral radius, minimum spiral radius,max center velocity,min center velocity
  scribbler = new CircularScribbler(10,(float)maxSize/50.f,13,10,1.f/2.f);
  // where to write the gcode, pen up angle [0-180], pen down angle [0-180].
  // Up and down values MUST match the values in your makelangelo robot settings > pen tab. 
  // A2 size is 420x592mm
  
  smooth(1);
  noFill();
  mode=0;
  wangTiles.prepare();
}
 

// (0...1]
void rainbowColor(float zeroToOne) {
  // index as hsv to rgb
  // https://en.wikipedia.org/wiki/HSL_and_HSV#HSV_to_RGB
  // Assume Hue=v/360, saturation=1, value=1.
  float C = 1;// C=V*S
  float H = zeroToOne*6;
  float X = C * (1-abs((H % 2) - 1));
  
  float r,g,b;
  
       if(H<1) { r=C; g=X; b=0; }
  else if(H<2) { r=X; g=C; b=0; }
  else if(H<3) { r=0; g=C; b=X; }
  else if(H<4) { r=0; g=X; b=C; }
  else if(H<5) { r=X; g=0; b=C; }
  else         { r=C; g=0; b=X; }  // H<6
  
  stroke(r*255,g*255,b*255,192);
}

// Give j [0....NUM_CLUSTERS-1]
// sets globals {r,g,b} to a rainbow color.
void clusterColor(int j) {
  float v = (float)(j+1) / (float)kMeans.NUM_CLUSTERS; // (0...1]
  rainbowColor(v);
}


// white (255) should be 0.
// black (  0) should be 1.
float sampleImageAt(float x,float y) {
  // it's a greyscale image, any channel will do.
  float i = 255 - red( img.get((int)x,(int)y) );
  // invert and scale
  i/=255;
  return  min(1,max(0,i));
}


float toneControl(float v) {
  v = 0.017 * exp(3.29*v)+0.005 * exp(7.27*v);
  return min(1,max(0,v));
}

void adjustTone() {
  img.loadPixels();
  for(int i=0;i<img.width*img.height;++i) {
    float v = img.pixels[i] & 0xff;
    int v2 = (int)(toneControl(v/255.0)*255.0);
    int rgb = min(255,max(0,v2));
    img.pixels[i] = color(rgb,rgb,rgb);
  }
  img.updatePixels();
}


// use linear interpolation to sample between pixels
float sampleLuminosityNew(float x,float y) {
  float tx=x;
  float ty=y;
  int ix=max(min(floor(tx),img.width -2),0);
  int iy=max(min(floor(ty),img.height-2),0);
  tx-=ix;
  ty-=iy;
  
  float sample =  
    sampleImageAt(ix  ,iy  )*(1-tx)*(1-ty) + 
    sampleImageAt(ix+1,iy  )*(  tx)*(1-ty) + 
    sampleImageAt(ix  ,iy+1)*(1-tx)*(  ty) + 
    sampleImageAt(ix+1,iy+1)*(  tx)*(  ty);
  
  return sample;
}


// average over several neighboring points
float sampleLuminosity(float x,float y) {
  // image source.
  // 1 3 1 = 5
  // 3 5 3 = 11
  // 1 3 1 = 5
  //       = 21
  float sum=0;
  float count=0;
  
  if(x>0) {
    if(y>0       ) { sum += sampleImageAt((int)x-1,(int)y-1) * 1.0;  count+=1; }
                   { sum += sampleImageAt((int)x-1,(int)y  ) * 3.0;  count+=3; }
    if(y<img.height-1) { sum += sampleImageAt((int)x-1,(int)y+1) * 1.0;  count+=1; }
  }
  // middle
    if(y>0       ) { sum += sampleImageAt((int)x  ,(int)y-1) * 3.0;  count+=3; }
                   { sum += sampleImageAt((int)x  ,(int)y  ) * 5.0;  count+=5; }
    if(y<height-1) { sum += sampleImageAt((int)x  ,(int)y+1) * 3.0;  count+=3; }
  // bottom
  if(x<img.width-1) {
    if(y>0       ) { sum += sampleImageAt((int)x+1,(int)y-1) * 1.0;  count+=1; }
                   { sum += sampleImageAt((int)x+1,(int)y  ) * 3.0;  count+=3; }
    if(y<img.height-1) { sum += sampleImageAt((int)x+1,(int)y+1) * 1.0;  count+=1; }
  }
  
  return sum/count;
}


void draw() {
  scale(scaleNow);
  //translate(20,20);
  
  switch(mode) {
    case 0:
      image(img,0,0);
      if(wangTiles.step()) wangTiles.render();
      else {
        wangTiles.render();
        wangTiles.finish();
        //wangTiles=null;
        kMeans.prepare(wangTiles.pointsOut);
        mode++;
      }
      break;
    case 1:
      image(img,0,0);
      if(kMeans.step()) kMeans.render();
      else {
        kMeans.finish();
        //kMeans=null;
        delaunayTriangulation.prepare(kMeans.clustersOut);
        mode++;
      }
      break;
    case 2:
      image(img,0,0);
      // this mode is instantaneous
      while(delaunayTriangulation.step());
      // this mode is a neat visualization
      //if(delaunayTriangulation.step()) {
      //  kmeans.render();
      //  delaunayTriangulation.render();
      //} else
      {
        delaunayTriangulation.finish();
        kernighanLin.prepare(kMeans.pointsOut,delaunayTriangulation);
        mode++;
      }
      break;
    case 3:
      image(img,0,0);
      if(kernighanLin.step()) {
        kernighanLin.render();
        //delaunayTriangulation.render();
      } else {
        kernighanLin.finish();
        scribbler.prepare(kernighanLin.pointsOut);
        mode++;
      } 
      break;
    case 4: 
      if(scribbler.step()) {
        scribbler.render();
      } else {
        // done
        scribbler.render();
        scribbler.finish();
        writeGCode.prepare(scribbler.pointsOut);
        writeSVG.prepare(scribbler.pointsOut);
        mode++;
      }
      break;
    case 5:
      if(writeGCode.step()) {
        //scribbler.render();
      } else {
        writeGCode.finish();
        mode++;
      }
      break;
    case 6:
      if(writeSVG.step()) {
        //scribbler.render();
      } else {
        writeSVG.finish();
        mode++;
      }
      break;
    default:
      noLoop();
      break;
  }
}
