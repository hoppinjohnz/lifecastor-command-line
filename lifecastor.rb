require 'rubygems' # required for Windows
require 'rubystats'
require "properties-ruby"
require 'optparse'
require 'ostruct'
require 'launchy'


module Utl
  def l_bounded(v, m, sd);                      l = m - 2.0*sd; v < l ? l : v;                                end
  def u_bounded(v, m, sd);                      u = m + 2.0*sd; v > u ? u : v;                                end
  def zero?(v);                                 v.abs < 0.0000001 ? true : false;                             end
  def normal_rand_number(m, sd);                zero?(sd) ? m : Rubystats::NormalDistribution.new(m, sd).rng; end
  def years_to_retire(age, age_to_retire);      age < age_to_retire ? age_to_retire - age : 0;                end
  def years_to_live(age, life_expectancy);      age < life_expectancy ? life_expectancy - age : 0;            end
  def co(amount)
    if amount.zero?
      0.0
    else
      amount
    end
  end
end


# this module defines the following:
# Lifecastor::Plan class represents a specific financial plan: carry the input data, do the planning, and hold the results
# Lifecastor.run method makes a series of simulation runs for the same plan
# Lifecastor.average_simulation calculates the overall average of the simulation runs

# TODO retirement, death, estate planning, catastrophical events/life insurance, random income, random inflation, will, estate stats 

module Lifecastor
  # global constants
  INFINITY = 99999999999999999
  MINEARNFORSS = 1130 # not used

  class Plan
    include Utl
    def initialize(sim, result_array, p_prop, clopt)
      @sim          = sim # only needed for output simulation numbers
      @result_array = result_array # year by income, tax, expense, ...
      @p_prop       = p_prop
      @clopt        = clopt

      @age             = p_prop.age.to_i
      @age_to_retire   = p_prop.age_to_retire.to_i
      @life_expectancy = p_prop.life_expectancy.to_i
      @age_            = p_prop.age_.to_i
      @age_to_retire_  = p_prop.age_to_retire_.to_i

      # TODO liabilities, children, ...
      @income  = Income.new(p_prop)
      @expense = Expense.new(p_prop)
      @tax     = Tax.new(p_prop)
      @savings = Savings.new(p_prop)

      # TODO will have more data points to collect
      @bankrupt     = 0 # binary 0 or 1; used for counting total bankrupts
      @bankrupt_age = 0
    end

    def bankrupt
      @bankrupt
    end

    def bankrupt_age
      @bankrupt_age
    end

    def write_header_out(clopt, sim)
      puts "Simulation #{sim+1}"
      if clopt.taxed_savings and clopt.verbose
        format = "%-4s%13s%22s%22s%22s%22s%22s%13s%14s\n" 
        printf(format, "Age", "Income", "Taxable", "Federal", "State", "Total Tax", "Expense", "Leftover", "Net Worth") 
      elsif clopt.verbose
        format = "%-4s%13s%13s%13s%13s%13s%13s%13s%13s\n"
        printf(format, "Age", "Income", "Taxable", "Federal", "State", "Total Tax", "Expense", "Leftover", "Net Worth") 
      else
        return
      end
    end

    def run
      write_header_out(@clopt, @sim) if @clopt.brief or @clopt.verbose
      (@p_prop.life_expectancy_.to_i-@age+1).times { |y|
        income         = @income.total(y)
        deduction      = @tax.std_deduction
        taxable_income = income > deduction ? income - deduction : 0
        current_age    = y + @age
        current_age_    = y + @age_
        expense        = @expense.total(y)
        st             = @tax.state_tax(income)
        ft             = @tax.federal_tax(income)
        leftover       = income - st - ft - expense
  
        # note: expense column is the same for both -f and -t as a result of the same number calls to rand method
        if @clopt.taxed_savings # tax savings
          adj_income, state_tax, federal_tax, adj_leftover = afloat_income(@tax, income, expense)
          cashed_savings = adj_income - income # cashed out savings to make up the shortfall if leftover < 0
  
          if adj_leftover > 0
            net = @savings.balance + adj_leftover   # increase savings: adj_leftover = leftover???
          else
            net = @savings.balance - cashed_savings # decrease savings
          end
          @savings.update(net) # update family savings
          adjusted_write_out(current_age, current_age_, income, income+cashed_savings, taxable_income, adj_income-deduction, 
                             ft, federal_tax, st, state_tax, expense, leftover, net) if @clopt.verbose
  
          # re-assign back so that the save result routine can still work
          income += cashed_savings
  
        else # no tax on savings is simpler to understand, this is the default
          net = @savings.balance + leftover
          @savings.update(net) # update family savings
          write_out(current_age, current_age_, income, taxable_income, ft, st, expense, leftover, net) if @clopt.verbose
        end

        save_yearly_result(current_age, y, income, taxable_income, ft, st, expense, leftover, net)

        if net < 0.0 #if net < 0.0 and y < @p_prop.life_expectancy.to_i-@age # not counting last year
          if @bankrupt == 0 # only print out bankrupt once
            @bankrupt = 1
            @bankrupt_age = current_age                                         # not to be called for -bv, only called for -b
            write_out(current_age, current_age_, income, taxable_income, ft, st, expense, leftover, net) if @clopt.brief and !@clopt.verbose 
            puts "      BANKRUPT at age #{current_age}!" if @clopt.brief or @clopt.verbose
          end
        end
      }
    end

    private

      # this where to use capital gain tax rates
      def calculate_taxes_and_leftover(tax, income, ex)
        st = tax.state_tax(income)
        ft = tax.federal_tax(income) # taking st away may reduced the tax bracket
        leftover = income - st - ft - ex
        return st, ft, leftover
      end
  
      # only call this when leftover < 0, ie, there is a shortfall and need to cash out savings
      # 1. get st
      # 2. get ft
      # 3. leftover = income - st - ft - expense
      # 4. if leftover < 0, let income = income - leftover and goto back to 1.
      #    ow, done: return income, st, ft, leftover
      def afloat_income(tax, income, ex)
        st, ft, leftover = calculate_taxes_and_leftover(tax, income, ex)
