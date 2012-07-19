require 'rubygems'
require 'rubystats'
require 'optparse'
require "properties-ruby"
require "time"
require 'launchy'

# this module defines the following:
# Lifecastor::Plan class to represent a financial planning/simulation
# Lifecastor.run method to make a financial forecast for the family

# TODO
# retirement, death, estate planning, catastrophical events/life insurance, random income, random inflation, will, estate stats 

module Lifecastor

  # global constants
  INFINITY = 99999999999999999

  class Plan
    def initialize(result_array, result_hash, plan_props, cmd_line_opts, filing_status, children, savings, income, expense, inflation)
      @result_array = result_array # year by income, tax, expense, ...
      @result_hash = result_hash
      @plan_props = plan_props
      @cmd_line_opts = cmd_line_opts
      @age = income[1]
      @age_to_retire = income[2]
      @years_to_work = @age_to_retire > @age ? @age_to_retire - @age : 0
      @income = Income.new(income)

      @expense = Expense.new('food', expense, inflation)

      @tax = Tax.new(filing_status)

      @savings = Savings.new(savings)
    end

    # returns 1 or 0 for bankrupt or not
    def run
      rv = 0
      printf("%-4s%13s%13s%13s%13s%13s%13s%13s\n", 
             "Age", "Income", "Taxable", "Federal", "State", "Expense", "Leftover", "Savings") if @cmd_line_opts[:verbose]
      (@plan_props.life_expectancy.to_i-@age+1).times { |y|
        income = @income.of_year(y)
  
        deduction = @tax.std_deduction
        taxable_income = income > deduction ? income - deduction : 0
        
        federal_tax = taxable_income * @tax.federal(taxable_income)
        state_tax = taxable_income * @tax.state(taxable_income)
  
        expense = @expense.normal_cost(@plan_props, y, y >= @years_to_work, y+@age == @plan_props.life_expectancy.to_i)
  
        leftover = income - expense - federal_tax - state_tax
  
        emergence_fund = @savings.balance
        net = emergence_fund + leftover
  
        @savings.update(net) # update family savings
        
        output(y+@age, income, taxable_income, federal_tax, state_tax, expense, leftover, net) if @cmd_line_opts[:verbose]
  
        save_yearly_result(y+@age, y, income, taxable_income, federal_tax, state_tax, expense, leftover, net)

        if net < 0.0 #if net < 0.0 and y < @plan_props.life_expectancy.to_i-@age # not counting last year
          if rv == 0 # only print out bankrupt once
            puts "BANKRUPT at age #{y+@age}!" 
            output(y+@age, income, taxable_income, federal_tax, state_tax, expense, leftover, net) if !@cmd_line_opts[:verbose]
          end
          rv = 1
        end
      }
      rv 
    end

    def output(age, income, taxable_income, federal_tax, state_tax, expense, leftover, net)
      printf("%3d %13.0f%13.0f%13.0f%13.0f%13.0f%13.0f%13.0f\n", 
             age, income, taxable_income, federal_tax, state_tax, expense, leftover, net)
    end

    private

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
    def initialize(bal, rate=0.002)
      @bal = bal
      @rate = rate # 0.1%
    end
  
    def balance
      @bal*(1.0 + @rate)
    end
  
    def update(bal)
      @bal = bal
    end
  end
  
  class Income
    def initialize(income)
      @base = income[0]
      @age = income[1]
      @age_to_retire = income[2]
      @inc_m = income[3]
      @inc_sd = income[4]
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
      inc = Rubystats::NormalDistribution.new(@inc_m, @inc_sd).rng
      @base = @base*(1.0 + inc)
      n < @years_to_work ? @base : ss
    end
  end
  
  class Expense
    def initialize(c, expense, inf)
      @cat = c
      @mean = expense[0]
      @sd = expense[1]
      @inf_m = inf[0]
      @inf_sd = inf[1]
    end
  
    def cost(n) # need to inflation adjust here
      inf = Rubystats::NormalDistribution.new(@inf_m, @inf_sd).rng
      lo = (@mean-2*@sd)*(1.0 + inf)**n
      up = (@mean+2*@sd)*(1.0 + inf)**n
      rand(lo..up)
    end
  
    def normal_cost(p, n, retired, dead) 
      inf = Rubystats::NormalDistribution.new(@inf_m, @inf_sd).rng
      @mean = @mean*(1.0 + inf) # inflation adjust here
      if n < 2
        mean = p.first_two_year_factor.to_f*@mean
        sd   = p.first_two_year_factor.to_f*@sd
      elsif dead
        mean = 0.5 * (retired ? p.expense_after_retirement.to_f*@mean : @mean) # adjust down to 80% after retirement
        sd   = 0.5 * (retired ? p.expense_after_retirement.to_f*@sd : @sd)
      else
        mean = retired ? p.expense_after_retirement.to_f*@mean : @mean # adjust down to 80% after retirement
        sd   = retired ? p.expense_after_retirement.to_f*@sd : @sd
      end
      Rubystats::NormalDistribution.new(mean, sd).rng
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
  def form_html_and_chart_it(title, header, chart1, res_array) # assuming that what-to-chart is an array containing column names

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


