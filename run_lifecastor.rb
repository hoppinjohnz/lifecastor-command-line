require 'rubygems'
require 'rubystats'
require 'optparse'
require "properties-ruby"
require "time"
require 'launchy'

module Utl
  def l_bounded(v, m, sd)
    l = m - 2.0*sd
    v < l ? l : v
  end
  def u_bounded(v, m, sd)
    u = m + 2.0*sd
    v > u ? u : v
  end
end

# this module defines the following:
# Lifecastor::Plan class to represent a financial planning/simulation
# Lifecastor.run method to make a financial forecast for the family

# TODO
# retirement, death, estate planning, catastrophical events/life insurance, random income, random inflation, will, estate stats 

module Lifecastor

  # global constants
  INFINITY = 99999999999999999

  class Plan
    def initialize(seed, result_array, result_hash, p_prop, cl_opt)
      @seed = seed
      @result_array = result_array # year by income, tax, expense, ...
      @result_hash = result_hash
      @p_prop = p_prop
      @cl_opt = cl_opt
      @age = p_prop.age.to_i
      @age_to_retire = p_prop.age_to_retire.to_i
      @years_to_work = @age_to_retire > @age ? @age_to_retire - @age : 0
      @income = Income.new(p_prop)

      @expense = Expense.new('food', p_prop)

      @tax = Tax.new(p_prop.filing_status)

      @savings = Savings.new(p_prop)

      @bankrupt = 0 # 0 or 1
      @bankrupt_age = 0
    end

    def bankrupt_age
      @bankrupt_age
    end

    def bankrupt
      @bankrupt
    end

    def run
      puts "Scenario #{@seed+1}"
      printf("%-4s%13s%13s%13s%13s%13s%13s%13s\n", 
             "Age", "Income", "Taxable", "Federal", "State", "Expense", "Leftover", "Savings") if @cl_opt[:verbose]
      (@p_prop.life_expectancy.to_i-@age+1).times { |y|
        income = @income.of_year(y)
  
        deduction = @tax.std_deduction
        taxable_income = income > deduction ? income - deduction : 0
        
        current_age = y + @age
        expense = @expense.normal_cost(@p_prop, y, y >= @years_to_work, current_age == @p_prop.life_expectancy.to_i)
  
        adjusted, state_tax, federal_tax, leftover = adjust_income_and_taxes(taxable_income, @tax.state(taxable_income), @tax.federal(taxable_income), expense)
        adjustment = adjusted - income
        taxable_income += adjustment

        if leftover > 0
          #TODO need to save the rate for auditing
          net = @savings.balance + leftover
        else
          net = @savings.balance - adjustment
        end
  
        @savings.update(net) # update family savings
        
        write_out(current_age, adjusted, taxable_income, federal_tax, state_tax, expense, leftover, net) if @cl_opt[:verbose]
  
        save_yearly_result(current_age, y, adjusted, taxable_income, federal_tax, state_tax, expense, leftover, net)

        if net < 0.0 #if net < 0.0 and y < @p_prop.life_expectancy.to_i-@age # not counting last year
          if @bankrupt == 0 # only print out bankrupt once
            puts "            BANKRUPT at age #{current_age}!" 
            write_out(current_age, adjusted, taxable_income, federal_tax, state_tax, expense, leftover, net) if !@cl_opt[:verbose]
            @bankrupt = 1
            @bankrupt_age = current_age
          end
        end
      }
    end

    private

      def static_calc(income, sr, fr, ex)
        st = sr * income
        ft = fr * (income - st)
        leftover = income - st - ft - ex
        return st, ft, leftover
      end
  
      def adjust_income_and_taxes(income, sr, fr, ex)
        st, ft, leftover = static_calc(income, sr, fr, ex)
