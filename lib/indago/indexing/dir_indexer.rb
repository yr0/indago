module Indago
  module Indexing
    class DirIndexer
      # +collection_for_index+ allows to specify a collection to index. If unspecified, all JSON files within data dir
      # will be indexed
      def initialize(collection_for_index = nil)
        @collection_for_index = collection_for_index || '*'
      end

      def walk_and_index_data_dir!
        if json_files_from_dir.empty?
          Indago.logger.warn("Indexer could not find any *.json files within #{DATA_DIR_PATH}")
          return
        end
        json_files_from_dir.each do |path|
          pass_contents_to_indexer(File.expand_path(path))
        end
      end

      private

      def pass_contents_to_indexer(path)
        extension = File.extname(path)
        collection_name = File.basename(path, extension)
        JsonIndexer.new(collection_name, File.open(path, &:read)).call
      end

      def json_files_from_dir
        @json_files ||= Dir.glob(File.join(DATA_DIR_PATH, "#{@collection_for_index}.json"))
      end
    end
  end
end
