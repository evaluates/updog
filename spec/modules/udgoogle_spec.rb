require 'spec_helper'
require 'ostruct'

class Test
  include Udgoogle
end

describe Udgoogle do
  it "prettifies json" do
    file = {
      whole: 'lotta',
      junk: 'here',
      all: 'i',
      want: 'is',
      the: 'following:',
      mime_type: 'application/vnd.google-apps.folder',
      title: 'jesse'
    }
    f = OpenStruct.new file
    input = [f]
    t = Test.new
    expect(t.json(input,"").to_json).to eq([{title:'jesse', ".tag": 'folder', path_lower: '/jesse'}].to_json)
  end
end