#printf("%s%13.0f%s%13.0f%s%13.0f\n", "income = ", income, ", st = ", st, ", ft = ", ft)
        if leftover < -1 # using 0 causes too deep stack error
          income -= leftover # increase the income by -leftover to try to make the next leftover >= 0
          adjust_income_and_taxes(income, sr, fr, ex)
        else
          # this income is the increased one to drive leftover >= 0 when started with leftover < 0
          # upon return, the diff with the original income is the savings cashed out to cover the shortfall
          # at this point, leftover still can be positive
          return income, st, ft, leftover
        end
      end
  
      def write_out(age, income, taxable_income, federal_tax, state_tax, expense, leftover, net)
        printf("%3d %13.0f%13.0f%13.0f%13.0f%13.0f%13.2f%13.0f\n", 
               age, income, taxable_income, federal_tax, state_tax, expense, leftover, net)
      end
  
      def save_yearly_result(age, year, income, taxable_income, federal_tax, state_tax, expense, leftover, net)
        if year == 0
          @result_hash['age'] = Array.new << age
          @result_hash['income'] = Array.new << income.to_i
          @result_hash['taxable_income'] = Array.new << taxable_income.to_i
          @result_hash['federal_tax'] = Array.new << federal_tax.to_i
          @result_hash['state_tax'] = Array.new << state_tax.to_i
          @result_hash['expense'] = Array.new << expense.to_i
          @result_hash['leftover'] = Array.new << leftover.to_i
          @result_hash['net'] = Array.new << net.to_i
        else
          @result_hash['age'] << age
          @result_hash['income'] << income.to_i
          @result_hash['taxable_income'] << taxable_income.to_i
          @result_hash['federal_tax'] << federal_tax.to_i
          @result_hash['state_tax'] << state_tax.to_i
          @result_hash['expense'] << expense.to_i
          @result_hash['leftover'] << leftover.to_i
          @result_hash['net'] << net.to_i
        end
  
        @result_array[year] = Array.new
        @result_array[year] << age
        @result_array[year] << income.to_i
        @result_array[year] << taxable_income.to_i
        @result_array[year] << federal_tax.to_i
        @result_array[year] << state_tax.to_i
        @result_array[year] << expense.to_i
        @result_array[year] << leftover.to_i
        @result_array[year] << net.to_i
      end
  end

  class Savings
    include Utl
    def initialize(p_prop)
      @bal = p_prop.savings.to_i
      @rate_m = p_prop.savings_rate_mean.to_f
      @rate_sd = p_prop.savings_rate_sd.to_f
    end
  
    def balance
      #rate = Rubystats::NormalDistribution.new(@rate_m, @rate_sd).rng
      rate = u_bounded(Rubystats::NormalDistribution.new(@rate_m, @rate_sd).rng, @rate_m, @rate_sd)
      @bal = @bal*(1.0 + rate)
    end
  
    def update(bal)
      @bal = bal
    end
  end
  
  class Income
    include Utl
    def initialize(p_prop)
      @base = p_prop.income.to_i
      @age = p_prop.age.to_i
      @age_to_retire = p_prop.age_to_retire.to_i
      @inc_m = p_prop.increase_mean.to_f
      @inc_sd = p_prop.increase_sd.to_f
      @years_to_work = @age_to_retire > @age ? @age_to_retire - @age : 0
    end
  
    def of_year(n)
      # before retirement normal income, after retirement ss
      # 62   17016
      # 66.5 24984
      # 70   34092
      ss = case @age_to_retire
           when 0..61 then 0
           when 62..66 then 17016
           when 67..69 then 24984
           when 70..INFINITY then 34092
           else raise "Unknown age to retire: #{age_to_retire}"
           end
      #inc = Rubystats::NormalDistribution.new(@inc_m, @inc_sd).rng
      inc = u_bounded(Rubystats::NormalDistribution.new(@inc_m, @inc_sd).rng, @inc_m, @inc_sd)
      @base = @base*(1.0 + inc)
      n < @years_to_work ? @base : ss
    end
  end
  
  class Expense
    include Utl
    def initialize(c, p_prop)
      @cat = c
      @mean = p_prop.expense_mean.to_i
      @sd = p_prop.expense_sd.to_i
      @inf_m = p_prop.inflation_mean.to_f
      @inf_sd = p_prop.inflation_sd.to_f
    end
  
    def cost(n) # need to inflation adjust here
      inf = Rubystats::NormalDistribution.new(@inf_m, @inf_sd).rng
      lo = (@mean-2*@sd)*(1.0 + inf)**n
      up = (@mean+2*@sd)*(1.0 + inf)**n
      rand(lo..up)
    end
  
    def normal_cost(p, n, retired, dead) 
      #inf = Rubystats::NormalDistribution.new(@inf_m, @inf_sd).rng
      inf = l_bounded(Rubystats::NormalDistribution.new(@inf_m, @inf_sd).rng, @inf_m, @inf_sd)
      @mean = @mean*(1.0 + inf) # inflation adjust here
      if n < 2
        mean = p.first_two_year_factor.to_f*@mean
        sd   = p.first_two_year_factor.to_f*@sd
