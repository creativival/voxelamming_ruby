# frozen_string_literal: true

require_relative "lib/voxelamming/version"

Gem::Specification.new do |spec|
  spec.name = "voxelamming"
  spec.version = Voxelamming::VERSION
  spec.authors = ["creativival"]
  spec.email = ["creativival@gmail.com"]

  spec.summary = "This Ruby package converts Ruby code into JSON format and sends it to the Voxelamming app using WebSockets, allowing users to create 3D voxel models by writing Ruby scripts.."
  spec.description = "Voxelamming is an AR programming learning app. Even programming beginners can learn programming visually and enjoyably. Voxelamming supports iPhones and iPads with iOS 16 or later, and Apple Vision Pro."
  spec.homepage = "https://creativival.github.io/voxelamming"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/creativival/voxelamming_gem"
  spec.metadata["changelog_uri"] = "https://creativival.github.io/voxelamming_gem/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_runtime_dependency 'faye-websocket', '~> 0.11.3'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
