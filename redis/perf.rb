require 'pry'
require 'json'

class RedisPerf
  def initialize
    @stats = %x[redis-cli info]
    if File.exist? 'data.json'
      @data = JSON.parse(File.read('data.json'))
    else
      @data = []
    end
  end
  def match noun
    @stats.match(/keyspace_#{noun}:([0-9]+)/)[1].to_i
  end
  def hits
    match 'hits'
  end
  def misses
    match 'misses'
  end
  def rate
    hits.to_f / (hits.to_f + misses.to_f)
  end
  def log
    @data << {
      hitrate: rate,
      ts: Time.now.to_i
    }
    File.write('data.json', JSON.pretty_generate(@data))
  end
end

RedisPerf.new.log