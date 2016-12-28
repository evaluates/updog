require 'spec_helper'

describe Identity do
  describe '#new' do
    before do
      @user = User.last
    end
    it "can be created" do
      iden = Identity.new
      expect(iden.class).to be(Identity)
    end
  end
end