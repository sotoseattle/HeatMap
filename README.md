HeatMap
=======

Generate a PNG image of a heat map based on a given function passed as a block.

The inputs are:
 
 * width of image in number of pixels
 * height of image in number of pixels
 * range of values for first parameter (x, horizontal, abcissa)
 * range of values for second parameter (y, vertical, ordinate)
 * the function to evaluate at each pixel of the image
    
Define the block so:

 * x, y are the only vars (all else fix inside block)
 * x, y admit float values
 * x will be abscissa axis and y ordinate
 * last line of block returns a value (float)

#### Gem Requirements:

* Chunky_PNG
* Color
* NArray

#### Example:

  Nonsense_function = ->(x,y) do
    (x**2 + y**2)
  end
  
  h = HeatMap.new 200, 200, (-10..10), (-10..10), &Nonsense_function
  h.image.save('output.png')

![alt text](./output.png "Example Output")

