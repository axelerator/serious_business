$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "serious_business/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "serious_business"
  s.version     = SeriousBusiness::VERSION
  s.authors     = ["Axel Tetzlaff"]
  s.email       = ["axel.tetzlaff@gmx.de"]
  s.homepage    = "https://github.com/axelerator"
  s.summary     = "A gem to formalize application flow of views and actions"
  s.description = "Secure your app by using our structured data model to specify the data flow between views and semnatic actions"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.0"
  #TODO:  for interpolation in action description need to figure out howto store interpolation
  #s.add_dependency 'i18n-dot_lookup'

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "byebug"
end
