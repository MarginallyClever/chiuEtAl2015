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

    size(512,512);  img = loadImage("lenna.png");

Change the size values to match the size of your image file and "lenna.png" to your image file.

    writeGCode = new WriteGCode("output.ngc");

Change "output.ngc" to the destination for your gcode file.

    wangTiles = new WangTiles(10000);

Is a good starting number.  Later you can raise this.  In very large images in the original paper it went as high as 100k.
Start low to try many variations.

    scribbler = new CircularScribbler(0.95,25,3);

0.95 is the turning speed of the spirals.  the higher the number, the lower the quality.  0.95 is good to start.
I have been down to 0.15 but mostly I find 0.5 is good enough and already creates a huge output file.

25,3 are the largest and smallest radius of spiral.  the more points you have, the smaller your spirals can be to still get dark tones.

So, to repeat: start with a low number of tiles and a high turning speed.  when you are in the right ball park and you have nice mid-tones, then you can start to raise the number of points and decrease the smallest radius.  When you are at your final point count, lower the turning speed to ~0.5.

## Todo

- Replace Poisson stippling with Wang Tiles (https://johanneskopf.de/publications/blue_noise/)
- output results to JPG, DXF?
- tweakable parameters while running?

## Early gallery results

![a](a.JPG "A")

![b](b.JPG "B")

![c](c.JPG "C")

![d](d.JPG "D")

![e](e.JPG "E")
