require 'active_support'
require 'active_support/dependencies'
require 'json'
require 'fileutils'

ActiveSupport::Dependencies.autoload_paths << File.join(File.dirname(__FILE__), 'indago')
$LOAD_PATH.unshift(File.dirname(__FILE__))

module Indago
  extend ActiveSupport::Autoload

  LOGGER_LEVEL = Logger::INFO
  WITHIN_PROJECT_DIR = ->(target) { File.expand_path(File.join(File.dirname(__FILE__), '..', target)) }
  # Path where JSON files for search are stored. This directory should be populated by user of the program
  DATA_DIR_PATH = WITHIN_PROJECT_DIR.call('data').freeze
  # Path where indexes will be stored. User should never change anything within this directory except for the case
  # she/he wants a clean index, in which case clearing the directory and running indago index should do the trick.
  INDEXES_DIR_PATH = WITHIN_PROJECT_DIR.call('indexes').freeze
  # Maximum size of a JSON array collection in bytes. We need to stop somewhere before we cause memory overflow
  # Per example 100_000 items would take about 1 GB (10^9 bytes) of in-memory space.
  # When we transform that to a search tree, this value could even triple.
  # So in order to calculate appropriate value for this constant, check if the amount of memory you are willing to
  # sacrifice in bytes is bigger than (MAX_INDEXING_ARRAY_SIZE * 3)
  MAX_INDEXING_ARRAY_SIZE = 10**9
  # Name of field that is considered primary (unique) for each entity within all collections.
  PRIMARY_FIELD_NAME = '_id'.freeze
  # Extension of index files. Used mostly for cosmetical purposes
  INDEX_FILE_EXTENSION = '.json'.freeze
  # Max width of table with found entity, in terminal units
  OUTPUT_TABLE_MAX_WIDTH = 100

  ##
  # CONTEXT-DEPENDENT CONSTANTS
  # We do this workaround for brevity. I could write a DSL for models within JSON collections, to build a graph of
  # relations more expressively, however that seems to be out of scope of this simpler task. If we wanted to add
  # another collection with relations, it would be simple enough with this hash.
  RELATIONS = {
    users: [
      { collection: 'organizations', kind: 'child', key: 'organization_id', as: 'organization_name' },
      { collection: 'tickets', kind: 'parent', key: 'submitter_id', as: 'submitted_ticket' },
      { collection: 'tickets', kind: 'parent', key: 'assignee_id', as: 'assigned_ticket' },
      { collection: 'tickets', kind: 'parent', key: 'requester_id', as: 'requested_ticket' }
    ],
    organizations: [
      { collection: 'users', kind: 'parent', key: 'organization_id', as: 'user_name' },
      { collection: 'tickets', kind: 'parent', key: 'organization_id', as: 'ticket' }
    ],
    tickets: [
      { collection: 'organizations', kind: 'child', key: 'organization_id', as: 'organization_name' },
      { collection: 'users', kind: 'child', key: 'submitter_id', as: 'submitter_name' },
      { collection: 'users', kind: 'child', key: 'assignee_id', as: 'assignee_name' },
      { collection: 'users', kind: 'child', key: 'requester_id', as: 'requester_name' }
    ]
  }.freeze
  # Basic data field is a field that contains essential value about entity, like its name or short description. The
  # value of this field will be stored and displayed as related information for entities.
  DEFAULT_BASIC_DATA_FIELD = 'name'.freeze
  CUSTOM_BASIC_DATA_FIELDS = { tickets: 'subject' }.freeze
  BASIC_DATA_FIELDS = Hash.new { |_, key| CUSTOM_BASIC_DATA_FIELDS[key] || DEFAULT_BASIC_DATA_FIELD }
  #
  ##

  autoload :CLI
  autoload :Output
  autoload :Searcher
  autoload :RelationsPopulator

  module Indexing
    extend ActiveSupport::Autoload

    autoload :DirIndexer
    autoload :JsonIndexer
    autoload :SearchTreePopulator
  end

  class << self
    def logger
      @logger ||= Logger.new(STDOUT, level: LOGGER_LEVEL)
    end

    def available_indexes
      @available_indexes ||= Dir.glob(File.join(INDEXES_DIR_PATH, '*')).map do |path|
        File.basename(path) if File.directory?(path)
      end.compact
    end
  end
end
