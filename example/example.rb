require 'rubygems'
require '../HeatMap'

require 'rubygems'

# In this example we use EDWARDS-BELL-OHLSON algorithm to compute the intrinsic
# value of a company based on financial information and forecasts
#
# The code is adapted from https://github.com/sotoseattle/EBOlve
#
# We want to see how the iintrinsic value varies when:
#  - long_term_growth ranges from 5% to 35% => x (top to botom)
#  - discount_rate ranges from 8% to 18%    => y (left to right)

class Ebolve
  attr_accessor :ltg, :r

  def initialize (input)
    @eps1 = input[:eps1]                    # forecasted eps Year 1
    @eps2 = input[:eps2]                    # forecasted eps Year 2, not neg
    @book_s = input[:book_s]                # starting book value
    @FROE = input[:FROE]                    # long term equilibrium ROE, not neg
    @retain = 1.0 - input[:pYOUT]           # % dividend payout, format 0.16
    @years = input[:years]                  # total years horizon, i.e. 12
    @growth_years = input[:growth_years]    # years of LTG, i.e. 5
    @ltg = input[:ltg]                      # contant rate of eps growth, format 0.25
    @r = input[:r]                          # discount rate, format 0.08
    self
  end

  def compute_ebo
    eps, roe, abn_eps, cum_ab_eps, eps_g = 0.0, 0.0, 0.0, 0.0, 0.0
    bv = @book_s
    roe_step = nil
    
    in_eps = [@eps1, @eps2]
    @growth_years.times{|i| in_eps << in_eps.last*(1 + @ltg)}
    
    (0..@years-1).each do |year|
      if year <= 1 + @growth_years
        bv += eps * @retain
        eps = in_eps[year]
        roe = eps / bv
      else
        roe_step ||= (@FROE - roe) / (@years - @growth_years - 2)
        bv *= 1 + (roe * @retain)
        roe += roe_step

        eps_g = eps
        eps = bv * roe
        eps_g = (eps-eps_g)/eps_g
      end
      
      abn_eps = (roe - @r) * bv
      cum_ab_eps += abn_eps / ((1 + @r)**(year+1))
    end

    terminal_Value = ((@FROE - @r) * bv) / (@r * (1 + @r)**@years)
    
    return (@book_s + cum_ab_eps + terminal_Value)
  end
end

# An ad-hoc wrapper class so the computing function depends only 
# on 2 params: long_term_growth and discount_rate
class EBO_Wrap

  def initialize(x_var, y_var, inputs)
    @ebo = Ebolve.new(inputs)
    @x, @y = x_var, y_var
  end

  def alghorithm(x_value, y_value)
    @ebo.instance_variable_set("@#{@x}", x_value)
    @ebo.instance_variable_set("@#{@y}", y_value)
    @ebo.compute_ebo
  end
end


# Initialize wrapper and definition of lambda with method
initial_inputs = {:eps1=>1.24, :eps2=>1.54, :ltg=>0.241, :book_s=>5.11, :FROE=>0.2,\
                  :r=>0.0960, :pYOUT=>0.16, :years=>12, :growth_years=>5}

w = EBO_Wrap.new(:ltg, :r, initial_inputs)
block = w.method(:alghorithm)

# Initialize the image with inputs, generate and save heat map
h = HeatMap.new :width => 300, :height => 500, :contours => 3,
                :x_range => (0.00..0.20), :y_range => (0.08..0.18), &block

h.generate_image
h.save_img('ebo_output.png')
h.legend.save('ebo_output_legend.png', :fast_rgb)
puts h.metadata.inspect






