HeatMap
=======

Generate a PNG image of a heat map based on a given function passed as a block.

The inputs are:
 
 * width of image in number of pixels
 * height of image in number of pixels
 * number of contour lines to draw equally spaced in max-min range (defaults to no lines)
 * range of values for first parameter (x, horizontal, abcissa)
 * range of values for second parameter (y, vertical, ordinate)
 * the function to evaluate at each pixel of the image
    
Define the block so:

 * x, y are the only vars (all else fix inside block)
 * x, y admit float values
 * x,y follow image processing coordinates mapping:
 ** x will be ordinate (from top to bottom) axis and
 ** y the abscissa (left to right)
 * last line of block returns a value (float)

#### Gem Requirements:

* Chunky_PNG
* Color
* NArray

#### Example:

```ruby
Nonsense_function = ->(x,y) do
  (x**2 + y**2)
end

h = HeatMap.new :width => 200, :height => 200, :contours => 2,
    :x_range => (-10..10), 
    :y_range => (-10..10), 
    &Nonsense_function

h.image.save('output.png')
```

![alt text](./output.png "Example Output")


