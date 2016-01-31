SKIP_ENCRYPTION = %w[config.yml run.coffee]
RUN_SOURCE_FILE = 'run.coffee'

require 'bundler'
require 'fileutils'
require 'yaml' 
Bundler.require

desc 'Stub out a new function. Specify NAME=example'
task :stub do
  abort 'Specify NAME=example'    unless ENV['NAME']
  abort 'Function already exists' if Dir.exists?('functions/%s' % ENV['NAME'])

  FileUtils.mkdir('functions/%s'      % ENV['NAME'])
  File.open('functions/%s/config.yml' % ENV['NAME'], 'w') do |config|
    config << YAML.dump(    # TODO refactor this
              description: 'Compiled by Cheese Grater',
            function_name: ENV['NAME'],
                  handler: 'handler',
                  runtime: 'nodejs',
                     role: '',
    )
  end
  FileUtils.touch 'functions/%s/run.coffee' % ENV['NAME']
  puts '%s created.'                        % ENV['NAME']
end

desc 'Build each function into build/functionName.zip'
task build: :test do
  FileUtils.rm_rf 'build' and puts 'Removed build/ directory'
  FileUtils.mkdir 'build' and puts 'Re-initialized build/ directory' 

  Dir['functions/*'].each do |command|
    Zip::Archive.open 'build/%s.zip' % function, Zip::CREATE do |archive|
      puts 'Opened build/%s.zip archive' % function

      CoffeeScript.compile(File.read('%s/%s' % [function, RUN_SOURCE_FILE])).tap do |compiled_source|
        archive.add_buffer 'run.js', compiled_source    and puts 'Compiled source for %s' % function
      end
      archive.add_dir 'node_modules'                    and puts 'Added node_modules/ for %s' % function

      Dir['functions/%s/*' % command].reject(&SKIP_ENCRYPTION.method(:include?)).each do |file|
        data_key_request = { encryption_context: { function: command, file: file },
                                         key_id: '',
                                       key_spec: 'AES_256' }

        AWS::KMS.new.generate_data_key(data_key_request).tap do |key|
          OpenSSL::Cipher::AES256.new(:CBC).tap(&:encrypt).tap do |cipher|
            cipher.key = key.plaintext
            cipher.iv  = cipher.random_iv

            archive.add_buffer '%s.key' % File.basename(file), key.ciphertext_blob
            archive.add_buffer '%s.iv'  % File.basename(file), cipher.iv
            archive.add_buffer '%s.enc' % File.basename(file), 
              Base64.encode(cipher.update(File.read(file) << cipher.final))
          end
        end
        GC.start # useful? paranoid? whatever?
      end
    end
  end
end

task default: :build do
  functions = AWS::Lambda::Client.new.list_functions(max: 1_000)

  Dir['functions/*'].each do |command|
    config = begin
               YAML::load_file('functions/%s/config.yml').symbolize_keys
             rescue Errno::ENOENT # No file? That's okay. Other exceptions should bubble up.
               { }
             end

    if functions.none? { |function| function.name == function }
      AWS::Lambda::Client.new.create_function({
                     code: { zip_file: 'build/%s.zip' % function },
              description: 'Compiled by Cheese Grater',
            function_name: function,
                  handler: 'handler',
                  runtime: 'nodejs',
                     role: '',
      }.merge(config))
    else
      AWS::Lambda::Client.new.update_function_code(zip_file: 'build/%s.zip' % function)

      if (payload = config.slice(:descripton, :handler, :function_name, :timeout, :memory)).any?
        AWS::Lambda::Client.new.update_function_configuration(payload)
      end
    end
  end
end

task :test do
  Dir['functions/run.coffee'].each do |file|
    CoffeeScript.compile File.read file
  end
end

