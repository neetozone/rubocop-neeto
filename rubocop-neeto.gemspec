# frozen_string_literal: true

require_relative "lib/rubocop/neeto/version"

Gem::Specification.new do |spec|
  spec.name = "rubocop-neeto"
  spec.version = RuboCop::Neeto::VERSION
  spec.authors = ["Abhay V Ashokan"]
  spec.email = ["abhay.ashokan@bigbinary.com"]

  spec.summary = "Custom RuboCop cops for Neeto"
  spec.homepage = "https://github.com/neetozone/rubocop-neeto"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir["{app,config,db,lib,test}/**/*", "Rakefile", "README.md"]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'rubocop'
end
