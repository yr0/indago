shared_context :relations_populating do
  include_context :with_real_indexes

  let(:collection_name) { 'users' }
  let(:item) { { '_id' => 1, 'organization_id' => 2 } }
  let(:organizations_options) do
    { collection: 'organizations', kind: 'child', key: 'organization_id', as: 'organization_name' }
  end
  let(:tickets_options) do
    { collection: 'tickets', kind: 'parent', key: 'submitter_id', as: 'submitted_ticket' }
  end
  let(:relations) { { users: [organizations_options, tickets_options] } }
  let(:collection_data) { { '1' => [2, 3] } }
  let(:related_collection) { 'organizations' }
  let(:unexisting_collection) { 'voids' }
  let(:related_collection_basics) do
    JSON.parse File.read(File.join(Indago::INDEXES_DIR_PATH, related_collection, 'basic',
                                   "basic#{Indago::INDEX_FILE_EXTENSION}"))
  end
end
