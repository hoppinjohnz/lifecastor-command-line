require 'mortgage_calc'
require 'rubystats'

# this module defines the following:
# Lifecastor::Family class to represent a family under financial planning/simulation
# Lifecastor.run method to make a financial forecast for the family

# TODO
# retirement, death, estate planning, statistical catastrophical events

module Lifecastor

  # global constents
  INFINITY = 99999999999999999
  LIFE_EXPECTANCY = 78
  
  class Family
    attr_accessor :age, :income, :expense, :tax, :savings

    def initialize(filing_status, children, savings, income, expense, inflation)
      @age = income[1]
      @age_to_retire = income[2]
      @years_to_work = @age_to_retire - @age > 0 ? @age_to_retire - @age : 0
      @income = Income.new(income[0], @age, @age_to_retire, @years_to_work)
      @expense = Expense.new('food', expense, inflation)
      @tax = Tax.new(filing_status)
      @savings = Savings.new(savings)
    end
  end
  
  # returns 1 or 0 for bankrupt or not
  def Lifecastor.run(family)
    printf("%-5s%13s%13s%13s%13s%13s%13s%13s\n", 
           "Age", "Income", "Taxable", "Federal", "State", "Expense", "Leftover", "Savings")
    (LIFE_EXPECTANCY-family.age+1).times { |y|
      income = family.income.of_year(y)

      deduction = family.tax.std_deduction
      taxable_income = income > deduction ? income - deduction : 0
      
      federal_tax = taxable_income * family.tax.federal(taxable_income)
      state_tax = taxable_income * family.tax.state(taxable_income)

      expense = family.expense.normal_cost(y)

      leftover = income - expense - federal_tax - state_tax

      emergence_fund = family.savings.balance
      net = emergence_fund + leftover

      family.savings.update(net) # update family savings
      
      printf("%4d %13.0f%13.0f%13.0f%13.0f%13.0f%13.0f%13.0f\n", 
             y+family.age, income, taxable_income, federal_tax, state_tax, expense, leftover, net)

      if net < 0.0
        puts "BANKRUPT at age #{y+family.age}!" 
        return 1
      end
    }
    return 0 
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
    def initialize(b, age, age_to_retire, years_to_work, inc=0.05)
      @base = b
      @age = age
      @age_to_retire = age_to_retire
      @years_to_work = years_to_work
      @inc = inc # 5%
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
      n < @years_to_work ? @base*(1.0 + @inc)**n : 17016
    end
  end
  
  class Expense
    def initialize(c, expense, inf=0.02)
      @cat = c
      @mean = expense[0]
      @sd = expense[1]
      @inf = inf
    end
  
    def cost(n) # need to inflation adjust here
      lo = (@mean-2*@sd)*(1.0 + @inf)**n
      up = (@mean+2*@sd)*(1.0 + @inf)**n
      rand(lo..up)
    end
  
    # need to adjust down to 80% after retirement
    def normal_cost(n) # need to inflation adjust here
      mean = @mean*(1.0 + @inf)**n
      Rubystats::NormalDistribution.new(mean, @sd).rng
    end
  end
  
  class Child < Expense
    def initialize(c, lo, up, inf=0.02, age, base)
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
      case income
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
      case income
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

# run many times to get an average view of the overall financial forecast
# we can collect stats, e.g., probability of bankrupt
count = 0
total = 100
total.times { |s|
  srand(s+222) # to make the randam numbers repeatable; without it the seed will be the not repeatable time

  # user data
  filing_status = 'single'
  children = [['Kyle', 12], ['Chris', 10]] # [name, age]
  savings = 10000 # more or less like emergence fund
  income = [50000, 10, 69] # [salary, age, age_to_retire]
  expense = [30000, 9000]
  inflation = 0.03

  puts ''
  puts s
  count += Lifecastor.run(Lifecastor::Family.new(filing_status, children, savings, income, expense, inflation))
}
puts "Likelyhood of bankrupt is #{count.to_f/total*100.0}%"
