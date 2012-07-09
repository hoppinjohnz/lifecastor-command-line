require 'mortgage_calc'

# this module does the following:
# defines Lifecastor::Family class to represent a family under financial planning and other helper classes
# defines Lifecastor.run method to make a financial forecast for the family

module Lifecastor

  # global constents
  INFINITY = 99999999999999999
  
  class Family
    attr_accessor :income, :expense, :tax, :savings

    def initialize(filing_status, savings, salary, cost_lower, cost_upper, inflation)
      @income = Income.new(salary)
      @expense = Expense.new('food', cost_lower, cost_upper, inflation)
      @tax = Tax.new(filing_status)
      @savings = Savings.new(savings)
    end
  end
  
  def Lifecastor.run(family, years=10)
    printf("%-5s%13s%13s%13s%13s%13s%13s%13s\n", "Year", "Income", "Taxable", "Federal", "State", "Expense", "Leftover", "Savings")
    years.times { |y|
      income = family.income.pay(y)
      taxable_income = income - family.tax.std_deduction
      
      federal_tax = taxable_income * family.tax.federal(taxable_income)
      state_tax = taxable_income * family.tax.state(taxable_income)

      expense = family.expense.cost(y)

      leftover = income - expense - federal_tax - state_tax

      emergence_fund = family.savings.balance
      net = emergence_fund + leftover

      family.savings.update(net) # update family savings
      
      printf("%4d %13.0f%13.0f%13.0f%13.0f%13.0f%13.0f%13.0f\n", y+1, income, taxable_income, federal_tax, state_tax, expense, leftover, net)

      if net < 0.0
        puts "BANKRUPT at year #{y}!" 
        return 1
        break
      else
      end
    }
    return 0 # returns 0 or 1 standing for bankrupt or not
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
        else raise "Unknown filing_status"
      end
    end
  
    def federal(income)
      case income
        when -INFINITY..  0 then 0.00 # added to deal with below 0 taxable income
        when      0..  8700 then 0.10 # projected for 2012
        when   8701.. 35350 then 0.15
        when  35351.. 85650 then 0.25
        when  85651..178650 then 0.28
        when 178651..388350 then 0.33
        when 388351..INFINITY then 0.35
        else raise "Unknown income in Tax::federal"
      end
    end
  
    def state(income)
      case income
        when     0.. 2760 then 0.00 # projected for 2012
        when  2761.. 5520 then 0.03
        when  5521.. 8280 then 0.04
        when  8281..11040 then 0.05
        when 11041..13800 then 0.06
        when 13801..INFINITY then 0.07
        else raise "Unknown income in Tax::state"
      end
    end
  end
  
  class Savings
    def initialize(bal, rate=0.01)
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
    def initialize(b, inc=0.05)
      @base = b
      @inc = inc # 5%
    end
  
    def pay(n)
      @base*(1.0 + @inc)**n
    end
  end
  
  class Expense
    def initialize(c, lo, up, inf)
      @cat = c
      @cost
      @lo = lo
      @up = up
      @inf = inf
    end
  
    def cost(n) # need to inflation adjust here
      lo = @lo*(1.0 + @inf)**n
      up = @up*(1.0 + @inf)**n
      rand(lo..up)
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

# run many times to get a average view of the overall financial forecast: we can collect stats, e.g., probability of bankrupt
count = 0
total = 1000
total.times { |s|
  srand(s) # to make the randam numbers repeatable; without it the seed will be the current time, thus not repeatable
  filing_status = 'single'
  savings = 10000 # more or less like emergence fund: need to consider growth at a reasonable rate like 1%
  salary = 50000
  cost_lower = 20000
  cost_upper = 45000
  inflation = 0.03
  years = 40
  puts ''
  puts s
  count += Lifecastor.run(Lifecastor::Family.new(filing_status, savings, salary, cost_lower, cost_upper, inflation), years)
}
puts "Likelyhood of bankrupt is #{count.to_f/total*100.0}%"
