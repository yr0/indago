module Indago
  module Indexing
    class JsonIndexer
      class ArrayNotProvided < StandardError; end
      class ArrayTooLarge < StandardError; end

      def initialize(collection_name, raw_json)
        @collection_name = collection_name
        @raw_json = raw_json
        @array_from_json = []
        @values_search_tree = {}
        # For look-ups of basic representations of related values
        @basic_data = {}
        # Directory where the collection's indexes will be stored
        @index_dir = File.join(INDEXES_DIR_PATH, @collection_name)
      end

      def call
        Indago.logger.info("Indexing #{@collection_name} collection")
        parse_and_check_raw!
        do_index
      rescue JSON::ParserError => e
        Indago.logger.fatal("The JSON for #{@collection_name} collection could not be parsed."\
                            'Abbreviated parser error is provided below')
        Indago.logger.fatal(e.to_s[0..200])
      rescue ArrayTooLarge, ArrayNotProvided => e
        Indago.logger.fatal(e.message)
      end

      private

      def parse_and_check_raw!
        if @raw_json.size > MAX_INDEXING_ARRAY_SIZE
          raise ArrayTooLarge, "The #{@collection_name} collection is too large. You could "\
                               'increase the constant value of Indago::MAX_INDEXING_ARRAY_SIZE if you feel adventurous.'
        end
        @array_from_json = JSON.parse(@raw_json)
        return if @array_from_json.is_a?(Array)
        raise ArrayNotProvided, "The JSON for #{@collection_name} is not an array."\
                                'Please refer to Assumptions about Data within README'
      end

      def do_index
        prepare_index_directory
        # This risks potential overflow since whole search tree has to be kept in memory.
        # That's why we check Indago::MAX_INDEXING_ARRAY_SIZE before we get here.
        @array_from_json.each do |item|
          SearchTreePopulator.new(item: item, search_tree: @values_search_tree, basic_data: @basic_data,
                                  collection_name: @collection_name).call
        end

        store_search_tree
        store_basic_data
      end

      def prepare_index_directory
        FileUtils.mkdir_p(File.join(@index_dir, 'basic'))
      end

      def store_search_tree
        @values_search_tree.each do |field, contents|
          dump_to_index_file(contents, "#{field}#{INDEX_FILE_EXTENSION}")
        end
      end

      def store_basic_data
        dump_to_index_file(@basic_data, 'basic', "basic#{INDEX_FILE_EXTENSION}")
      end

      def dump_to_index_file(contents, *path_components)
        File.open(File.join(@index_dir, *path_components), 'w') do |f|
          f.write(JSON.dump(contents))
        end
      end
    end
  end
end
