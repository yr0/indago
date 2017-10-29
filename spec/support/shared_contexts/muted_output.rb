shared_context :muted_output do
  before(:each) do
    allow_any_instance_of(Indago::Output).to receive(:output)
  end
end
