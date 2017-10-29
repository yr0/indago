module Indago
  class RelationsPopulator
    def initialize(collection_name)
      @collection_name = collection_name
      @basic_data = {}
      @searchers = {}
    end

    def process(results_array)
      results_array.each { |item| populate(item) }
    end

    def populate(item)
      RELATIONS[@collection_name.to_sym].each do |options|
        relation_options = options.dup
        collection = relation_options[:collection]
        collection_data = basic_data_for(collection)
        next if collection_data.empty?
        send("populate_as_#{relation_options[:kind]}", item, collection_data, relation_options)
      end
    end

    private

    def basic_data_for(collection)
      return @basic_data[collection] unless @basic_data[collection].nil?
      path_to_index = File.join(INDEXES_DIR_PATH, collection, 'basic', "basic#{INDEX_FILE_EXTENSION}")
      if File.exist? path_to_index
        @basic_data[collection] = JSON.parse(File.read(path_to_index)) || {}
      else
        Indago.logger.warn("#{@collection_name} collection requires basic data from #{collection} collection,"\
                           ' but it was not indexed.')
        @basic_data[collection] = {}
      end
    end

    def searcher_for(collection)
      @searchers[collection] ||= Searcher.new(collection)
    end

    def populate_as_child(item, collection_data, options)
      parent_id_field = options[:key]
      parent_name_field = options[:as]
      parent_basic_value = collection_data[item[parent_id_field].to_s]
      # We could modify this logic to output some generic value for missing parent
      item[parent_name_field] = parent_basic_value unless parent_basic_value.nil?
    end

    def populate_as_parent(item, collection_data, options)
      values_from_field(options[:collection], options[:key], item[PRIMARY_FIELD_NAME]).each.with_index do |ticket_id, i|
        item["#{options[:as]}_#{i + 1}"] = collection_data[ticket_id.to_s]
      end
    rescue Searcher::NoIndexError
      Indago.logger.debug("Looks like the index for related field #{options[:key]} does not exist"\
                          " for #{options[:collection]} index. Skipping.")
    end

    def values_from_field(collection, field, value)
      searcher_for(collection).ids_from_tree_for(field, value)
    end
  end
end