# This hash will hold all of the options parsed from the command-line by OptionParser.
cmd_line_opts = {}

optparse = OptionParser.new do|opts|
  # Set a banner, displayed at the top of the help screen.
  opts.banner = "Usage: ruby #{__FILE__} [options]"

  # Define the options, and what they do
  cmd_line_opts[:verbose] = false
  opts.on( '-v', '--verbose', 'Output complete output' ) do
    cmd_line_opts[:verbose] = true
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


plan_props = Utils::Properties.load_from_file("planning.properties", true)

# user data from properties file
seed_offset = plan_props.seed_offset.to_i
filing_status = plan_props.filing_status
children = [['Kyle', 12], ['Chris', 10]] # [name, age]
savings = plan_props.savings.to_i # more or less like emergence fund
income = [plan_props.income.to_i, plan_props.age.to_i, plan_props.age_to_retire.to_i, plan_props.increase_mean.to_f, plan_props.increase_sd.to_f]
expense = [plan_props.expense_mean.to_i, plan_props.expense_sd.to_i]
inflation = [plan_props.inflation_mean.to_f, plan_props.inflation_sd.to_f]
total = plan_props.total_number_of_scenario_runs.to_i


def average_scenario(res_set)
  avg_res = Array.new
  seeds = res_set.length
  years = res_set[0].length
  cols  = res_set[0][0].length
  years.times {|y|
    avg_res[y] = Array.new
    cols.times {|c|
      avg_res[y][c] = 0.0
      res_set.length.times {|s|
        avg_res[y][c] += res_set[s][y][c]
      }
    }
  }

  years.times {|y| cols.times {|c| avg_res[y][c] /= seeds } }
  avg_res
end

# run many times to get an average view of the overall financial forecast
count = 0
# result array indexed by seeds, each is a hash keyed by 'income, expense, ...' and valued by its time series array
result_set_in_hash = [] 
result_set_in_array = [] # result array indexed by seeds, each is 2-d of income, tax, expense, ... by age
total.times { |seed|
  srand(seed+seed_offset) # make the randam repeatable; without it, the random will not repeat

  result_set_in_hash << result_hash = Hash.new # stores the planning result hashed on income, tax, expense, ...
  result_set_in_array << result_array = Array.new # stores planning result on income, tax, expense, ... by years

  count += Lifecastor::Plan.new(result_array, result_hash, plan_props, cmd_line_opts, filing_status, children, savings, income, expense, inflation).run
}
puts "Bankrupt probability is #{count.to_f/total*100.0}%"


header = ["Age", "Income", "Taxable", "Federal", "State", "Expense", "Leftover", "Savings"]
# initialize charts; it's empty if properties said so
chart1 = plan_props.what_to_chart1.empty? ? '' : plan_props.what_to_chart1.split(',')
chart2 = plan_props.what_to_chart2.empty? ? '' : plan_props.what_to_chart2.split(',')

c = Chart.new
c.form_html_and_chart_it('All', header, chart1, result_set_in_array[58])
sleep 3
c.form_html_and_chart_it('Savings', header, chart2, result_set_in_array[58])

#puts average_scenario(result_set_in_array)
