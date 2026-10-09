# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Neeto::DirectLiquidRender, :config do
  let(:cop_config) { { "Enabled" => true } }

  it "registers an offense for Liquid::Template.parse" do
    snippet = <<~RUBY
      Liquid::Template.parse(body).render(variables)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
    RUBY
    expect_offense(snippet, msg: message(:parse))
  end

  it "registers an offense for Liquid::Template.new" do
    snippet = <<~RUBY
      template = Liquid::Template.new
                 ^^^^^^^^^^^^^^^^^^^^ %{msg}
    RUBY
    expect_offense(snippet, msg: message(:new))
  end

  it "registers an offense for a top-level constant reference" do
    snippet = <<~RUBY
      ::Liquid::Template.parse(subject)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
    RUBY
    expect_offense(snippet, msg: message(:parse))
  end

  it "does not register an offense for the shared renderer" do
    expect_no_offenses(<<~RUBY)
      NeetoLiquid.render(body, variables, format: :html)
    RUBY
  end

  it "does not register an offense for other parse calls" do
    expect_no_offenses(<<~RUBY)
      JSON.parse(payload)
      Template.parse(body)
      Other::Liquid::Template.parse(body)
    RUBY
  end

  private

    def message(method)
      format(described_class::MSG, method:)
    end
end
