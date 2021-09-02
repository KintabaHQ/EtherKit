Pod::Spec.new do |s|
  s.swift_versions   = [5.0]
  s.name             = 'EtherKit'
  s.version          = '0.2.0'
  s.summary          = 'A library for interacting with the Ethereum network.'

  s.description      = <<-DESC
  EtherKit provides some useful abstractions for interacting with the Ethereum network:

    * A spec-compliant JSONRPC API with both HTTPS/Websocket support.
    * A conversion engine that can convert between subdenominations of Ethereum.
    * A Keystore for generating and accessing Ethereum Wallets.
    * A codegen utility for generating Swift bindings for a Contract's ABI.
                       DESC

  s.homepage         = 'https://github.com/Vaultio/EtherKit'
  s.license          = { :type => 'Apache-2.0', :file => 'LICENSE' }
  s.authors          = "Vault, Inc."
  s.source           = { :git => 'https://github.com/Vaultio/EtherKit.git', :branch => 'next' }

  s.ios.deployment_target = '10.0'

  s.subspec 'Core' do |core|
    core.source_files = 'EtherKit/**/*'
    core.dependency 'BigInt'
    core.dependency 'Starscream'
    core.dependency 'Marshal'
    core.dependency 'CryptoSwift', "~> 1.4.1"
    core.dependency 'secp256k1.swift'
    core.dependency 'Result'
    core.resource_bundles = {
      'WordLists' => ['Assets/WordLists/*.txt']
    }
  end

  s.subspec 'PromiseKit' do |promisekit|
    promisekit.source_files = 'Extras/PromiseKit/*.swift'
    promisekit.dependency 'EtherKit/Core'
    promisekit.dependency 'PromiseKit/CorePromise'
  end
end