#printf("%s%13.0f%s%13.0f%s%13.0f\n", "income = ", income, ", st = ", st, ", ft = ", ft)
        if leftover < -1 # using 0 causes too deep stack error
          income -= leftover # increase the income by -leftover to try to make the next leftover >= 0
          afloat_income(tax, income, ex)
        else
          # this income is the increased one to drive leftover >= 0 when started with leftover < 0
          # upon return, the diff with the original income is the savings cashed out to cover the shortfall
          # at this point, leftover still can be positive
          return income, st, ft, leftover
        end
      end
  
      def add_indicators(age, age_, format)
        format = "r"+format if age_ >= @age_to_retire_
        if age >= @life_expectancy
          format = "L"+format
        elsif age >= @age_to_retire
          format = "R"+format
        end
        format # needed
      end

      def write_out(age, age_, income, t_income, ft, st, expense, leftover, net)
        format = "%3d %13.0f%13.0f%13.0f%13.0f%13.0f%13.0f%13.0f%13.0f\n"
        printf(add_indicators(age, age_, format), age, co(income), co(t_income), co(ft), co(st), co(ft+st), co(expense), co(leftover), co(net))
      end
  
      def adjusted_write_out(age, age_, income, a_income, t_income, a_t_income, ft, aft, st, ast, expense, leftover, net)
        format = "%3d %13.0f/%-10.0f%11.0f/%-10.0f%11.0f/%-10.f%11.0f/%-10.f%11.0f/%-10.0f%11.0f%13.0f%14.0f\n"
        printf(add_indicators(age, age_, format), age, co(income), co(a_income), co(t_income), co(a_t_income), co(ft), co(aft), co(st), co(ast), co(ft+st), co(aft+ast), co(expense), co(leftover), co(net))
      end
  
      def save_yearly_result(age, year, income, taxable_income, federal_tax, state_tax, expense, leftover, net)
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
      rate = u_bounded(normal_rand_number(@rate_m, @rate_sd), @rate_m, @rate_sd)
      @bal*(1.0 + rate)
    end
  
    def update(bal)
      @bal = bal
    end
  end
  
  class Income
    include Utl
    def initialize(p_prop)
      @age           = p_prop.age.to_i
      @age_to_retire = p_prop.age_to_retire.to_i
      @inc_m         = p_prop.increase_mean.to_f
      @inc_sd        = p_prop.increase_sd.to_f
      @base          = p_prop.income.to_i

      @age_           = p_prop.age_.to_i
      @age_to_retire_ = p_prop.age_to_retire_.to_i
      @inc_m_         = p_prop.increase_mean_.to_f
      @inc_sd_        = p_prop.increase_sd_.to_f
      @base_          = p_prop.income_.to_i
      @life_expectancy = p_prop.life_expectancy.to_i

      @spousal_ss_benefit_factor = p_prop.spousal_ss_benefit_factor.to_f
      @years_to_retire = years_to_retire(@age, @age_to_retire)
      @years_to_retire_ = years_to_retire(@age_, @age_to_retire_)
      @years_to_live = years_to_live(@age, @life_expectancy)

      # make sure spousal ss benefit factor and income are mutually exlucsive
      if zero? @base_
        if zero? @spousal_ss_benefit_factor
