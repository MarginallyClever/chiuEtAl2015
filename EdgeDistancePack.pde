class EdgeDistancePack implements Comparable<EdgeDistancePack> {
  Edge2D edge;
  float distance;
  
  EdgeDistancePack(Edge2D e1,float d1) {
    edge=e1;
    distance=d1;
  }

  public int compareTo(EdgeDistancePack o) {
    return Float.compare(this.distance, o.distance);
  }
}
