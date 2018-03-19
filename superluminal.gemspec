Gem::Specification.new do |gem|
  tag = `git describe --tags --abbrev=0`.chomp

  gem.name          = 'superluminal'
  gem.homepage      = 'http://github.com/colstrom/superluminal'
  gem.summary       = 'Picking up where Ansible falls down.'

  gem.version       = "#{tag}"
  gem.licenses      = ['MIT']
  gem.authors       = ['Chris Olstrom']
  gem.email         = 'chris@olstrom.com'

  gem.cert_chain    = ['trust/certificates/colstrom.pem']
  gem.signing_key   = File.expand_path ENV.fetch 'GEM_SIGNING_KEY'

  gem.files         = `git ls-files -z`.split("\x0")
  gem.test_files    = `git ls-files -z -- {test,spec,features}/*`.split("\x0")
  gem.executables   = `git ls-files -z -- bin/*`.split("\x0").map { |f| File.basename(f) }

  gem.require_paths = ['lib']

  gem.add_runtime_dependency 'aws-sdk',           '~> 2.2',  '>= 2.2.0'
  gem.add_runtime_dependency 'commander',         '~> 4.3',  '>= 4.3.0'
  gem.add_runtime_dependency 'multi_json',        '~> 1.11', '>= 1.11.0'
  gem.add_runtime_dependency 'settingslogic',     '~> 2.0',  '>= 2.0.0'
  gem.add_runtime_dependency 'terminal-announce', '~> 1.0'   '>= 1.0.0'
end
