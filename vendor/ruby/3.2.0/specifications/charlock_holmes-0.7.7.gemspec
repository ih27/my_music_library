# -*- encoding: utf-8 -*-
# stub: charlock_holmes 0.7.7 ruby lib
# stub: ext/charlock_holmes/extconf.rb

Gem::Specification.new do |s|
  s.name = "charlock_holmes".freeze
  s.version = "0.7.7".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Brian Lopez".freeze, "Vicent Mart\u00ED".freeze]
  s.date = "2019-11-08"
  s.description = "charlock_holmes provides binary and text detection as well as text transcoding using libicu".freeze
  s.email = "seniorlopez@gmail.com".freeze
  s.extensions = ["ext/charlock_holmes/extconf.rb".freeze]
  s.files = ["ext/charlock_holmes/extconf.rb".freeze]
  s.homepage = "https://github.com/brianmario/charlock_holmes".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--charset=UTF-8".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3".freeze)
  s.rubygems_version = "3.1.0.pre1".freeze
  s.summary = "Character encoding detection, brought to you by ICU".freeze

  s.installed_by_version = "3.5.11".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<rake-compiler>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.11".freeze])
  s.add_development_dependency(%q<chardet>.freeze, ["~> 0.9".freeze])
end
