require "tflat/version"
require 'erb'
require 'fileutils'
require 'ptools'
require 'json'
require 'digest'

module Tflat
  class Terraform
    attr_accessor :destination, :all_files, :args, :directory
    def initialize(args:, directory: '.')
      @workspace = ENV['TFLAT_WORKSPACE']
      @args = args.join(' ')
      @directory = directory
      @all_files = Dir.glob("#{directory}/**/*").select{|e| File.file?(e) && !e.match(/^\.tflat.*\/.+$/)}
      if @workspace
        @destination = "#{directory}/.tflat.#{@workspace}"
        @tag = "[tflat | #{@workspace}]"
        @tflat_folder = ".tflat.#{@workspace}"
      else
        @destination = "#{directory}/.tflat"
        @tag = "[tflat]"
        @tflat_folder = ".tflat"
      end

    end
    def run!
      if args.empty?
        puts `terraform`
        puts "\n\n- #{@tag} Notice: You must run tflat with terraform arguments.\n\n"
        return
      end
      setup
      read_variables
      puts "- #{@tag} Generating files"
      flatten_directories
      parse_erb
      puts " done!"
      puts "- #{@tag} Running: terraform #{args}"
      execute
    end

    def setup
      FileUtils.mkdir_p(destination)
      Dir.glob("#{@tflat_folder}/*").each do |entry|
        next unless File.file?(entry)
        FileUtils.rm_f entry
      end
    end

    def read_variables
      return unless File.file?('terraform.tfvars.json')
      @variables = JSON.parse(File.read 'terraform.tfvars.json')
      # Env vars TF_VAR_* will overwrite anything set on the JSON file.
      ENV.select{|k,v| k =~ /^TF_VAR_.+$/}.each do |k,v|
        name = k.sub('TF_VAR_', '')
        @variables[name] = v
      end
    end

    def flatten_directories
      all_files.each do |entry|
        next if entry =~ /#/
        new_name = entry.sub(/^#{directory}\//,'').gsub('/', '#')
        if new_name =~ /^#/ # Skip files/directories that start with a hash sign
          puts "- #{@tag} Skipping: #{entry}"
          next
        end
        FileUtils.cp(entry, "#{@tflat_folder}/#{new_name}")
      end
    end

    def parse_erb
      Dir.glob("#{@tflat_folder}/*").sort.each do |entry|
        next unless File.file?(entry)
        next if File.binary?(entry)
        puts "- #{@tag} -> #{entry}"
        begin
          rendered = render(entry)
        rescue Exception => e
          puts "- #{@tag} ERROR: Could not parse ERB on file #{entry}"
          puts e.message
          exit 1
        end
        File.write(entry, rendered)
      end
    end

    def f(file)
      file.sub(/^\.\//, "").gsub('/', '#')
    end

    def file(file)
      render(file).inspect[1...-1]
    end

    def file_sha256(ff)
      f = file(ff)
      Digest::SHA256.hexdigest(f)
    end

    def render(file)
      template = File.read(file)
      ERB.new(template).result(binding)
    end

    def execute
      exec "cd #{@tflat_folder} && terraform #{args}"
    end
  end
end