#          puts "\nWarning: Spousal SS benefit factor = 0. Give it a value greater than 0 in the plan properties file.\n" 
        end
        @inc_m_ = @inc_sd_ = 0.0
      end
    end
  
    def total(n)
      # spousal benefit is lower if spouse income = 0: 
      # http://www.foxbusiness.com/personal-finance/2012/07/16/smart-social-security-strategies-for-couples/
      # before retirement normal income, after retirement ss
      # 62   17016
      # 66.5 24984
      # 70   34092
      retired = n >= @years_to_retire
      dead = n >= @years_to_live

      ss = ss(@age_to_retire)
      inc = u_bounded(normal_rand_number(@inc_m, @inc_sd), @inc_m, @inc_sd)
      @base = @base*(1.0 + inc) if n > 0 # no inc for the first plan year
      income = retired ? ss : @base
      income = dead ? 0.0 : income

      # spouse
      retired_ = n >= @years_to_retire_
      # this cal is not right: should based on earned credits
      ss_ = (n + @age_ < 62 ? 0.0 : @spousal_ss_benefit_factor * ss) # can begin spousal benefit as early as 62
      inc_ = u_bounded(normal_rand_number(@inc_m_, @inc_sd_), @inc_m_, @inc_sd_)
      @base_ = @base_*(1.0 + inc_) if n > 0 # no inc for the first plan year
      income_ = retired_ ? ss_ : @base_

      income + income_
    end

    def ss(age_to_retire)
      case age_to_retire
      when 0..61 then 0
      when 62..66 then 17016
      when 67..69 then 24984
      when 70..INFINITY then 34092
      else raise "Unknown age to retire: #{age_to_retire}"
      end
    end
  end
  
  class Expense
    include Utl
    def initialize(p_prop)
      @mean = p_prop.expense_mean.to_i
      @sd = p_prop.expense_sd.to_f
      @inf_m = p_prop.inflation_mean.to_f
      @inf_sd = p_prop.inflation_sd.to_f
      @first_two = p_prop.first_two_year_factor.to_f
      @expense_after = p_prop.expense_after_retirement.to_f
      @monthly_expense = p_prop.monthly_expense.to_f
      @start_year = p_prop.start_year.to_i
      @end_year = p_prop.end_year.to_i
      @age           = p_prop.age.to_i
      @age_to_retire = p_prop.age_to_retire.to_i
      @shift = p_prop.shift.to_f
      @health_cost_base = p_prop.health_cost_base.to_f
      @life_expectancy  = p_prop.life_expectancy.to_i
      @expense_after_life_expectancy = p_prop.expense_after_life_expectancy.to_f
      @years_to_retire = years_to_retire(@age, @age_to_retire)
      @years_to_live = years_to_live(@age, @life_expectancy)

      @age_              = p_prop.age_.to_i
      @life_expectancy_  = p_prop.life_expectancy_.to_i
      @shift_            = p_prop.shift_.to_f
      @health_cost_base_ = p_prop.health_cost_base_.to_f
      @years_to_live_    = years_to_live(@age_, @life_expectancy_)
    end
  
    def cost(n) # need to inflation adjust here
      inf = normal_rand_number(@inf_m, @inf_sd)
      lo = (@mean-2*@sd)*(1.0 + inf)**n
      up = (@mean+2*@sd)*(1.0 + inf)**n
      rand(lo..up)
    end
  
    def total(y)
      normal_cost(y) + periodic_expense(y) + health_care_cost(y, @age, @shift, @health_cost_base, @years_to_live) + health_care_cost(y, @age_, @shift_, @health_cost_base_, @years_to_live_)
    end

    def normal_cost(year) 
      retired = year >= @years_to_retire
      dead = year >= @years_to_live

      # inflation adjustment of cost
      inf = l_bounded(normal_rand_number(@inf_m, @inf_sd), @inf_m, @inf_sd)
      @mean = @mean*(1.0 + inf) 

      if year < 2 # first two year factor
        mean = @first_two*@mean
        sd   = @first_two*@sd
      else
        # adjust down to 80% if retired
        mean = (retired ? @expense_after*@mean : @mean) 
        sd   = (retired ? @expense_after*@sd   : @sd)

        # adjust down again if dead
        mean = (dead ? @expense_after_life_expectancy*mean : mean)
        sd   = (dead ? @expense_after_life_expectancy*sd   : sd)
      end
      l_bounded(normal_rand_number(mean, sd), mean, sd)
    end
  
    def health_care_cost(y, a, s, base, ytl) # aga, year, shift, base cost, years to live
      return 0.0 if zero?(base)
      return 0.0 if y >= ytl
      return 0.0 if a + y < 55 + s # 55 is the start of the cost growth
      # least square fit: http://www.akiti.ca/LinLeastSqPoly4.html 
      # 55, 100
      # 60, 110
      # 65, 150
      # 70, 180
      # 75, 230
      # 80, 300
      # 85, 400
      # 90, 600
      sa = a + y - s # shifted age
      base * (0.0009242424242415721*sa**4.0 - 0.2508585858583263*sa**3.0 + 25.596590909061494*sa**2.0 - 1155.608405481936*sa + 19507.78679650952)/100.0  
    end

    def periodic_expense(year) 
      rv = 0.0
      y = Time.new.year + year
      rv = 12.0 * @monthly_expense if @start_year < y && y <= @end_year
      rv
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
    def initialize(p_prop)
      @fs = p_prop.filing_status
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
  
    # optional tax rate, eg, capital gain rate if selling equaty
    # Tax Bracket | Capital Gain Tax Rate
    #             | Short Term   | Long Term
    # --------------------------------------
    # 10%         | 10%          | 0%
    # 15%         | 15%          | 0%
    # 25%         | 25%          | 15%
    # 28%         | 28%          | 15%
    # 33%         | 33%          | 15%
    # 35%         | 35%          | 15%
    def capital_gain_tax
    end

    def federal_tax_rate(federal_taxable_income)
      case federal_taxable_income.to_i
        when -INFINITY..  0   then 0.00 # added to deal with below 0 taxable income
        when      0..  8700   then 0.10 # projected for 2012
        when   8701.. 35350   then 0.15
        when  35351.. 85650   then 0.25
        when  85651..178650   then 0.28
        when 178651..388350   then 0.33
        when 388351..INFINITY then 0.35
        else raise "Unknown federal_taxable_income: #{federal_taxable_income} in Tax::federal"
      end
    end
  
    # not to use taxable income here but the full income
    def federal_tax(income) 
      federal_taxable_income = income - std_deduction - state_tax(income)
      federal_tax_rate(federal_taxable_income) * federal_taxable_income
    end

    # no deduction considered here
    def state_tax_rate(income)
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

    def state_tax(income)
      state_tax_rate(income) * income
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


  class Chart
    def form_html_and_chart_it(title, chart1, res_array) # array containing column names
  
      header = ["Age", "Income", "Taxable", "Federal", "State", "Expense", "Leftover", "Net Worth"]
      data_to_chart = form_chart_data(header, chart1, res_array)
    
      fn = title.gsub(/ /, '_') # just for IE: it could not handle spaces in file names
      f = File.new("#{fn}.html", "w+")
      f.puts "<html>"
      f.puts "  <head>"
      f.puts "    <script type=\"text/javascript\" src=\"lib/jsapi\"></script>" # just use local jsapi
     #f.puts "    <script type=\"text/javascript\" src=\"https://www.google.com/jsapi\"></script>"
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
      Launchy.open("#{fn}.html")
    end
  
    private
  
      def sub_array_indexes(subarray, superarray) # return an array of indexes into superarray indicating where subarray are
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
        puts "Error: m.legnth(#{m.length}) != subarray.length(#{subarray.length})" if m.length != subarray.length
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
  
  
  class Optparser
    CODES = %w[iso-2022-jp shift_jis euc-jp utf8 binary]
    CODE_ALIASES = { "jis" => "iso-2022-jp", "sjis" => "shift_jis" }
  
    # Return a structure describing the options.
    def self.parse(args)
      # The options specified on the command line will be collected in *options*. We set default values here.
      options = OpenStruct.new
      options.brief         = false
      options.chart         = false
      options.taxed_savings = false
      options.verbose       = false
      options.diff          = false
  
      opts = OptionParser.new do |opts|
