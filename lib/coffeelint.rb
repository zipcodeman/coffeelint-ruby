require "coffeelint/version"
require 'execjs'
require 'coffee-script'

module Coffeelint
  require 'coffeelint/railtie' if defined?(Rails)

  def self.path()
    @path ||= File.expand_path('../../coffeelint/src/coffeelint.coffee', __FILE__)
  end

  def self.colorize(str, color_code)
    "\e[#{color_code}m#{str}\e[0m"
  end

  def self.red(str, pretty_output = true)
    pretty_output ? Coffeelint.colorize(str, 31) : str
  end

  def self.green(str, pretty_output = true)
    pretty_output ? Coffeelint.colorize(str, 32) : str
  end

  def self.lint(script, config = {})
    coffeescriptSource = File.read(CoffeeScript::Source.path)
    coffeelintSource = CoffeeScript.compile(File.read(Coffeelint.path))
    context = ExecJS.compile(coffeescriptSource + coffeelintSource)
    context.call('coffeelint.lint', script, config)
  end

  def self.lint_file(filename, config = {})
    Coffeelint.lint(File.read(filename), config)
  end

  def self.lint_dir(directory, config = {})
    retval = {}
    Dir.glob("#{directory}/**/*.coffee") do |name|
      retval[name] = Coffeelint.lint_file(name, config)
      yield name, retval[name] if block_given?
    end
    retval
  end

  def self.display_test_results(name, errors, pretty_output = true)
    good = pretty_output ? "\u2713" : 'Passed'
    bad = pretty_output ? "\u2717" : 'Failed'

    if errors.length == 0
      puts "  #{good} " + Coffeelint.green(name, pretty_output)
      return true
    else
      puts "  #{bad} " + Coffeelint.red(name, pretty_output)
      errors.each do |error|
        print "     #{bad} "
        print CoffeeLint.red(error["lineNumber"], pretty_output)
        puts ": #{error["message"]}, #{error["context"]}."
      end
      return false
    end
  end

  def self.run_test(file, config = {})
    pretty_output = config.has_key?(:pretty_output) ? config.delete(:pretty_output) : true
    result = Coffeelint.lint_file(file, config)
    Coffeelint.display_test_results(file, result, pretty_output)
  end

  def self.run_test_suite(directory, config = {})
    pretty_output = config.has_key?(:pretty_output) ? config.delete(:pretty_output) : true
    success = true
    Coffeelint.lint_dir(directory, config) do |name, errors|
      result = Coffeelint.display_test_results(name, errors, pretty_output)
      success = false if not result
    end
    success
  end
end
