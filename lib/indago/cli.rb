require 'thor'

module Indago
  class CLI < Thor
    desc 'index', 'Run before search: Index all JSON files within data directory'
    method_option :collection,
                  type: :string, aliases: '-c',
                  banner: 'Name of collection to index. Will index all files within data directory if empty.'
    def index
      Indexing::DirIndexer.new(options['collection']).walk_and_index_data_dir!
    end

    desc 'search', 'Run after index: Perform continuous search on model or do an instant search by providing options'
    method_option :collection,
                  type: :string, aliases: '-c', required: true, enum: Indago.available_indexes,
                  banner: 'Name of collection to search within'
    method_option :field,
                  type: :string, aliases: '-f',
                  banner: 'Field name. If not provided, the search will be continuous'
    method_option :value,
                  type: :string, aliases: '-v', default: '',
                  banner: 'Value to search the record for. If not provided, empty value is assumed'
    def search
      collection = options['collection']
      searcher = Searcher.new(collection)
      if options.keys.include?('field')
        Output.new(collection, searcher.call(options['field'], options['value'])).table_print
      else
        do_continuous_search(searcher)
      end
    end

    desc 'list_fields', 'List available fields for collection'
    method_option :collection,
                  type: :string, aliases: '-c', required: true, enum: Indago.available_indexes,
                  banner: 'Name of collection to list fields from. Will fail unless you run index first'
    def list_fields
      collection = options['collection']
      searcher = Searcher.new(collection)
      Output.new(collection).print_listed_fields(searcher.list_fields)
    end

    private

    def do_continuous_search(searcher)
      Indago.logger.info("Available fields: #{searcher.list_fields.join(', ')}")
      loop do
        Indago.logger.info('This is a continuous search. Press Ctrl+C at any time to quit')
        field = ask 'Enter the field name:'
        value = ask 'Enter the value to search the record for:'
        Output.new(searcher.collection_name, searcher.call(field, value)).table_print
      end
    end
  end
end
