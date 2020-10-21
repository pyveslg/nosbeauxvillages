require "deep_symbolize"

# Load all static yml data
class Static
  def self.load
    original_verbosity = $VERBOSE
    $VERBOSE = nil
    files.each do |file|
      constant = File.basename(file, ".*")
      const_set(constant.upcase, load_file(file))
    end
    $VERBOSE = original_verbosity
  end

  private

  def self.load_file(file)
    hash = YAML::load_file(file)
    hash.extend DeepSymbolizable
    hash.deep_symbolize { |key| key }
  end

  def self.files
    Dir["#{File.dirname(__FILE__)}/../data/*.yml"]
  end
end
