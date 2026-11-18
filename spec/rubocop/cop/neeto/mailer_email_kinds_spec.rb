# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Neeto::MailerEmailKinds, :config do
  let(:config) { RuboCop::Config.new }
  let(:path) { "app/mailers/message_mailer.rb" }

  it "registers an offense when a mailer has no email_kinds declaration" do
    expect_offense(<<~RUBY, path)
      class MessageMailer < ApplicationMailer
            ^^^^^^^^^^^^^ Neeto/MailerEmailKinds: Declare `email_kinds` for `customer_email`, `member_email`, e.g. `email_kinds transactional: %i[...], user_generated: %i[...]`.
        def customer_email; end

        def member_email; end
      end
    RUBY
  end

  it "registers an offense for a public action in neither list" do
    expect_offense(<<~RUBY, path)
      class MessageMailer < ApplicationMailer
        email_kinds user_generated: %i[customer_email]

        def customer_email; end

        def member_email; end
            ^^^^^^^^^^^^ Neeto/MailerEmailKinds: Add `member_email` to `transactional` or `user_generated` in `email_kinds`.
      end
    RUBY
  end

  it "registers an offense for an action in both lists" do
    expect_offense(<<~RUBY, path)
      class MessageMailer < ApplicationMailer
        email_kinds transactional: [:customer_email], user_generated: [:customer_email]
                                                                       ^^^^^^^^^^^^^^^ Neeto/MailerEmailKinds: `customer_email` is in both `transactional` and `user_generated`. Keep it in one.

        def customer_email; end
      end
    RUBY
  end

  it "registers an offense for a listed action the mailer doesn't define" do
    expect_offense(<<~RUBY, path)
      class MessageMailer < ApplicationMailer
        email_kinds transactional: [:member_email, :old_email]
                                                   ^^^^^^^^^^ Neeto/MailerEmailKinds: `old_email` is listed in `email_kinds` but this mailer doesn't define it.

        def member_email; end
      end
    RUBY
  end

  it "registers an offense for a bare symbol such as :all" do
    expect_offense(<<~RUBY, path)
      class MessageMailer < ApplicationMailer
        email_kinds transactional: :all
                                   ^^^^ Neeto/MailerEmailKinds: List the actions by name, e.g. `%i[member_email]`.

        def member_email; end
      end
    RUBY
  end

  it "accepts a mailer that declares every public action once" do
    expect_no_offenses(<<~RUBY, path)
      class MessageMailer < ApplicationMailer
        email_kinds transactional: %i[member_email], user_generated: %i[customer_email]

        def customer_email; end

        def member_email; end
      end
    RUBY
  end

  it "accepts a namespaced mailer with only transactional actions" do
    expect_no_offenses(<<~RUBY, "app/mailers/reports/export_mailer.rb")
      module Reports
        class ExportMailer < ApplicationMailer
          email_kinds transactional: %i[member_email admin_email]

          def member_email; end

          def admin_email; end
        end
      end
    RUBY
  end

  it "ignores private, protected and class methods, and attribute accessors" do
    expect_no_offenses(<<~RUBY, path)
      class MessageMailer < ApplicationMailer
        email_kinds transactional: %i[member_email]

        attr_accessor :booking

        def self.build; end

        def member_email; end

        def helper_one; end
        private :helper_one

        private def helper_two; end

        protected

          def helper_three; end

        private

          def helper_four; end
      end
    RUBY
  end

  it "counts methods after a bare public again" do
    expect_offense(<<~RUBY, path)
      class MessageMailer < ApplicationMailer
        email_kinds transactional: %i[member_email]

        def member_email; end

        private

          def helper; end

        public

        def customer_email; end
            ^^^^^^^^^^^^^^ Neeto/MailerEmailKinds: Add `customer_email` to `transactional` or `user_generated` in `email_kinds`.
      end
    RUBY
  end

  it "ignores ApplicationMailer even when it overrides public ActionMailer methods" do
    expect_no_offenses(<<~RUBY, "app/mailers/application_mailer.rb")
      class ApplicationMailer < NeetoCommonsBackend::ApplicationMailer
        def mail(headers = {}, &block)
          super
        end
      end
    RUBY
  end

  it "ignores mailers with no public actions" do
    expect_no_offenses(<<~RUBY, "app/mailers/slot/base_mailer.rb")
      class Slot::BaseMailer < ApplicationMailer
        default from: "app@neeto.com"

        private

          def set_locale; end
      end
    RUBY
  end

  it "ignores classes whose name doesn't end with Mailer" do
    expect_no_offenses(<<~RUBY, "app/mailers/concerns/mail_helpers.rb")
      class MailHelpers
        def format_amount; end
      end
    RUBY
  end

  it "skips list checks when a list isn't a literal" do
    expect_no_offenses(<<~RUBY, path)
      class MessageMailer < ApplicationMailer
        email_kinds transactional: TRANSACTIONAL_ACTIONS

        def member_email; end
      end
    RUBY
  end
end
