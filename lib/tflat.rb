require "tflat/version"
require 'erb'
require 'fileutils'
require 'ptools'

module Tflat
  class Terraform
    attr_accessor :destination, :all_files, :args, :directory
    def initialize(args:, directory: '.')
      @args = args.join(' ')
      @directory = directory
      @all_files = Dir.glob("#{directory}/**/*").select{|e| File.file?(e) && !e.match(/^\.tflat\/.+$/)}
      @destination = "#{directory}/.tflat"
    end
    def run!
      if args.empty?
        puts `terraform`
        puts "\n\n- [tflat] Notice: You must run tflat with terraform arguments.\n\n"
        return
      end
      setup
      print "- [tflat] Generating files..."
      flatten_directories
      parse_erb
      puts " done!"
      puts "- [tflat] Running: terraform #{args}"
      execute
    end

    def setup
      FileUtils.mkdir_p(destination)
      Dir.glob('.tflat/*').each do |entry|
        next unless File.file?(entry)
        FileUtils.rm_f entry
      end
    end

    def flatten_directories
      all_files.each do |entry|
        new_name = entry.sub(/^#{directory}\//,'').gsub('/', '#')
        if new_name =~ /^#/ # Skip files/directories that start with a hash sign
          puts "- [tflat] Skipping: #{entry}"
          next
        end
        FileUtils.cp(entry, ".tflat/#{new_name}")
      end
    end

    def parse_erb
      Dir.glob(".tflat/*").each do |entry|
        next unless File.file?(entry)
        next if File.binary?(entry)
        rendered = render(entry)
        File.write(entry, rendered)
      end
    end

    def f(file)
      file.sub(/^\.\//, "").gsub('/', '#')
    end

    def file(file)
      f = ".tflat/#{f(file)}"
      File.read(f).inspect[1...-1]
    end

    def render(file)
      template = File.read(file)
      ERB.new(template).result(binding)
    end

    def execute
      exec "cd .tflat && terraform #{args}"
    end
  end
end