#     elsif dead
#       # the year dead, 50% of cost reduced: note this is different from loss of life, planning goes on
#       mean = 0.5 * (retired ? p.expense_after_retirement.to_f*@mean : @mean)
#       sd   = 0.5 * (retired ? p.expense_after_retirement.to_f*@sd : @sd)
      else
        mean = retired ? p.expense_after_retirement.to_f*@mean : @mean # adjust down to 80% after retirement
        sd   = retired ? p.expense_after_retirement.to_f*@sd : @sd
      end
      l_bounded(Rubystats::NormalDistribution.new(mean, sd).rng, mean, sd)
    end
  end
  
  class Child < Expense
    def initialize(c, lo, up, inf, age, base)
      super(c, lo, up, inf)
      @age = age
      @base = base
    end
    
    # http://visualeconomics.creditloan.com/how-much-does-it-really-cost-to-raise-a-kid/
    def expense(n) # age dependent expenses like child care, elementary, middle, high schools
      case age + n # age can be negative: -3 means expecting a child in 4 years
      when  -INFINITY..-1 then 0
      when          0.. 2 then 11700
      when          3.. 5 then 11730
      when          6.. 8 then 11650
      when          9..11 then 12420
      when         12..14 then 13090
      when         15..17 then 13530
      when         18..22 then 30000
      else 1000
      end
    end
  end

  class Tax
    def initialize(filing_status)
      @fs = filing_status
    end

    def std_deduction
      case @fs
        when "single"                    then  5700 # for 2011
        when "married_filing_separately" then  5700
        when "married_filing_jointly"    then 11400
        when "head_of_household"         then  8400
        when "qualifying_window"         then 11400
        else raise "Unknown filing_status: #{fs}"
      end
    end
  
    def federal(income)
      case income.to_i
        when -INFINITY..  0   then 0.00 # added to deal with below 0 taxable income
        when      0..  8700   then 0.10 # projected for 2012
        when   8701.. 35350   then 0.15
        when  35351.. 85650   then 0.25
        when  85651..178650   then 0.28
        when 178651..388350   then 0.33
        when 388351..INFINITY then 0.35
        else raise "Unknown income: #{income} in Tax::federal"
      end
    end
  
    def state(income)
      case income.to_i
        when -INFINITY.. 2760    then 0.00 # projected for 2012
        when      2761.. 5520    then 0.03
        when      5521.. 8280    then 0.04
        when      8281..11040    then 0.05
        when     11041..13800    then 0.06
        when     13801..INFINITY then 0.07
        else raise "Unknown income: #{income} in Tax::state"
      end
    end
  end
  
  # those below are not used yet
  class Account
    attr_accessor :type, :base
  
    def initialize(t, b, r)
      @type = t
      @balance = b
      @return = r
    end
  
    def balance(n)
      @base*(1.0 + @return)**n
    end
  end
  
  class Mortgage
    attr_reader :value, :equity, :payment
    # has a mortgage, maybe not
    def initialize(loan, rate, period)
     #mort = MortgageCalc::MortgageUtil.new(loan, rate, period, lender_fee, points)
      mort = MortgageCalc::MortgageUtil.new(loan, rate, period, 0.0,        0.0)
      @payment = mort.monthly_payment
    end
  
    # increase in value
    def appreciation
      @value * 0.05
    end
  end
  
  class Car
    attr_reader :payment
    # car payment, maybe not
    def initialize(p)
      @payment = p
    end
  end
