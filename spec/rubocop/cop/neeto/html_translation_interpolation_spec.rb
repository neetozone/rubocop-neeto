# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Neeto::HtmlTranslationInterpolation, :config do
  let(:cop_config) do
    { "Enabled" => true, "LocaleFiles" => [File.expand_path("../../../../fixtures/locales/en.yml", __FILE__)] }
  end

  it "registers an offense when a value is interpolated into an HTML translation" do
    snippet = <<~RUBY
      I18n.t("seed.description", name: user.name, locale: :en)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
    RUBY
    expect_offense(snippet, msg: message("seed.description", "%{name}"))
  end

  it "registers an offense for the receiverless t helper" do
    snippet = <<~RUBY
      t("seed.description", name: name)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
    RUBY
    expect_offense(snippet, msg: message("seed.description", "%{name}"))
  end

  it "registers an offense for _html keys since I18n.t does not escape them" do
    snippet = <<~RUBY
      I18n.t("seed.link_html", url: params[:url])
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
    RUBY
    expect_offense(snippet, msg: message("seed.link_html", "%{url}"))
  end

  it "does not register an offense when the value is escaped" do
    expect_no_offenses(<<~RUBY)
      I18n.t("seed.description", name: ERB::Util.html_escape(user.name))
      I18n.t("seed.description", name: h(user.name))
    RUBY
  end

  it "does not register an offense for plain text translations" do
    expect_no_offenses(<<~RUBY)
      I18n.t("seed.plain", name: user.name)
    RUBY
  end

  it "does not register an offense for HTML translations without passed values" do
    expect_no_offenses(<<~RUBY)
      I18n.t("seed.static", locale: :en)
      I18n.t("seed.static")
    RUBY
  end

  it "does not register an offense for unknown or dynamic keys" do
    expect_no_offenses(<<~RUBY)
      I18n.t("seed.missing", name: user.name)
      I18n.t(key, name: user.name)
      I18n.t(:description, name: user.name)
    RUBY
  end

  private

    def message(key, variables)
      format(described_class::MSG, key:, variables:)
    end
end
