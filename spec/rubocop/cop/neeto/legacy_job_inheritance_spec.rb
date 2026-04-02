# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Neeto::LegacyJobInheritance, :config do
  let(:config) { RuboCop::Config.new }

  it "registers an offense for legacy queue base classes in app jobs" do
    RuboCop::Cop::Neeto::LegacyJobInheritance::LEGACY_SUPERCLASSES.each_key do |superclass|
      expect_offense(<<~RUBY, "app/jobs/export_job.rb", superclass:, message: offense(superclass))
        class ExportJob < %{superclass}
                          ^{superclass} %{message}
        end
      RUBY
    end
  end

  it "registers an offense for legacy queue base classes in dummy app jobs" do
    expect_offense(<<~RUBY, "test/dummy/app/jobs/send_webhooks_job.rb")
      class SendWebhooksJob < NeetoCommonsBackend::BaseJobs::Default
                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense("NeetoCommonsBackend::BaseJobs::Default")}
      end
    RUBY
  end

  it "registers an offense for legacy queue base classes in workers" do
    expect_offense(<<~RUBY, "test/dummy/app/workers/send_webhooks_job.rb")
      class SendWebhooksJob < NeetoCommonsBackend::BaseJobs::Default
                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense("NeetoCommonsBackend::BaseJobs::Default")}
      end
    RUBY
  end

  it "does not register an offense for latency based job definitions" do
    expect_no_offenses(<<~RUBY, "app/jobs/concerns/latency_based_jobs.rb")
      module LatencyBasedJobs
        class Within5Seconds < NeetoCommonsBackend::BaseJobs::Base
          queue_as :within_5_seconds
        end
      end
    RUBY
  end

  it "does not register an offense for neeto commons base job definitions" do
    expect_no_offenses(<<~RUBY, "app/jobs/neeto_commons_backend/base_jobs/default.rb")
      module NeetoCommonsBackend
        module BaseJobs
          class Default < NeetoCommonsBackend::BaseJobs::Base
            queue_as :default
          end
        end
      end
    RUBY
  end

  it "does not register an offense for latency based job base classes" do
    expect_no_offenses(<<~RUBY, "app/jobs/export_job.rb")
      class ExportJob < LatencyBasedJobs::Within5Minutes
      end
    RUBY
  end

  private

    def offense(superclass)
      replacement = RuboCop::Cop::Neeto::LegacyJobInheritance::LEGACY_SUPERCLASSES.fetch(superclass)
      message = format(RuboCop::Cop::Neeto::LegacyJobInheritance::MSG, superclass:, replacement:)
      "Neeto/LegacyJobInheritance: #{message}"
    end
end
