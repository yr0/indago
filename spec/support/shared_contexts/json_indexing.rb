shared_context :json_indexing do
  let(:collection_name) { 'users' }
  let(:raw_json) { read_fixture_file('one_user.json') }
  let(:parsed_json) { JSON.parse(raw_json) }
end
