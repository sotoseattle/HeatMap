require 'rubygems'
require 'color'
require 'chunky_png'
require 'narray'

# Utility class to generate a heat map based on a given function
# passed as a block.
# The inputs in order are:
#  - width of image in number of pixels
#  - height of image in number of pixels
#  - range of values for first parameter (x, horizontal, abcissa)
#  - range of values for second parameter (y, vertical, ordinate)
#  - the function to evaluate at each pixel of the image
#     define the block so:
#      - x, y are the only vars (all else fix inside block)
#      - x, y admit float values
#      - x will be abscissa axis and y ordinate
#      - last line of block returns a value (float)
#
# Example:
#   Nonsense_function = ->(x,y) do
#     (x**4 + y**3)
#   end
#   
#   h = HeatMap.new 200, 200, (-10..10), (-10..10), &Nonsense_function
#   h.image.save('output.png')

module HeatPalette
  HSL_HUE_MIN = 0
  HSL_HUE_MAX = 180
  HSL_SATURATION = 90
  HSL_LIGHTNESS = 50
  Rainbow = (HSL_HUE_MIN...HSL_HUE_MAX).map do |hue|
    Color::HSL.new(hue, HSL_SATURATION, HSL_LIGHTNESS).to_rgb.hex
  end
end

class HeatMap

  include HeatPalette
  
  def initialize(width, height, x_range, y_range, &function)
    @width, @height = width, height
    @x_range, @y_range = x_range, y_range
    @evaluator = function
  end

  # Compose image from pixel stream.
  def image
    ChunkyPNG::Image.new(@width, @height, pixel_stream)
  end

  # Transforms range into array of predetermined size
  def explicit_range(rango, n_steps)
    jump = (rango.max.to_f - rango.min) / n_steps
    rango.step(jump).to_a
  end

  private
  # Computes matrix where each cell stores the pairs of input 
  # values (x,y) to evaluate.
  def inputs_matrix
    x = explicit_range(@x_range, @width-1)
    y = explicit_range(@y_range, @height-1)

    matrix_X = x.map{|e| [e]*@height}.flatten
    matrix_Y = ([y]*@width).flatten

    matrix_X.zip(matrix_Y)
  end

  # Applies valuation function to each pair of inputs for each
  # cell of the matrix.
  def values_matrix 
    arr = inputs_matrix.map{|e| @evaluator.call(*e)}
    matrix = NArray[arr].reshape(@width, @height)
  end

  # Scales numeric values to the color palete range. The new matrix of
  # colors becomes the pixels of the image returned.
  def pixel_stream
    matrix = values_matrix

    #scale down to range of positions of array of available colors
    max, min = matrix.max.to_f, matrix.min.to_f
    factor = HeatPalette::HSL_HUE_MAX - HeatPalette::HSL_HUE_MIN - 1
    references = ((matrix - min)*factor/(max-min)).round
    stream = references.flatten.to_a

    # convert to chunky colored pixels
    stream.map{|e| ChunkyPNG::Color.from_hex("#{HeatPalette::Rainbow[e]}")}
  end
end