module Indago
  class Searcher
    class NoIndexError < StandardError; end
    attr_reader :collection_name

    def initialize(collection_name)
      @collection_name = collection_name
      @stored_fields_data = {}
      @relations_populator = RelationsPopulator.new(collection_name)
    end

    def call(field, value)
      Indago.logger.info("Searching #{@collection_name} for field `#{field}` with a value of '#{value}'")
      load_and_process_result(field, value)
    rescue NoIndexError => e
      Indago.logger.fatal e.message
      []
    end

    def list_fields
      @listed_fields ||= Dir.glob(File.join(INDEXES_DIR_PATH, @collection_name,
                                            "*#{INDEX_FILE_EXTENSION}")).map do |path|
        File.basename(path, INDEX_FILE_EXTENSION)
      end.sort
    end

    def ids_from_tree_for(field, value)
      field_data = load_data_for(field)
      (field_data[value.to_s] || []).map(&:to_s)
    end

    private

    def load_data_for(field)
      return @stored_fields_data[field] unless @stored_fields_data[field].nil?
      path_to_index = File.join(INDEXES_DIR_PATH, @collection_name, "#{field}#{INDEX_FILE_EXTENSION}")
      unless File.exist? path_to_index
        raise NoIndexError, "#{field} field could not be searched within #{@collection_name} either because you have "\
                            'not yet run bin/indago index, or because this field could not be found within any items '\
                            "of #{@collection_name}, or because this field is of un-indexable format."
      end
      @stored_fields_data[field] = JSON.parse(File.read(path_to_index)) || {}
    end

    def load_and_process_result(field, value)
      full_records = load_data_for(PRIMARY_FIELD_NAME)
      result = if field == PRIMARY_FIELD_NAME
                 [full_records[value.to_s]] # all keys in JSON are strings
               else
                 full_records.values_at(*ids_from_tree_for(field, value))
               end
      @relations_populator.process(result)
      result
    end
  end
end
