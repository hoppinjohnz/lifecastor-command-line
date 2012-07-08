require 'mortgage_calc'

# this module does the following:
# defines Lifecastor::Family class to represent a family under financial planning and other helper classes
# defines Lifecastor.plan method to make a financial plan for the family

module Lifecastor

  # global constents
  INFINITY = 99999999999999999999999999999
  
  # An exception of this class indicates that a family is over-spent.
  class Bankrupt < StandardError
  end

  class Family
    attr_accessor :income, :expense, :tax, :savings

    def initialize(filing_status, savings, salary, cost_lower, cost_upper)
      @income = Income.new(salary)
      @expense = Expense.new('food', cost_lower, cost_upper)
      @tax = Tax.new(filing_status)
      @savings = savings
    end
  end
  
  def Lifecastor.plan(years, family)
    printf("%-5s%-5s%13s%13s%13s%13s%13s%13s%13s\n", "Year", "Month", "Income", "Taxable", "Federal", "State", "Expense", "Leftover", "Savings")
    years.times { |y|
      12.times { |m|
        income = family.income.pay(y)
        taxable_income = income - family.tax.std_deduction
        federal_tax = taxable_income * family.tax.federal(taxable_income)
        state_tax = taxable_income * family.tax.state(taxable_income)
        expense = family.expense.cost
        leftover = income - expense - federal_tax - state_tax

        savings = family.savings += leftover
        
        printf("%4d %5d%13.0f%13.0f%13.0f%13.0f%13.0f%13.0f%13.0f\n", y+1, m+1, income, taxable_income, federal_tax, state_tax, expense, leftover, savings)

        raise Bankrupt if savings < 0.0
      }
    }
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
  
  class Income
    attr_reader :base
    def initialize(b, inc=0.05)
      @base = b
      @inc = inc # 5%
    end
  
    def pay(n)
      @base*(1.0 + @inc)**n
    end
  end
  
  class Expense
    attr_accessor :cat
  
    def initialize(c, lo, up)
      @cat = c
      @cost
      @lo = lo
      @up = up
    end
  
    def cost
      rand(@lo..@up)
    end
    # We override the array access operator to allow access to the 
    # individual months of a horizon. Horizons are two-dimensional,
    # and must be indexed with year and month coordinates.
    def [](y, m)
      # Convert two-dimensional (y, m) coordinates into a one-dimensional
      # array index and return the cell value there
      @cost[y*9 + m]
    end
  end
  
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

srand(2) # to make the randam numbers repeatable; without it the seed will be the current time, thus not repeatable
filing_status = 'single'
savings = 5000
salary = 50000
cost_lower = 25000
cost_upper = 46000
years = 4
Lifecastor.plan(years, Lifecastor::Family.new(filing_status, savings, salary, cost_lower, cost_upper))
