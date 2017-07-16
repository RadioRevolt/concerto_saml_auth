$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "concerto_saml_auth/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "concerto_saml_auth"
  s.version     = ConcertoSamlAuth::VERSION
  s.authors     = ["Gabe Perez", "Thorben Dahl"]
  s.email       = ["perez283@gmail.com", "thorben@sjostrom.no"]
  s.homepage    = "http://www.concerto-signage.org"
  s.summary     = "Provides user authentication using SAML"
  s.description = "Authorize Concerto users with SAML"
  s.license     = "Apache-2.0"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails"
  s.add_dependency "omniauth-saml"
  s.add_dependency "concerto_identity"
  s.add_dependency "activerecord-session_store"

end