end


class Chart
  def form_html_and_chart_it(title, header, chart1, res_array) # array containing column names

    data_to_chart = form_chart_data(header, chart1, res_array)
  
    f = File.new("#{title}.html", "w+")
    f.puts "<html>"
    f.puts "  <head>"
    f.puts "    <script type=\"text/javascript\" src=\"https://www.google.com/jsapi\"></script>"
    f.puts "    <script type=\"text/javascript\">"
    f.puts "      google.load(\"visualization\", \"1\", {packages:[\"corechart\"]});"
    f.puts "      google.setOnLoadCallback(drawChart);"
    f.puts "      function drawChart() {"
    f.puts "        var data = google.visualization.arrayToDataTable(["
  
    f.puts data_to_chart
  
    f.puts "        ]);"
    f.puts "        var options = {"
    f.puts "          title: \"#{title}\""
    #f.puts           "title: 'Company Performance',"
    #f.puts           "vAxis: {minValue: -1200000},"
    #f.puts           "vAxis: {gridlines: {count: 3}},"
    #f.puts           "vAxis: {maxValue: 1200000}"
    f.puts "        };"
    f.puts "        var chart = new google.visualization.LineChart(document.getElementById('chart_div'));"
    f.puts "        chart.draw(data, options);"
    f.puts "      }"
    f.puts "    </script>"
    f.puts "  </head>"
    f.puts "  <body>"
    f.puts "    <div id=\"chart_div\" style=\"width: 900px; height: 400px;\"></div>"
    f.puts "  </body>"
    f.puts "<html>"
    f.close
    Launchy.open("#{title}.html")
  end

  private

    def sub_array_indexes(subarray, superarray) # return the array of indexes into superarray indicating where subarray are
      return nil if subarray.empty?
      m = Array.new # to store indexes of subarray into superarray
      subarray.each {|w|
        superarray.length.times {|i|
          if w.include?(superarray[i])
            m << i
            break
          end
        }
      }
      puts 'Error: m.legnth != subarray.length' if m.length != subarray.length
      m
    end
    
    def form_chart_data(header, what_to_chart, res_array) # what-to-chart is an array containing column names
      return nil if what_to_chart.empty?
      s = '          ["Age", '
      length = what_to_chart.length
      done = length - 1
      length.times {|i|
        if i != done
          s << (what_to_chart[i] + ', ')
        else
          s << (what_to_chart[i] + "],\n")
        end
      }
    
      match = sub_array_indexes(what_to_chart, header)
    
      # process the data time serieses
      years = res_array.length
      if match.length == 1 # a special case
        years.times {|y|
          done = years-1
          s << "          [\'#{res_array[y][0]}\', "
          if y != done
            s << res_array[y][match[0]].to_s+"],\n"
          else # for last row or year
            s << res_array[y][match[0]].to_s+"]\n"
          end
        }
      else
        years.times {|y|
          done = years-1
          s << "          [\'#{res_array[y][0]}\', "
          if y != done
            match.length.times {|i| 
              done = match.length-1
              if i == 0
                s << res_array[y][match[i]].to_s+", "
              elsif i != done
                s << res_array[y][match[i]].to_s+', ' 
              else # for the last column
                s << res_array[y][match[i]].to_s+"],\n"
              end
            }
          else # for last row or year
            match.length.times {|i| 
              done = match.length-1
              if i == 0
                s << res_array[y][match[i]].to_s+", "
              elsif i != done
                s << res_array[y][match[i]].to_s+', ' 
              else # for the last column
                s << res_array[y][match[i]].to_s+"]\n"
              end
            }
          end
        }
      end
      s
    end
