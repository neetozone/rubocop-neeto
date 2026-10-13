# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Neeto::HtmlTranslationInterpolation, :config do
  let(:cop_config) do
    locales = File.expand_path("../../../../fixtures/locales", __FILE__)
    { "Enabled" => true, "LocaleFiles" => ["#{locales}/**/en.yml", "#{locales}/**/*.en.yml"] }
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

  it "registers an offense in a view for a key without the _html suffix" do
    snippet = <<~RUBY
      sanitize t("seed.description", name: @name)
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
    RUBY
    expect_offense(
      snippet, "app/views/mailers/otp_mailer/send_otp.html.inky", msg: message("seed.description", "%{name}"))
  end

  it "registers an offense in a view for I18n.t with an _html key" do
    snippet = <<~RUBY
      I18n.t("seed.link_html", url: @url)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
    RUBY
    expect_offense(snippet, "app/views/pages/show.html.erb", msg: message("seed.link_html", "%{url}"))
  end

  it "does not register an offense in a view for the t helper with an _html key" do
    expect_no_offenses(<<~RUBY, "app/views/pages/show.html.erb")
      t("seed.link_html", url: @url)
    RUBY
  end

  it "registers an offense for symbol and array keys" do
    snippet = <<~RUBY
      I18n.t(:"seed.description", name: user.name)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
      I18n.t(%i[seed description], name: user.name)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
    RUBY
    expect_offense(snippet, msg: message("seed.description", "%{name}"))
  end

  it "registers an offense for a key resolved through scope" do
    snippet = <<~RUBY
      I18n.t("description", scope: "seed", name: user.name)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
      I18n.t(:description, scope: %i[seed], name: user.name)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
    RUBY
    expect_offense(snippet, msg: message("seed.description", "%{name}"))
  end

  it "registers an offense for a key from another English locale file" do
    snippet = <<~RUBY
      I18n.t("mailer.otp", email: user.email)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
    RUBY
    expect_offense(snippet, msg: message("mailer.otp", "%{email}"))
  end

  it "does not register an offense for values built by escaping helpers" do
    expect_no_offenses(<<~RUBY)
      I18n.t("seed.description", name: CGI.escapeHTML(user.name))
      I18n.t("seed.description", name: tag.b(user.name))
      I18n.t("seed.description", name: helpers.tag.strong(user.name))
      I18n.t("seed.link_html", url: link_to(url, url))
      I18n.t("seed.description", name: safe_join(names, ", "))
    RUBY
  end

  it "does not register an offense when the scope is dynamic" do
    expect_no_offenses(<<~RUBY)
      I18n.t("description", scope: scope_name, name: user.name)
    RUBY
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
