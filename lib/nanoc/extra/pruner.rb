# encoding: utf-8

module Nanoc::Extra

  # TODO document
	class Pruner

    # @return [Nanoc::Site] The site this pruner belongs to  
    attr_reader :site

    # @param [Nanoc::Site] The site for which a pruner is created
    #
    # @option params [Boolean] :dry_run (false) true if the files to be deleted
    # should only be printed instead of actually deleted, false if the files
    # should actually be deleted.
    def initialize(site, params={})
      @site    = site
      @dry_run = params.fetch(:dry_run) { false }
    end

    # Prunes all output files not managed by nanoc.
    #
    # @return [void]
    def run
      require 'find'

      # Get compiled files
      compiled_files = self.site.items.map do |item|
        item.reps.map do |rep|
          rep.raw_path
        end
      end.flatten.compact.select { |f| File.file?(f) }

      # Get present files and dirs
      present_files_and_dirs = Set.new
      Find.find(self.site.config[:output_dir]) do |f|
        present_files_and_dirs << f
      end
      present_files = present_files_and_dirs.select { |f| File.file?(f) }
      present_dirs  = present_files_and_dirs.select { |f| File.directory?(f) }

      # Remove stray files
      stray_files = present_files - compiled_files
      stray_files.each { |f| self.delete_file(f) }

      # Remove empty directories
      present_dirs.sort_by{ |d| -d.length }.each do |dir|
        next if Dir.foreach(dir) { |n| break true if n !~ /\A\.\.?\z/ }
        self.delete_dir(dir)
      end
    end

  protected

    def delete_file(file)
      if @dry_run
        puts file
      else
        Nanoc3::CLI::Logger.instance.file(:high, :delete, file)
        FileUtils.rm(file)
      end
    end

    def delete_dir(dir)
      if @dry_run
        puts dir
      else
        Nanoc3::CLI::Logger.instance.file(:high, :delete, dir)
        Dir.rmdir(dir)
      end
    end

  end

end
