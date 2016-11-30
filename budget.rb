require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "pry-nav"
require "pry"

configure do
  enable :sessions
  set :session_secret, "1qaz"
end

BILL_CATEGORES = ["Repast", "Clothes", "Traffic", "Entainment", "Phone", "Books", "Learning"]

before do
  @errors = {}
  initialize_category
  session[:expenses] ||= []
  session[:budgets] ||= []
  load_categories
  load_budgets
end

helpers do

end

def check_budget_input(time, num)
  @errors[:budget_num] = "please enter a number" if num.to_i.to_s != num
  @errors[:budget_time] = "please choose time " if time == ""
  @errors == {}
end

def check_expense_input(time, num)
  @errors[:expense_time] = "please choose time" if time == ""
  @errors[:expense_num] = "please enter a number" if num.to_i.to_s != num
  @errors == {}
end


def extract_expenses(time_month, by_year)
  expenses = session[:expenses].select do |expense|
    if by_year
      time_month.split("-")[0] == expense[:time].split("-")[0] # by_year
    else
      time_month == expense[:time].split("-")[0..1].join("-")
    end
  end
  expenses
end

def extracct_budgets(time_month)
  budgets = session[:budgets]
  res = budgets.find{|budget| budget[:month] == time_month}
end

def statstics(expenses)
  total = 0
  by_categories = {}
  expenses.each do |expense|
    total += expense[:num]
    if !expense[:category].empty?
      by_categories[expense[:category]] ||= 0
      by_categories[expense[:category]] += expense[:num]
    else
      by_categories["others"] ||= 0
      by_categories["others"] += expense[:num]
    end
  end
  return total, by_categories
end

def initialize_category
  session[:categories] ||= BILL_CATEGORES
end

def load_categories
  @categories = session[:categories]
end
def load_budgets
  @budgets = session[:budgets]
end

def categories=(name)
  return if session[:categories].include?(name)
  session[:categories] << name
end

get "/" do
  redirect "/expenses"
end


get "/budgets/new" do
  erb :budgets_new
end

post "/budgets" do
  budget_time = params[:budget_time]
  budget_num = params[:budget_num]

  if check_budget_input(budget_time, budget_num)
    # uniqueness of budget,
    @budgets.delete_if {|budget| budget[:month] ==  budget_time} if extracct_budgets(budget_time)

    session[:budgets] << {month: budget_time, num: budget_num.to_f}
    session[:message] = "created success"
    redirect "/budgets"
  else
    erb :budgets_new
  end
end

get "/budgets" do
  erb :budgets
end

get "/expenses/new" do
  erb :expenses_new
end

get "/expenses" do
  time = params[:expense_time]
  if time && !time.empty?
    query_type = params[:by_year] == "true"
    @expenses = extract_expenses(time, query_type)
    @budget = extracct_budgets(time) unless query_type
  else
    @expenses = session[:expenses]  #all
  end
  @total, @by_categories = statstics(@expenses)
  @res = @budget[:num].to_f - @total if @budget
  erb :expenses
end

post "/expenses" do
  category = params[:expense_category]
  category == "" ? "others" : category 
  name = params[:expense_detail]
  time = params[:expense_time]
  num = params[:expense_num]
 
  if check_expense_input(time, num)
    expense = { num: num.to_f, category: category, name: name , time: time}
    session[:expenses] << expense
    session[:message] = "created success"
    redirect "/expenses"
  else
    erb :expenses_new
  end
end
