module Plucky
  class Pipeline
    attr_accessor :pipeline, :model
    
    def initialize(model)
      @model = model
      @pipeline = []
    end
    
    %w(project match limit skip unwind group sort).each do |operator|
      define_method operator do |hash|
        _pipeline operator, hash
      end
    end
    
    def first
      limit(1)._aggregate
    end
    
    def last
      @pipeline.each do |command|
        next unless command[:$sort]
        command[:$sort] = command[:$sort].map do |s|
          [s[0], -s[1]]
        end unless command[:$sort].nil?
        
        command[:$sort] = Hash[*command[:$sort].flatten]
      end
      
      first
    end
    
    def _aggregate
      model.collection.aggregate @pipeline
    end
    
    alias_method :all, :_aggregate
    
    def _pipeline(operator, hash)
      @pipeline << { :"$#{ operator }" => hash }
      self
    end
  end
end
