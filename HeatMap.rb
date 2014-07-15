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
    @width, @height = inputs[:width].to_int, inputs[:height].to_int
    @x_range, @y_range = inputs[:x_range], inputs[:y_range]
    @contours = inputs[:contours].to_i+1
    @evaluator = function
  end

  # Compose image from pixel stream.
  def image
    ChunkyPNG::Image.new(@width, @height, pixel_stream)
  end

  # Transforms range into array of predetermined size
  def explicit_range(rango, n_steps)
    a = n_steps==0 ? 1 : n_steps
    jump = (rango.max.to_f - rango.min)/a
    rango = rango.step(jump).to_a
    rango.delete_at(-1)
    rango
  end

  private
  # Matrix where each cell stores the pairs of input values (x,y) to use.
  # Consider that x goes top to bottom (=> vertical, height)
  def inputs_matrix
    x = explicit_range(@x_range, @height)
    y = explicit_range(@y_range, @width)

    matrix_X = x.map{|e| [e]*@width}.flatten
    matrix_Y = ([y]*@height).flatten

    matrix_X.zip(matrix_Y)
  end

  # Evaluates with function each pair of inputs for each cell of the matrix.
  def compute_values 
    arr = inputs_matrix.map{|e| @evaluator.call(*e)}
    matrix = NArray[arr].reshape(@width, @height)
  end

  def colorines(contours) 
    contours = contours.map{|c| Color::HSL.new(c, HSL_SATURATION, HSL_LIGHTNESS).to_rgb.hex}
    HeatPalette::Rainbow.map{|c| contours.include?(c) ? "000000" : c}
  end

  # Scales values to color palete range. 
  # The new matrix of colors becomes the pixels of the image to return.
  def pixel_stream
    matrix_values = compute_values
    max, min = matrix_values.max.to_f, matrix_values.min.to_f
    
    factor = HeatPalette::HSL_HUE_MAX - HeatPalette::HSL_HUE_MIN - 1
    matrix_scaled = ((matrix_values - min)*factor/(max-min)).round
    
    contours_values = explicit_range(min..max, @contours).drop(1)
    contours_scaled =  contours_values.map{|e| ((e - min)*factor/(max-min)).round}
    rainbow = colorines(contours_scaled)
    
    stream = matrix_scaled.flatten.to_a
    stream.map{|e| ChunkyPNG::Color.from_hex("#{rainbow[e]}")}
  end
end
