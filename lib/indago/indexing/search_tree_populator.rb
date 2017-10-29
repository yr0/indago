module Indago
  module Indexing
    class SearchTreePopulator
      # +search_tree+ is a hash for collection where keys correspond to collection fields seen so far and values
      # correspond to possible values within collection. The values in turn are assigned an array of item ids within
      # collection that have this value
      # +item+ is a single JSON hash entry from collection
      # +basic_data+ is a hash with item ids as keys and their basic field representations (name, subject) as values
      # +collection_name+ is just a string with name of collection
      def initialize(search_tree:, item:, basic_data:, collection_name:)
        @search_tree = search_tree
        @item = item
        @basic_data = basic_data
        @collection_name = collection_name
        @item_id = nil
      end

      def call
        @item_id = @item[PRIMARY_FIELD_NAME]&.to_s
        if @item_id.nil?
          Indago.logger.warn("#{@item} does not have #{PRIMARY_FIELD_NAME} to identify it by. It will not be indexed.")
          return
        end

        @item.each do |key, value|
          populate_tree_with(key, value)
        end
      end

      def populate_tree_with(key, value)
        @search_tree[key] ||= {}
        @basic_data[@item_id] = value if BASIC_DATA_FIELDS[@collection_name.to_sym] == key.to_s
        if key == PRIMARY_FIELD_NAME
          populate_primary_field(value)
        else
          populate_by_value_type(key, value)
        end
      end

      def populate_primary_field(value)
        if @search_tree[PRIMARY_FIELD_NAME][value].nil?
          @search_tree[PRIMARY_FIELD_NAME][value] = @item
        else
          Indago.logger.warn("Duplicate #{PRIMARY_FIELD_NAME} within #{@collection_name}: #{value}. Ignoring.")
        end
      end

      def populate_by_value_type(key, value, allow_arrays = true)
        if allow_arrays && value.is_a?(Array)
          # We allow only one level of nesting within arrays
          value.each { |array_item| populate_by_value_type(key, array_item, false) }
        elsif [String, Integer, Float, TrueClass, FalseClass, NilClass].any? { |klass| value.is_a?(klass) }
          @search_tree[key][value] ||= []
          @search_tree[key][value] << @item_id
        else
          Indago.logger.warn("The value '#{value}' (of #{key}) within #{@collection_name} (#{@item_id})"\
                             'is of unsupported format. The users will not be able to search by it.')
        end
      end
    end
  end
end
