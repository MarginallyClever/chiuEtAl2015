
class Edge2D {

  // CONSTANTS

  static final int LEFT_SIDE  = 2;
  static final int COINCIDENT = 1;
  static final int RIGHT_SIDE = 0;


  // VARIABLES

  Point2D a;
  Point2D b;

  // METHODS

  Edge2D() {
  }
  Edge2D(Point2D aa, Point2D bb) {
    a=aa;
    b=bb;
  }

  boolean includes(Point2D arg0) {
    return a==arg0 || b==arg0;
  }

  // returns LEFT_SIDE, RIGHT_SIDE, or COINCIDENT
  // See https://stackoverflow.com/questions/1560492/how-to-tell-whether-a-point-is-to-the-right-or-left-side-of-a-line
  int whereAmI(Point2D testPoint) {
    float v = (b.x - a.x) * (testPoint.y - a.y) - (b.y - a.y) * (testPoint.x - a.x);

    if (v>EPSILON) return LEFT_SIDE;
    if (v<EPSILON) return RIGHT_SIDE;
    // else must be
    return COINCIDENT;
  }
}
