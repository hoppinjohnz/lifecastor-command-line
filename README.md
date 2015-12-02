# Lifecastor Command Line

## Usage: ruby lifecastor.rb [options] [planning property file of your choice]

    Options are explained below. They can be combined.

    To make a simplest run, type the following, then hit enter key.

        ruby lifecastor.rb

        This uses the default parameters from the included file planning.properites.
        Feel free to modify the parameters as you wish.

    To run on your own planning property file named 'my_planning_properties', type:

        ruby lifecastor.rb my_planning_properties

    To combine the above run with option -v, type:

        ruby lifecastor.rb -v my_planning_properties

Options:

    -b, --brief                      Output brief resutls of bankrupt info. Use -v to see more detaills.

    -c, --chart                      Chart the resutls as configured by your plan.propreties file.

    -d, --diff                       Show the difference between last and current results.

    -q, --quiet                      Output nothing to the standard output.

    -t, --taxed_savings              Tax savings at short term capital gain tax rates which are the same as regular income tax rates.

    -v, --verbose                    Output the complete resutls.

    -h, --help                       Show this message


# Features

This is an application for [*Personal Finance Life-long Forcaste*](http://tranquil-headland-5582.herokuapp.com/).

* Easy to modify input parameters in file planning.properties allow you to run endless what-if simulations so that you can understand your financial future. 

* See the big pictures of your financial future under dynamic probabilistic income, expense, and savings. 

* Analyze the impact of inflation, social security, and retirement age on your financial future. 

* Statistically forecast your estate and wealth. 

* Display you simulated wealth paths into the future.

Please send comments and suggestions to John at johnzhu00@gmail.com.

