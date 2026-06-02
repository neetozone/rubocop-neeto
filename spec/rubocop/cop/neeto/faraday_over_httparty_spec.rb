# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Neeto::FaradayOverHttparty, :config do
  let(:config) { RuboCop::Config.new }

  it "registers an offense when httparty is added" do
    expect_offense(<<~RUBY)
      gem "httparty"
      ^^^^^^^^^^^^^^ #{offense}
    RUBY
  end

  it "registers an offense when httparty is added with single quotes" do
    expect_offense(<<~RUBY)
      gem 'httparty'
      ^^^^^^^^^^^^^^ #{offense}
    RUBY
  end

  it "registers an offense when httparty is added with a version constraint" do
    expect_offense(<<~RUBY)
      gem "httparty", "~> 0.21"
      ^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense}
    RUBY
  end

  it "registers an offense when httparty is added with options" do
    expect_offense(<<~RUBY)
      gem "httparty", require: false
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense}
    RUBY
  end

  it "registers an offense regardless of casing" do
    expect_offense(<<~RUBY)
      gem "HTTParty"
      ^^^^^^^^^^^^^^ #{offense}
    RUBY
  end

  it "does not register an offense for faraday" do
    expect_no_offenses(<<~RUBY)
      gem "faraday"
    RUBY
  end

  it "does not register an offense for gems whose name merely contains httparty" do
    expect_no_offenses(<<~RUBY)
      gem "httparty_extensions"
    RUBY
  end

  private

    def offense
      "Neeto/FaradayOverHttparty: #{RuboCop::Cop::Neeto::FaradayOverHttparty::MSG}"
    end
end
