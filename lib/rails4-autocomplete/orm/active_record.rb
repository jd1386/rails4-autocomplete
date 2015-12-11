module Rails4Autocomplete
  module Orm
    module ActiveRecord
      def get_autocomplete_order(method, options, model=nil)
        order = options[:order]

        table_prefix = model ? "#{ options[:table_name] ||= model.table_name}." : ""
        order || "#{table_prefix}#{method} ASC"
      end

      def get_autocomplete_items(parameters)
        model   = parameters[:model]
        table_name = parameters[:table_name]
        term    = parameters[:term]
        method  = parameters[:method]
        options = parameters[:options]
        scopes  = Array(options[:scopes])
        where   = options[:where]
        limit   = get_autocomplete_limit(options)
        order   = get_autocomplete_order(method, options, model)

        items = model.all

        scopes.each { |scope| items = items.send(scope) } unless scopes.empty?

        items = items.select(get_autocomplete_select_clause(model, method, options)) unless options[:full_model]
        items = items.where(get_autocomplete_where_clause(model, term, method, options)).
            limit(limit).order(order)
        items = items.where(where) unless where.blank?

        items.to_a
      end

      def get_autocomplete_select_clause(model, method, options)
        table_name = model.table_name
        (["#{table_name}.#{model.primary_key}", "#{options[:table_name]}.#{method}"] + (options[:extra_data].blank? ? [] : options[:extra_data]))
      end

      def get_autocomplete_where_clause(model, term, method, options)
        table_name = model.table_name
        term = term.gsub(/([_%\\])/, '\\\\\1')
        is_full_search = options[:full]
        ["unaccent(#{options[:table_name]}.#{method}) ilike unaccent(?)", "#{(is_full_search ? '%' : '')}#{term.downcase}%"]
      end

    end
  end
end
