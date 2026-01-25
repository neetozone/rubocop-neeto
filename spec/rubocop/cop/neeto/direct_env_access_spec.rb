# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Neeto::DirectEnvAccess, :config do
  let(:config) { RuboCop::Config.new }

  it "registers an offense when ENV is accessed with bracket notation" do
    snippet = <<~RUBY
      api_key = ENV['STRIPE_API_KEY']
                ^^^^^^^^^^^^^^^^^^^^^ #{offense}
    RUBY
    expect_offense(snippet)
  end

  it "registers an offense when ENV.fetch is used" do
    snippet = <<~RUBY
      default_timezone = ENV.fetch('DEFAULT_TIMEZONE', 'UTC')
                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense}
    RUBY
    expect_offense(snippet)
  end

  it "registers an offense when ENV.fetch is used without a default" do
    snippet = <<~RUBY
      api_key = ENV.fetch('STRIPE_API_KEY')
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense}
    RUBY
    expect_offense(snippet)
  end

  it "registers multiple offenses when ENV is accessed multiple times" do
    snippet = <<~RUBY
      api_key = ENV['STRIPE_API_KEY']
                ^^^^^^^^^^^^^^^^^^^^^ #{offense}
      timeout = ENV.fetch('REQUEST_TIMEOUT', '30')
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense}
    RUBY
    expect_offense(snippet)
  end

  it "registers an offense when ENV is accessed with :: prefix" do
    snippet = <<~RUBY
      api_key = ::ENV['STRIPE_API_KEY']
                ^^^^^^^^^^^^^^^^^^^^^^^ #{offense}
    RUBY
    expect_offense(snippet)
  end

  it "does not register an offense when Secvault.secrets is used" do
    snippet = <<~RUBY
      api_key = Secvault.secrets.stripe_api_key
    RUBY
    expect_no_offenses(snippet)
  end

  it "does not register an offense for non-ENV constants" do
    snippet = <<~RUBY
      value = SOME_CONSTANT['key']
    RUBY
    expect_no_offenses(snippet)
  end

  private

    def offense
      "Neeto/DirectEnvAccess: #{RuboCop::Cop::Neeto::DirectEnvAccess::MSG}"
    end
end
