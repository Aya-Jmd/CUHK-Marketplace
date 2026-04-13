if Gem.win_platform?
  module WindowsViewResolverPatch
    private

    def template_glob(glob)
      Dir.chdir(@path) do
        Dir.glob(glob).filter_map do |filename|
          expanded_path = File.expand_path(filename, @path)
          next if File.directory?(expanded_path)

          expanded_path
        end
      end
    end
  end

  ActionView::FileSystemResolver.prepend(WindowsViewResolverPatch)
end
