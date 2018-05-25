require "multi_model_paginator/version"

module MultiModelPaginator
  class QueryStruct
    attr_reader :query

    def initialize(query, select, count)
      @query = query
      @select = select
      @count = count
    end

    def with_select
      @query.select(@select)
    end

    def count
      @cached_count ||=
        begin
          if @count.nil?
            @query.count
          else
            @count.call
          end
        end
    end
  end

  class Builder
    def initialize(per, page)
      @query_list = []
      @per = per
      @page = page
      @list = []
    end

    def add(query, select: nil, count: nil)
      @query_list.push(QueryStruct.new(query, select, count))
    end

    def result
      remain = @per
      offset = (@page * @per)
      @query_list.reduce([]) do |accumulator, query|
        prev_total_count = @query_list.reduce(0) { |a, q| q == query ? (break(a)) : (a =+ q.count) }
        if (prev_total_count..(prev_total_count + query.count)).include?(offset)
          local_page = @page - (prev_total_count / @per) + 1
        else
          next(accumulator)
        end
        list = query.with_select.page(local_page).per(@per).first(remain)
        accumulator.concat(list)
        remain = remain - list.size
        if remain == 0
          break(accumulator)
        else
          next(accumulator)
        end
      end
    end
  end

  def self.new(per: , page: )
    Builder.new(per, page)
  end
end
