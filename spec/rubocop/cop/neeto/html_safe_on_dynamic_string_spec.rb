# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Neeto::HtmlSafeOnDynamicString, :config do
  let(:cop_config) { { "Enabled" => true } }

  it "registers an offense for html_safe on an interpolated string" do
    snippet = <<~'RUBY'
      "<a href='#{url}'>#{name}</a>".html_safe
                                     ^^^^^^^^^ %{msg}
    RUBY
    expect_offense(snippet, msg: message(:html_safe))
  end

  it "registers an offense for html_safe on a method result" do
    snippet = <<~RUBY
      policy = meeting.cancellation_policy.html_safe
                                           ^^^^^^^^^ %{msg}
    RUBY
    expect_offense(snippet, msg: message(:html_safe))
  end

  it "registers an offense for html_safe with safe navigation" do
    snippet = <<~RUBY
      meeting.cancellation_policy&.html_safe
                                   ^^^^^^^^^ %{msg}
    RUBY
    expect_offense(snippet, msg: message(:html_safe))
  end

  it "registers an offense for html_safe on a variable" do
    snippet = <<~RUBY
      item.html_safe
           ^^^^^^^^^ %{msg}
    RUBY
    expect_offense(snippet, msg: message(:html_safe))
  end

  it "registers an offense for html_safe on a joined collection" do
    snippet = <<~RUBY
      participants.join("<br />").html_safe
                                  ^^^^^^^^^ %{msg}
    RUBY
    expect_offense(snippet, msg: message(:html_safe))
  end

  it "registers an offense for html_safe on an interpolated heredoc" do
    snippet = <<~'RUBY'
      <<~HTML.html_safe
              ^^^^^^^^^ %{msg}
        <p>#{value}</p>
      HTML
    RUBY
    expect_offense(snippet, msg: message(:html_safe))
  end

  it "registers an offense for raw on a dynamic value" do
    snippet = <<~RUBY
      raw(message.body)
      ^^^ %{msg}
    RUBY
    expect_offense(snippet, msg: message(:raw))
  end

  it "registers an offense for safe_concat with a dynamic value" do
    snippet = <<~RUBY
      buffer.safe_concat(answer)
             ^^^^^^^^^^^ %{msg}
    RUBY
    expect_offense(snippet, msg: message(:safe_concat))
  end

  it "registers an offense when the annotation has no reason" do
    snippet = <<~RUBY
      body.html_safe # neeto:html-safe-reviewed
           ^^^^^^^^^ %{msg}
    RUBY
    expect_offense(snippet, msg: message(:html_safe))
  end

  it "does not register an offense for html_safe on a plain string literal" do
    expect_no_offenses(<<~RUBY)
      "<br />".html_safe
    RUBY
  end

  it "does not register an offense for html_safe on adjacent string literals" do
    expect_no_offenses(<<~RUBY)
      "<div>" "</div>".html_safe
    RUBY
  end

  it "does not register an offense for html_safe on a heredoc without interpolation" do
    expect_no_offenses(<<~RUBY)
      <<~HTML.html_safe
        <p>Static</p>
      HTML
    RUBY
  end

  it "does not register an offense for raw or safe_concat on string literals" do
    expect_no_offenses(<<~RUBY)
      raw("&nbsp;")
      buffer.safe_concat("</ul>")
    RUBY
  end

  it "does not register an offense for raw called on a receiver" do
    expect_no_offenses(<<~RUBY)
      request.raw(payload)
    RUBY
  end

  it "does not register an offense when annotated on the same line" do
    expect_no_offenses(<<~RUBY)
      body.html_safe # neeto:html-safe-reviewed rendered by the escaping renderer
    RUBY
  end

  it "does not register an offense when annotated on the previous line" do
    expect_no_offenses(<<~RUBY)
      # neeto:html-safe-reviewed rendered by the escaping renderer
      body.html_safe
    RUBY
  end

  it "does not register an offense when annotated inside a multi-line expression" do
    expect_no_offenses(<<~RUBY)
      body
        .strip # neeto:html-safe-reviewed rendered by the escaping renderer
        .html_safe
    RUBY
  end

  it "does not register an offense for html_safe? checks" do
    expect_no_offenses(<<~RUBY)
      value.html_safe?
    RUBY
  end

  private

    def message(method)
      format(described_class::MSG, method:)
    end
end
