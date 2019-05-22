
require 'yaml'

class BaseExtensions
  attr_accessor :base_path, :base_yml

  def initialize(path)
    yml_validate(path)
    @base_path = path
    @base_yml = YAML::load_file(path)
  end

  def yml_validate(path)
    unless ['.yaml', '.yml'].include? File.extname(path)
      raise 'Base Extesions requires a .yml file'
    end
  end

  def find_ext(ext_name, category = 'extensions')
    index = find_ext_index(ext_name, category)
    @base_yml[category][index] if index != nil
  end

  def find_ext_index(ext_name, category = 'extensions')
    @base_yml[category].index{|ext| ext_name == ext['name']}
  end

  def patch!(patch_file)
    yml_validate(patch_file)
    patch_yml = YAML::load_file(patch_file)
    return false unless patch_yml
    ['extensions', 'native_modules'].each do |category|
      patch_yml.dig(category,'additions')&.each do |ext|
        idx = find_ext_index(ext['name'], category)
        if idx
          @base_yml[category][idx] = ext
        else
          @base_yml[category].push(ext)

        end
      end
      patch_yml.dig(category,'exclusions')&.each do |ext|
        idx = find_ext_index(ext['name'], category)
          @base_yml[category].delete_at(idx) if idx
      end
    end
    return true
  end

  def write_yml(extension_file)
    File.open(extension_file, 'w') {|f| f.write @base_yml.to_yaml }
  end
end


