# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe RuboCop::Cop::Neeto::WebhooksBypass, :config do
  let(:config) { RuboCop::Config.new }

  # Each test runs inside a fresh tmpdir that contains an empty Gemfile so
  # `FleetCheckBase#project_root_for` walks up from a relative file path and
  # roots in the tmpdir. Relative paths (rather than absolute) are used in
  # `expect_offense` so the cop's Include glob in default.yml still matches.
  around do |example|
    Dir.mktmpdir do |dir|
      FileUtils.touch(File.join(dir, "Gemfile"))
      FileUtils.mkdir_p(File.join(dir, "app/services/messages"))
      Dir.chdir(dir) do
        RuboCop::Neeto::FleetTodo.reset!
        ENV.delete("NEETO_FLEET_RECORD")
        @root = Pathname.new(dir)
        example.run
      end
    end
  end

  let(:webhook_service_path) { "app/services/messages/webhook_service.rb" }
  let(:non_webhook_service_path) { "app/services/messages/send_service.rb" }

  it "flags Faraday.post in a file whose path looks webhook-related" do
    expect_offense(<<~RUBY, webhook_service_path)
      class Messages::WebhookService
        def process
          Faraday.post(endpoint.url, payload.to_json)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense_message("Faraday", :post)}
        end
      end
    RUBY
  end

  it "flags HTTParty.post and other HTTP verbs in webhook files" do
    expect_offense(<<~RUBY, webhook_service_path)
      class Messages::WebhookService
        def process
          HTTParty.put(endpoint.url, body: payload)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense_message("HTTParty", :put)}
        end
      end
    RUBY
  end

  it "does not flag DeliverService usage" do
    expect_no_offenses(<<~RUBY, webhook_service_path)
      class Messages::WebhookService
        def process(payload)
          NeetoWebhooksEngine::DeliverService
            .new(entity: organization, event_identifier: "x", body: payload.to_json)
            .process_later
        end
      end
    RUBY
  end

  it "does not flag raw HTTP in files that are not webhook-flavored" do
    expect_no_offenses(<<~RUBY, non_webhook_service_path)
      class Messages::SendService
        def process
          Faraday.post(url, message)
        end
      end
    RUBY
  end

  it "suppresses offenses already listed in fleet_todo.yml" do
    @root.join("fleet_todo.yml").write({
      "Neeto/WebhooksBypass" => { "files" => { webhook_service_path => 1 } }
    }.to_yaml)

    expect_no_offenses(<<~RUBY, webhook_service_path)
      class Messages::WebhookService
        def process
          Faraday.post(endpoint.url, payload.to_json)
        end
      end
    RUBY
  end

  it "flags the EXTRA offense when a file has more bypasses than recorded" do
    @root.join("fleet_todo.yml").write({
      "Neeto/WebhooksBypass" => { "files" => { webhook_service_path => 1 } }
    }.to_yaml)

    expect_offense(<<~RUBY, webhook_service_path)
      class Messages::WebhookService
        def process
          Faraday.post(endpoint.url, payload.to_json)
          HTTParty.post(endpoint.url, body: payload)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense_message("HTTParty", :post)}
        end
      end
    RUBY
  end

  it "suppresses all offenses in record mode" do
    ENV["NEETO_FLEET_RECORD"] = "1"
    expect_no_offenses(<<~RUBY, webhook_service_path)
      class Messages::WebhookService
        def process
          Faraday.post(endpoint.url, payload.to_json)
          HTTParty.post(endpoint.url, body: payload)
        end
      end
    RUBY

    todo = RuboCop::Neeto::FleetTodo.for(@root)
    counts = todo.instance_variable_get(:@observed_counts)
    expect(counts.dig("Neeto/WebhooksBypass", webhook_service_path)).to eq(2)
  end

  private

    def offense_message(receiver, method_name)
      message = format(
        RuboCop::Cop::Neeto::WebhooksBypass::MSG,
        receiver:,
        method: method_name)
      "Neeto/WebhooksBypass: #{message}"
    end
end
