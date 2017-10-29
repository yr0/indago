require 'terminal-table'

module Indago
  class Output
    attr_accessor :collection, :result

    def initialize(collection, result = [])
      @collection = collection
      @result = result
    end

    def print_listed_fields(fields)
      output "Search fields for #{collection}:"
      output fields.join("\n")
    end

    def table_print
      if result.empty?
        output Terminal::Table.new rows: [['No results found']]
        return
      end
      result.each do |item|
        output Terminal::Table.new(title: "#{collection.singularize.capitalize} ##{item[Indago::PRIMARY_FIELD_NAME]}",
                                   rows: wrap_values(item))
      end
    end

    private

    def output(value)
      puts value
    end

    def wrap_values(item)
      item.each do |key, value|
        item[key] = wrap(value) if value.to_s.size > OUTPUT_TABLE_MAX_WIDTH
      end
    end

    def wrap(value)
      value = value.to_s
      insert_break_at = OUTPUT_TABLE_MAX_WIDTH
      while value.size > insert_break_at
        value.insert(insert_break_at, "\n")
        insert_break_at += OUTPUT_TABLE_MAX_WIDTH + 1
      end
      value
    end
  end
end
