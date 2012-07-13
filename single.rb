require 'mortgage_calc'
require 'rubystats'
require 'optparse'
require "properties-ruby"
require "time"

# this module defines the following:
# Lifecastor::Plan class to represent a financial planning/simulation
# Lifecastor.run method to make a financial forecast for the family

# TODO
# retirement, death, estate planning, catastrophical events/life insurance, random income, random inflation, will, estate stats 

module Lifecastor

  # global constents
  INFINITY = 99999999999999999
  LIFE_EXPECTANCY = 78
  EXPENSE_AFTER_RETIREMENT = 0.8
  FIRST_TWO_YEAR_FACTOR = 0.7
  INFLATION_MEAN = 0.02
  INFLATION_SD = 0.002

  class Plan
    def initialize(options, filing_status, children, savings, income, expense, inflation)
      @options = options
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
      printf("%-4s%13s%13s%13s%13s%13s%13s%13s\n", "Age", "Income", "Taxable", "Federal", "State", "Expense", "Leftover", "Savings") if @options[:verbose]
      (LIFE_EXPECTANCY-@age+1).times { |y|
        income = @income.of_year(y)
  
        deduction = @tax.std_deduction
        taxable_income = income > deduction ? income - deduction : 0
        
        federal_tax = taxable_income * @tax.federal(taxable_income)
        state_tax = taxable_income * @tax.state(taxable_income)
  
        expense = @expense.normal_cost(y, y >= @years_to_work)
  
        leftover = income - expense - federal_tax - state_tax
  
        emergence_fund = @savings.balance
        net = emergence_fund + leftover
  
        @savings.update(net) # update family savings
        
        printf("%3d %13.0f%13.0f%13.0f%13.0f%13.0f%13.0f%13.0f\n", y+@age, income, taxable_income, federal_tax, state_tax, expense, leftover, net) if @options[:verbose]
  
        if net < 0.0
          puts "BANKRUPT at age #{y+@age}!" 
          printf("%3d %13.0f%13.0f%13.0f%13.0f%13.0f%13.0f%13.0f\n", y+@age, income, taxable_income, federal_tax, state_tax, expense, leftover, net) if !@options[:verbose]
          return 1
        end
      }
      return 0 
    end
  end

  class Savings
    def initialize(bal, rate=0.002)
      @bal = bal
      @rate = rate # 1%
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
      @years_to_work = @age_to_retire > @age ? @age_to_retire - @age : 0
      @inc_m = income[3]
      @inc_sd = income[4]
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
  
    def normal_cost(n, retired) 
      inf = Rubystats::NormalDistribution.new(@inf_m, @inf_sd).rng
      mean = @mean*(1.0 + inf)**n # inflation adjust here
      if n < 2
        mean = FIRST_TWO_YEAR_FACTOR*@mean
        sd   = FIRST_TWO_YEAR_FACTOR*@sd
      else
        mean = retired ? EXPENSE_AFTER_RETIREMENT*mean : mean # adjust down to 80% after retirement
        sd   = retired ? EXPENSE_AFTER_RETIREMENT*@sd : @sd
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


# This hash will hold all of the options parsed from the command-line by OptionParser.
options = {}

optparse = OptionParser.new do|opts|
  # Set a banner, displayed at the top of the help screen.
  opts.banner = "Usage: ruby #{__FILE__} [options]"

  # Define the options, and what they do
  options[:verbose] = false
  opts.on( '-v', '--verbose', 'Output complete output' ) do
    options[:verbose] = true
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


p = Utils::Properties.load_from_file("lifecastor.properties", true)

# run many times to get an average view of the overall financial forecast
# we can collect stats, e.g., probability of bankrupt
count = 0
total = 100
total.times { |s|
  # user data from properties file
  seed_offset = p.seed_offset.to_i
  filing_status = p.filing_status
  children = [['Kyle', 12], ['Chris', 10]] # [name, age]
  savings = p.savings.to_i # more or less like emergence fund
  income = [p.income.to_i, p.age.to_i, p.age_to_retire.to_i, p.increase_mean.to_f, p.increase_sd.to_f]
  expense = [p.expense_mean.to_i, p.expense_sd.to_i]
  inflation = [p.inflation_mean.to_f, p.inflation_sd.to_f]

  srand(s+seed_offset) # make the randam repeatable; without it, the random will not repeat
  count += Lifecastor::Plan.new(options, filing_status, children, savings, income, expense, inflation).run
}
puts "Likelyhood of bankrupt is #{count.to_f/total*100.0}%"
