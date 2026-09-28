# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Neeto::HtmlInStringLiteral, :config do
  let(:cop_config) { { "Enabled" => true } }

  it "registers an offense for an interpolated string with markup" do
    snippet = <<~'RUBY'
      "<a href='mailto:#{email}'>#{email}</a>"
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
    RUBY
    expect_offense(snippet, msg: described_class::MSG)
  end

  it "registers an offense for a plain string with markup" do
    snippet = <<~RUBY
      list = "<li>"
             ^^^^^^ %{msg}
    RUBY
    expect_offense(snippet, msg: described_class::MSG)
  end

  it "registers an offense for a closing tag" do
    snippet = <<~RUBY
      html += "</table>"
              ^^^^^^^^^^ %{msg}
    RUBY
    expect_offense(snippet, msg: described_class::MSG)
  end

  it "registers an offense for a self-closing tag" do
    snippet = <<~RUBY
      "<br/>"
      ^^^^^^^ %{msg}
    RUBY
    expect_offense(snippet, msg: described_class::MSG)
  end

  it "registers an offense for a heredoc with markup" do
    snippet = <<~'RUBY'
      <<~HTML
      ^^^^^^^ %{msg}
        <tr><td>#{answer}</td></tr>
      HTML
    RUBY
    expect_offense(snippet, msg: described_class::MSG)
  end

  it "registers an offense for markup in a percent literal" do
    snippet = <<~'RUBY'
      %(<span style="color: #6B7280;">#{name}</span>)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
    RUBY
    expect_offense(snippet, msg: described_class::MSG)
  end

  it "registers one offense for an interpolated string with several markup parts" do
    snippet = <<~'RUBY'
      "<p>#{field}</p><p>#{value}</p>"
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
    RUBY
    expect_offense(snippet, msg: described_class::MSG)
  end

  it "registers an offense for markup used as a replacement" do
    snippet = <<~'RUBY'
      text.gsub("\n", "<br/>")
                      ^^^^^^^ %{msg}
    RUBY
    expect_offense(snippet, msg: described_class::MSG)
  end

  it "does not register an offense for strings without markup" do
    expect_no_offenses(<<~'RUBY')
      "Hello #{name}"
      "a < b"
      "1<2"
      "<<EOF"
      "<!-- comment -->"
    RUBY
  end

  it "does not register an offense for markup being searched for" do
    expect_no_offenses(<<~RUBY)
      body.gsub("<p></p>", "")
      body.include?("<table")
      body.start_with?("<p>")
      body.split("<br>")
      body == "<p></p>"
      "<p></p>" == body
    RUBY
  end

  it "does not register an offense for regular expressions" do
    expect_no_offenses(<<~'RUBY')
      text.gsub(/<br\s*\/?>/i, "\n")
      text.gsub(%r{</p>}, "")
    RUBY
  end

  it "does not register an offense for binary strings" do
    expect_no_offenses(<<~'RUBY')
      bytes.start_with?("\x89PNG\r\n\x1A\n".b)
      signature = "\xFF\xD8\xFF".b
    RUBY
  end

  it "does not register an offense for symbols" do
    expect_no_offenses(<<~RUBY)
      :"<div>"
    RUBY
  end
end
