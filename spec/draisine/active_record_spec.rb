require "spec_helper_ar"

describe Draisine::ActiveRecordPlugin, :model do
  let(:model) { Lead }
  let(:syncer) { instance_double(Draisine::Syncer).as_null_object }
  let(:system_modstamp) { Time.current }

  before do
    allow(model).to receive(:salesforce_syncer) { syncer }
  end

  describe ".salesforce_inbound_update" do
    let(:inbound_attrs) {
      {
        "Id" => "A001",
        "FirstName" => "John",
        "LastName" => "Doe",
        "CustomAttribute__c" => "32876",
        "SystemModstamp" => system_modstamp.iso8601
      }
    }

    it "creates a record if it doesn't exist yet" do
      expect {
        model.salesforce_inbound_update(inbound_attrs)
      }.to change { model.count }.by(1)
      lead = model.find_by_salesforce_id('A001')
      expect(lead.FirstName).to eq 'John'
      expect(lead.LastName).to eq 'Doe'
      expect(lead.custom_attribute).to eq '32876'
    end

    it "updates a record if it already exists" do
      lead = model.create_without_callbacks!(salesforce_id: 'A001', FirstName: 'Arnold', LastName: 'Schwartzenegger')
      expect {
        model.salesforce_inbound_update(inbound_attrs)
      }.not_to change { model.count }
      lead.reload
      expect(lead.FirstName).to eq 'John'
      expect(lead.LastName).to eq 'Doe'
    end

    it "doesn't update the record if system modstamp on record is less than or equal to salesforce_updated_at" do
      lead = model.create_without_callbacks!(salesforce_id: 'A001', FirstName: 'Jack', salesforce_updated_at: system_modstamp)
      model.salesforce_inbound_update(inbound_attrs)
      lead.reload
      expect(lead.FirstName).to eq 'Jack'
    end

    it "nulls missing attribute values" do
      lead = model.create_without_callbacks!(salesforce_id: 'A001', FirstName: 'John')
      model.salesforce_inbound_update({ 'Id' => 'A001' })
      lead.reload
      expect(lead.FirstName).to be_nil
    end

    it "doesn't null missing attributes values if add_blanks arg is false" do
      lead = model.create_without_callbacks!(salesforce_id: 'A001', FirstName: 'John')
      model.salesforce_inbound_update({ 'Id' => 'A001' }, false)
      lead.reload
      expect(lead.FirstName).to eq('John')
    end
  end

  describe ".salesforce_inbound_delete" do
    it "deletes a model with matching salesforce id" do
      model.create_without_callbacks!(salesforce_id: 'A001')
      expect {
        model.salesforce_inbound_delete('A001')
      }.to change { model.count }.by(-1)
    end

    it "doesn't trigger after destroy callback" do
      model.create_without_callbacks!(salesforce_id: 'A001')
      expect(syncer).not_to receive(:delete)
      model.salesforce_inbound_delete('A001')
    end
  end

  describe "#salesforce_outbound_create" do
    subject { model.new(FirstName: 'Mark', custom_attribute: '322') }
    let(:created_sf_response) {
      {
        "id" => "A002",
        "success" => true,
        "errors" => []
      }
    }

    it "posts reverse mapped attributes to the syncer" do
      expect(syncer).to receive(:create).with({
        'FirstName' => 'Mark',
        'CustomAttribute__c' => '322'
      }).and_return(created_sf_response)
      subject.salesforce_outbound_create
    end

    it "doesn't post unknown attributes" do
      subject.non_sf_attribute = 'unknown'
      expect(syncer).to receive(:create).with({
        'FirstName' => 'Mark',
        'CustomAttribute__c' => '322'
      }).and_return(created_sf_response)
      subject.salesforce_outbound_create
    end

    it "assigns salesforce_id from response in the before_create hook" do
      allow(syncer).to receive(:create).and_return(created_sf_response)
      subject.save!
      subject.reload
      expect(subject.salesforce_id).to eq('A002')
    end
  end

  describe "#salesforce_outbound_update" do
    subject { model.create_without_callbacks!(FirstName: 'Mark', salesforce_id: 'A000') }

    before do
      allow(syncer).to receive(:update)
      allow(syncer).to receive(:get_system_modstamp).and_return(Time.current)
    end

    it "sends an updated attribute hash to the syncer" do
      subject.FirstName = 'John'
      expect(syncer).to receive(:update).with('A000', {
        'FirstName' => 'John'
      })

      subject.salesforce_outbound_update({
        'FirstName' => 'John'
      })
    end

    it "updates #salesforce_updated_at field with updated system_modstamp" do
      subject.FirstName = 'John'
      time = 1.minute.since
      expect(syncer).to receive(:get_system_modstamp).with('A000').and_return(time)
      subject.salesforce_outbound_update({ 'FirstName' => 'John' })
      expect(subject.reload.salesforce_updated_at).to eq(time)
    end
  end

  describe "#salesforce_outbound_delete" do
    subject { model.create_without_callbacks!(salesforce_id: 'A000') }

    it "sends a delete request to the syncer" do
      expect(syncer).to receive(:delete).with('A000')
      subject.salesforce_outbound_delete
    end
  end
end
