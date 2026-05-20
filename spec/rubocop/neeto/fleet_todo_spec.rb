# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe RuboCop::Neeto::FleetTodo do
  around do |example|
    Dir.mktmpdir do |dir|
      @root = Pathname.new(dir)
      FileUtils.touch(@root.join("Gemfile"))
      described_class.reset!
      example.run
    end
  end

  let(:cop) { "Neeto/WebhooksBypass" }
  let(:file) { @root.join("app/services/messages/webhook_service.rb").to_s }

  before { FileUtils.mkdir_p(File.dirname(file)) }

  describe "#listed?" do
    it "returns false when no entries exist" do
      todo = described_class.new(@root)
      expect(todo.listed?(cop, file, 0)).to be(false)
    end

    it "returns true while the observation index is below the recorded count" do
      seed_todo(cop => { "files" => { "app/services/messages/webhook_service.rb" => 2 } })
      todo = described_class.new(@root)
      expect(todo.listed?(cop, file, 0)).to be(true)
      expect(todo.listed?(cop, file, 1)).to be(true)
      expect(todo.listed?(cop, file, 2)).to be(false)
    end
  end

  describe "#observe! and #violations_over_limit" do
    it "flags files whose observed count exceeds the recorded ceiling" do
      seed_todo(cop => { "files" => { "app/services/messages/webhook_service.rb" => 1 } })
      todo = described_class.new(@root)
      todo.observe!(cop, file)
      todo.observe!(cop, file)

      report = todo.violations_over_limit
      expect(report).to eq(cop => { "app/services/messages/webhook_service.rb" => { observed: 2, allowed: 1 } })
    end

    it "is empty when observed equals ceiling" do
      seed_todo(cop => { "files" => { "app/services/messages/webhook_service.rb" => 1 } })
      todo = described_class.new(@root)
      todo.observe!(cop, file)
      expect(todo.violations_over_limit).to be_empty
    end
  end

  describe "#stale_entries" do
    it "reports files whose observed count is below the recorded ceiling" do
      seed_todo(cop => { "files" => { "app/services/messages/webhook_service.rb" => 2 } })
      todo = described_class.new(@root)
      todo.observe!(cop, file)
      expect(todo.stale_entries).to eq(
        cop => { "app/services/messages/webhook_service.rb" => { observed: 1, allowed: 2 } }
      )
    end

    it "is empty when observation matches the ceiling" do
      seed_todo(cop => { "files" => { "app/services/messages/webhook_service.rb" => 1 } })
      todo = described_class.new(@root)
      todo.observe!(cop, file)
      expect(todo.stale_entries).to be_empty
    end
  end

  describe "#dump_recording!" do
    it "writes observed counts and a human-readable header" do
      todo = described_class.new(@root)
      todo.observe!(cop, file)
      todo.observe!(cop, file)
      todo.dump_recording!

      contents = todo.path.read
      expect(contents).to include("This file lists pre-existing bypasses")
      data = YAML.safe_load(contents.sub(/\A(#[^\n]*\n)*\n?/, ""))
      expect(data).to eq(cop => { "files" => { "app/services/messages/webhook_service.rb" => 2 } })
    end

    it "deletes the file when no observations were made" do
      seed_todo(cop => { "files" => { "x.rb" => 1 } })
      todo = described_class.new(@root)
      todo.dump_recording!
      expect(todo.path.exist?).to be(false)
    end
  end

  def seed_todo(data)
    @root.join("fleet_todo.yml").write(data.to_yaml)
  end
end
