require 'rubygems'
require 'color'
require 'chunky_png'
require 'narray'

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

  attr_reader :img, :metadata, :legend

  LEGEND_HEIGHT = 20
  
  def initialize(inputs, &function)
    @width, @height = inputs[:width].to_int, inputs[:height].to_int
    @x_range, @y_range = inputs[:x_range], inputs[:y_range]
    @contours = inputs[:contours].to_i+1
    @evaluator = function
    @img = nil
    @metadata = {}
    @legend = nil
  end
  
  # Transforms range into array of predetermined size
  def explicit_range(rango, n_steps)
    a = n_steps==0 ? 1 : n_steps
    jump = (rango.max.to_f - rango.min)/a
    rango = rango.step(jump).to_a
    rango.delete_at(-1)
    rango
  end

  # The faster way to save the image
  def save_img(filename)
    @img.save(filename, :fast_rgb)
  end

  # Scales values to color palete range. 
  # The new matrix of colors becomes the pixels of the image to return.
  def generate_image
    matrix_values = compute_values
    max, min = matrix_values.max.to_f, matrix_values.min.to_f
    
    hue_range = HeatPalette::HSL_HUE_MAX - HeatPalette::HSL_HUE_MIN
    matrix_scaled = ((matrix_values - min)*(hue_range-1)/(max-min)).round
    
    contours_values = explicit_range(min..max, @contours).drop(1)
    contours_scaled =  contours_values.map{|e| ((e - min)*(hue_range-1)/(max-min)).round}
    rainbow = colorines(contours_scaled)
    
    @metadata["max_value"] = max
    @metadata["min_value"] = min
    @metadata["contours_values"] = contours_values
    
    legend_stream = rainbow.map{|e| ChunkyPNG::Color.from_hex(e)}
    
    @legend = ChunkyPNG::Image.new(hue_range, LEGEND_HEIGHT, legend_stream*LEGEND_HEIGHT)
    
    stream = matrix_scaled.flatten.to_a
    stream.map!{|e| ChunkyPNG::Color.from_hex("#{rainbow[e]}")}
    @img = ChunkyPNG::Image.new(@width, @height, stream).rotate_counter_clockwise
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

end
