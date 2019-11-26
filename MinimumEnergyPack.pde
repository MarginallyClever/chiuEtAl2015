class MinimumEnergyPack implements Comparable<MinimumEnergyPack> {
  // two clusters and their edges
  int c0;
  int c1;
  Edge2D bestF;
  Edge2D bestS;
  boolean isCrossed=true;
  float energy;
  
  MinimumEnergyPack(int c0in,int c1in,Edge2D eF,Edge2D eS,boolean crossedIn,float energyIn) {
    this.c0=c0in;
    this.c1=c1in;
    this.bestF=eF;
    this.bestS=eS;
    this.energy=energyIn;
    this.isCrossed = crossedIn; 
  }

  public int compareTo(MinimumEnergyPack o) {
    return Float.compare(this.energy, o.energy);
  }
}
