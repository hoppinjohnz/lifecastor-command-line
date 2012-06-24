require 'mortgage_calc'

class Plan
  # has all these
  def initialize
    @income = Income.new(10000)
    @expense = Expense.new('food')
  end
  
  def cal
    10.times { |y|
      12.times { |m|
        printf("%6.0f\t%6d\t%6.0f\n", i = @income.pay(y), e = @expense.cost(y), i - e)
      }
    }
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

  def initialize(c)
    @cat = c
  end

  def cost(n)
    rand(7000..13000)
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

Plan.new.cal