#Usage: ruby #{__FILE__} [options] [planning property file of your choice]\n
        opts.banner = "
Usage: lifecastor.exe [options] [planning property file of your choice]\n
    Options are explained below. They can be combined.\n
    To make a simplest run, type:
        lifecastor.exe
    Then, hit enter key.\n
    To run on your own planning property file named 'my_planning_properties', type:
        lifecastor.exe my_planning_properties
    Then, hit enter key.\n
    To combine the above run with option -v, type:
        lifecastor.exe -v my_planning_properties"
  
        opts.separator "" # nice formatter for the usage and help show
        opts.separator "Specific options:"
  
        # Boolean switch.
        opts.on( '-b', '--brief', 'Output brief resutls of bankrupt info. Use -v to see more detaills.' ) do |b|
          options.brief = b
        end
  
        opts.on( '-c', '--chart', 'Chart the resutls as configured by your plan.propreties file.' ) do |c|
          options.chart = c
        end
  
        # need to combine with -v to get complete output
        opts.on( '-t', '--taxed_savings', 'Tax savings at short term capital gain tax rates which are the same as regular income tax rates.' ) do |t|
          options.taxed_savings = t
        end
      
        opts.on( '-v', '--verbose', 'Output the complete resutls.' ) do |v|
          options.verbose = v
        end
  
        # use this option when run within rails
        opts.on( '-q', '--quiet', 'Output nothing to the standard output.' ) do |q|
          options.quiet = q
        end
  
        opts.on( '-d', '--diff', 'Show the difference between last and current results.' ) do |d|
          options.diff = d
        end
  
        opts.separator ""
        opts.separator "Common options:"
  
        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end
      end
  
      # Parse the command-line. Remember there are two forms of the parse method. The 'parse' method 
      # simply parses ARGV, while the 'parse!' method parses ARGV and removes any options found there, 
      # as well as any parameters for the options. What's left is the list of files to resize.
      begin
        opts.parse!(args)
      rescue OptionParser::InvalidOption, OptionParser::MissingArgument
        # $! or $ERROR_INFO - exception information message set by the last 'raise' (last exception thrown).
        puts "\n#{$!.to_s}\n\n"  # Friendly output when parsing fails: 
        puts opts
        exit
      end 
      options
    end  # parse()
  end  # class Optparser
  
  
  
  # TODO need to use a simple array then methods to make it into a 3-d array
  def Lifecastor.average_simulation(res_set) # sim x year x col
    sims = res_set.length
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
        avg_res[y][c] /= sims 
        avg_res[y][c] = avg_res[y][c].to_i if c == 0 # keep age column integer
      } 
    }
    avg_res
  end
  
  def Lifecastor.run  
    # save the current results as the last results for comparison at the end of this run
    Lifecastor.copy('.curr.res', '.last.res')

    # parse command line arguments
    clopt = Optparser.parse(ARGV)

    # when used in rails, it should be populated by user's plan out of db
    ppf = "plan.properties"
    ppf = ARGV[0] if ARGV.length > 0
    p_prop = Utils::Properties.load_from_file(ppf, true)
    
    # TODO really don't need these, plan stores its run result inside
    # run many times to get an average view of the overall financial forecast
    result_set_in_array = [] # result array indexed by sims, each is 2d array of income, tax, expense, ... indexed by age
    count = 0
    bankrupt_total_age = 0
    p_prop.total_number_of_simulation_runs.to_i.times { |sim|
      # this alone makes a new simulation run
      srand(sim + p_prop.seed_offset.to_i) # make the randam repeatable; without it, the random will not repeat
    
      result_set_in_array << result_array = Array.new # stores planning result on income, tax, expense, ... by years
    
      plan = Lifecastor::Plan.new(sim, result_array, p_prop, clopt) # TODO plan can saved in an array to collect results
      plan.run
      count += plan.bankrupt
      bankrupt_total_age += plan.bankrupt_age
    }
    
    # summary results
    a_scen = Lifecastor.average_simulation(result_set_in_array)
    sr = sprintf("%s: %9.1f%s\n", "  Bankrupt probability", 100 * count / p_prop.total_number_of_simulation_runs.to_f, "%")
    sr << (count == 0 ? sprintf("%s: %9.1f\n", "  No bankruptcy       ", p_prop.life_expectancy_) : sprintf("%s: %9.1f\n", "  Average bankrupt age", bankrupt_total_age / count.to_f))
    sr << sprintf("%s: %11s\n\n", "  Avg horizon wealth", a_scen[p_prop.life_expectancy_.to_i-p_prop.age.to_i][7].to_i.to_s.gsub(/(\d)(?=\d{3}+(?:\.|$))(\d{3}\..*)?/,'\1,\2')) # get 1,234.23

    # get the current plan properties into a string so that it can be saved to a file later
    ps = Lifecastor.file2string(ppf)

    # save the current properties and results
    File.open('.curr.res', 'w') {|f| f.write(ps + sr) }    

    # compare last and current results
    ds = Lifecastor.diff('.last.res', '.curr.res')

    # output summary results
    puts sr if !clopt.quiet 
    puts ds if clopt.diff 

    # append plan properties and results to the history file
    File.open('.history.res', 'a') {|f| f.write("\n"+Time.new.strftime("%Y-%m-%d %H:%M:%S")+"\n"+ps+sr+"\n"+Time.new.strftime("%Y-%m-%d %H:%M:%S")+"\n"+ds) }    

    # charting
    if clopt.chart
      # initialize charts; it's empty if properties said so
      chart1 = p_prop.what_to_chart1.empty? ? '' : p_prop.what_to_chart1.split(',')
      chart2 = p_prop.what_to_chart2.empty? ? '' : p_prop.what_to_chart2.split(',')
      
      c = Chart.new
      c.form_html_and_chart_it('All but Net Worth', chart1, a_scen)
      sleep 1
      c.form_html_and_chart_it('Net Worth', chart2, a_scen)
    end
  end

  private
    def Lifecastor.diff(f1, f2)
      a1 = Array.new
      a1 = IO.readlines(f1)
      a2 = Array.new
      a2 = IO.readlines(f2)
      ret = ''
      diff = false
      for i in 0..a1.length-1
        if a1[i] != a2[i]
          ret << "    " + a1[i] + "--> " + a2[i]
          diff = true
        end
      end
      diff ? ret : "No change.\n"
    end
    def Lifecastor.copy(f1, f2)
      File.open(f2, 'w') do |w|  
        File.open(f1, 'r') do |r|  
          while line = r.gets  
            w.write line  
          end  
        end  
      end  
    end
    def Lifecastor.file2string(file)
      ps = ''
      File.open(file, 'r') do |f|  
        while line = f.gets  
          ps << line  
        end  
      end  
      ps
    end
end

##############################################
# uncomment this line to make Windows runable
##############################################
Lifecastor.run
