![cover](cover.jpg "Chiu Et Al 2015")

# chiuEtAl2015

Implementation of http://cgv.cs.nthu.edu.tw/projects/Recreational_Graphics/CircularScribbleArt
Written for Processing

## Usage

Install Processing from http://processing.org
Open the chiuEtAl2015.pde file with the Processing app.
Run (the play button) and watch as it create the drawing.

## Note

Every time the app runs it will create some text files in the folder where it is run.
These text files save each step of the work so that you can tweak the last step without waiting for all the earlier steps.  That means if you want to change the earlier steps you have to delete the text files.

## Next
Adjust parameters in setup() to see different effects.

At the top of setup() you will see

    size(512,512);
    img = loadImage("lenna.png");

size(w,h) will open a window w wide and h high.  it does not have to match your image size.  Your image file goes instead of lenna.png.

    writeGCode = new WriteGCode("output.ngc");

Change "output.ngc" to the destination for your gcode file.

    wangTiles = new WangTiles(10000);

10000 is the approximate number of points that will be put across the image.  Larger images need more points to be accurately represented.

toneControl(x)  adjusts the tone of the image for better representation in a black and white medium.  it's detailed in the original paper.the 1-v are there because black is represented as 0 and white as 1.  we want the opposite for the tone control to work.  Feel free to try removing both 1-v and see what happens!  (use a small image to save time).

    scribbler = new CircularScribbler(20,10,3,2.5,0.2);

20 is the number of segments per loop, in degrees.  as this number goes up the quality goes down, but so does the size of the output file.
10,3 control the max/min size of the loops.  lighter areas, bigger loops.
2.5,0.2 are the max/min speed of the loops.  lighter areas, faster loops.
If the picture gets bigger and the loop sizes are not changed then the loops will appear smaller.

Experiment with these numbers to get a good feel, and please share your results!

## Legal

Wang Tiles (and tileset.dat) are from https://johanneskopf.de/publications/blue_noise/
Read the paper, it's excellent!

## Todo

- output results to JPG, DXF?
- tweakable parameters while running?

## Early gallery results

![a](a.JPG "A")

![b](b.JPG "B")

![c](c.JPG "C")

![d](d.JPG "D")

![e](e.JPG "E")