end


# TODO need to use a simple array then methods to make it into a 3-d array
def average_scenario(res_set) # seed x year x col
  seeds = res_set.length
  years = res_set[0].length
  cols  = res_set[0][0].length

  avg_res = Array.new         # year x col
  years.times {|y|
    avg_res[y] = Array.new
    cols.times {|c|
      avg_res[y][c] = 0.0
      res_set.length.times {|s|
        avg_res[y][c] += res_set[s][y][c]
      }
    }
  }

  years.times {|y| 
    cols.times {|c| 
      avg_res[y][c] /= seeds 
      avg_res[y][c] = avg_res[y][c].to_i if c == 0 # keep age column integer
    } 
  }
  avg_res
end


# This hash will hold all of the options parsed from the command-line by OptionParser.
cl_opt = {}

optparse = OptionParser.new do|opts|
  # Set a banner, displayed at the top of the help screen.
  opts.banner = "Usage: ruby #{__FILE__} [options]"

  # Define the options, and what they do
  cl_opt[:verbose] = false
  opts.on( '-v', '--verbose', 'Output complete output' ) do
    cl_opt[:verbose] = true
  end

  cl_opt[:chart] = false
  opts.on( '-c', '--chart', 'Chart the end resutls' ) do
    cl_opt[:chart] = true
  end

  # This displays the help screen, all programs are assumed to have this option.
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end

# Parse the command-line. Remember there are two forms
# of the parse method. The 'parse' method simply parses
# ARGV, while the 'parse!' method parses ARGV and removes
# any options found there, as well as any parameters for
# the options. What's left is the list of files to resize.
begin
  optparse.parse!
rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  puts $!.to_s  # Friendly output when parsing fails
  puts optparse
  exit
end 


p_prop = Utils::Properties.load_from_file("planning.properties", true)

# run many times to get an average view of the overall financial forecast
# result array indexed by seeds, each is a hash keyed by 'income, expense, ...' and valued by its time series array
result_set_in_hash = [] 
result_set_in_array = [] # result array indexed by seeds, each is 2-d of income, tax, expense, ... by age
count = 0
bankrupt_total_age = 0
p_prop.total_number_of_scenario_runs.to_i.times { |seed|
  srand(seed+p_prop.seed_offset.to_i) # make the randam repeatable; without it, the random will not repeat

  result_set_in_hash << result_hash = Hash.new # stores the planning result hashed on income, tax, expense, ...
  result_set_in_array << result_array = Array.new # stores planning result on income, tax, expense, ... by years

  plan = Lifecastor::Plan.new(seed, result_array, result_hash, p_prop, cl_opt)
  plan.run
  count += plan.bankrupt
  bankrupt_total_age += plan.bankrupt_age
}

printf("%s: %9.1f%s\n", "Bankrupt probability", 100 * count / p_prop.total_number_of_scenario_runs.to_f, "%")
printf("%s: %9.1f\n", "Average bankrupt age", bankrupt_total_age / count.to_f) if count != 0

printf("%s: %12s\n", "Avg estate wealth", average_scenario(result_set_in_array)[p_prop.life_expectancy.to_i-p_prop.age.to_i][7].to_i.to_s.gsub(/(\d)(?=\d{3}+(?:\.|$))(\d{3}\..*)?/,'\1,\2')) # get 123,456.123

if cl_opt[:chart]
  header = ["Age", "Income", "Taxable", "Federal", "State", "Expense", "Leftover", "Savings"]
  # initialize charts; it's empty if properties said so
  chart1 = p_prop.what_to_chart1.empty? ? '' : p_prop.what_to_chart1.split(',')
  chart2 = p_prop.what_to_chart2.empty? ? '' : p_prop.what_to_chart2.split(',')
  
  c = Chart.new
  ac = average_scenario(result_set_in_array)
  c.form_html_and_chart_it('All', header, chart1, ac)
  sleep 1
  c.form_html_and_chart_it('Savings', header, chart2, ac)
end
