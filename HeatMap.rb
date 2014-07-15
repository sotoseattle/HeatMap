require 'rubygems'
require 'color'
require 'chunky_png'
require 'narray'
require 'awesome_print'

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
  
  def initialize(inputs, &function)
    @width, @height = inputs[:width], inputs[:height]
    @x_range, @y_range = inputs[:x_range], inputs[:y_range]
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
  # Matrix where each cell stores the pairs of input values (x,y) to use.
  # Consider that x goes top to bottom (=> vertical, height)
  def inputs_matrix
    x = explicit_range(@x_range, @height-1)
    y = explicit_range(@y_range, @width-1)

    matrix_X = x.map{|e| [e]*@width}.flatten
    matrix_Y = ([y]*@height).flatten

    matrix_X.zip(matrix_Y)
  end

  # Evaluates with function each pair of inputs for each cell of the matrix.
  def values_matrix 
    arr = inputs_matrix.map{|e| @evaluator.call(*e)}
    matrix = NArray[arr].reshape(@width, @height)
  end

  # Scales values to color palete range. 
  # The new matrix of colors becomes the pixels of the image to return.
  def pixel_stream
    matrix = values_matrix

    max, min = matrix.max.to_f, matrix.min.to_f
    factor = HeatPalette::HSL_HUE_MAX - HeatPalette::HSL_HUE_MIN - 1
    references = ((matrix - min)*factor/(max-min)).round
    stream = references.flatten.to_a

    stream.map{|e| ChunkyPNG::Color.from_hex("#{HeatPalette::Rainbow[e]}")}
  end
end
