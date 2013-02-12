require 'plucky/query'
require 'plucky/pipeline'

module Plucky
  class Query
    %w(project match unwind group).each do |operator|
      define_method operator do |hash|
        Pipeline.new(model).match(criteria.source).tap do |pipeline|
          pipeline.project(options[:fields]) if options.has_key?(:fields)
          pipeline.sort(Hash[*options[:sort].flatten]) if options.has_key?(:sort)
          pipeline.skip(options[:skip]) if options.has_key?(:skip)
          pipeline.limit(options[:limit]) if options.has_key?(:limit)
          pipeline.send operator, hash
        end
      end
    end
  end
end