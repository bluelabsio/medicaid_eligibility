require 'test_helper'

class HouseholdIncomeTest < ActiveSupport::TestCase
  include ApplicationProcessor

  [[79999, 1], [80000, 2], [89999, 2], [90000, 3], [100000, 4], [1_260_000, 120], [1_300_000, 120]]. each do |(amount, months)|
    test "months of winnings for #{amount} winnings" do
      expander = WinningsExpander.new(amount, Date.new(2020, 5, 1))
      assert_equal expander.number_of_months, months
      assert_equal expander.amount_to_apply, (amount.to_f/months).round
    end
  end

  test "active range" do
    expander = WinningsExpander.new(100_000, Date.new(2020, 5, 18))
    assert_not_operator expander, :within_active_range?, Date.new(2020, 4)
    assert_operator expander, :within_active_range?, Date.new(2020, 5)
    assert_operator expander, :within_active_range?, Date.new(2020, 6)
    assert_operator expander, :within_active_range?, Date.new(2020, 7)
    assert_operator expander, :within_active_range?, Date.new(2020, 8)
    assert_not_operator expander, :within_active_range?, Date.new(2020, 9)
  end

  test "normal household income" do
    p1 = Person.new(1, nil, {incomes: {"Wages, Salaries, Tips" => 1.0, "Taxable Income" => 2.0}, deductions: {"Alimony" => 1.5}})
    p2 = Person.new(2, nil, {incomes: {"Wages, Salaries, Tips" => 5.0}, deductions: {"Other Income" => 2}})
    assert_equal calculate_household_income(p1, [p1, p2], nil), ((1.0 + 2.0 - 1.5) + (5.0 - 2))
  end

  def self.scenario(name, date_of_winnings:, winnings_amount:, expected_adjustment:, date_of_test: Date.new(2020, 5, 2), applicant: :winner)
    test name do
      p1 = Person.new(1, nil, {incomes: {"Wages, Salaries, Tips" => 1.0, "Taxable Income" => 2.0}, deductions: {}, qualified_winnings: [{amount: winnings_amount, date: date_of_winnings}]})
      p2 = Person.new(2, nil, {incomes: {"Wages, Salaries, Tips" => 5.0}, deductions: {"Other Income" => 2}})
      calculate_for = applicant == :winner ? p1 : p2
      assert_equal calculate_household_income(calculate_for, [p1, p2], date_of_test) - ((1.0 + 2.0) + (5.0 - 2)), expected_adjustment
    end
  end

  scenario "lottery winnings below the threshold in month of application for applicant",
    date_of_test: Date.new(2020,5,2), date_of_winnings: Date.new(2020,5,1), winnings_amount: 79999, expected_adjustment: 79999

  scenario "lottery winnings of 80000 in month of application for applicant",
    date_of_test: Date.new(2020,5,2), date_of_winnings: Date.new(2020,5,1), winnings_amount: 80000, expected_adjustment: 40000

  scenario "lottery winnings of 80000 in 1 month before application for applicant",
    date_of_test: Date.new(2020,6,2), date_of_winnings: Date.new(2020,5,1), winnings_amount: 80000, expected_adjustment: 40000

  scenario "lottery winnings of 80000 in 2 months before application for applicant",
    date_of_test: Date.new(2020,7,2), date_of_winnings: Date.new(2020,5,1), winnings_amount: 80000, expected_adjustment: 0

  scenario "lottery winnings below the threshold in month before application for applicant",
    date_of_test: Date.new(2020,5,2), date_of_winnings: Date.new(2020,4,1), winnings_amount: 79999, expected_adjustment: 0

  scenario "lottery winnings below the threshold in month of application for household member",
    date_of_test: Date.new(2020,5,2), date_of_winnings: Date.new(2020,5,1), winnings_amount: 79999, expected_adjustment: 79999, applicant: :other

  scenario "lottery winnings of 80000 in month of application for household member",
    date_of_test: Date.new(2020,5,2), date_of_winnings: Date.new(2020,5,1), winnings_amount: 80000, expected_adjustment: 80000, applicant: :other

  scenario "lottery winnings of 80000 in 1 month before application for household member",
    date_of_test: Date.new(2020,6,2), date_of_winnings: Date.new(2020,5,1), winnings_amount: 80000, expected_adjustment: 0, applicant: :other

  scenario "lottery winnings of 80000 in 2 months before application for household member",
    date_of_test: Date.new(2020,7,2), date_of_winnings: Date.new(2020,5,1), winnings_amount: 80000, expected_adjustment: 0, applicant: :other

  scenario "lottery winnings below the threshold in month before application for household member",
    date_of_test: Date.new(2020,5,2), date_of_winnings: Date.new(2020,4,1), winnings_amount: 79999, expected_adjustment: 0, applicant: :other
end
