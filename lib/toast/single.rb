module Toast

  # A Single resource is queried without an ID, by custom class methods
  # or scopes of the model or ActiveRecord single finders like:
  # first, last

  # The single resource name must be a class method of the model and
  # must return nil or an instance.

  # GET is the only allowed verb. To make changes the URI with ID has
  # to be used.
  class Single < Resource

    attr_reader :model

    def initialize model, subresource_name, params, config_in, config_out
      @config_in = config_in
      @config_out = config_out

      unless @config_out.singles.include? subresource_name
        raise ResourceNotFound
      end

      @model = model
      @params = params
      @format = params[:format]

      unless @model.respond_to?(subresource_name)
        raise "Toast Error: Cannot find class method '#{@model}.#{subresource_name}', which is configured in 'acts_as_resource > singles'."
      end

      @record = if @config_out.pass_params_to.include?(subresource_name)
                  if @model.method(subresource_name).arity != 1
                    raise "Toast Error: Class method '#{@model}.#{subresource_name}' must accept one parameter, as configured by 'acts_as_resource > pass_params_to'."
                  end
                  @model.send(subresource_name, @params)
                else
                  if(@model.method(subresource_name).arity < -1 or 
                     @model.method(subresource_name).arity > 0)
                    raise "Toast Error: Class method '#{@model}.#{subresource_name}' must be callable w/o parameters"
                  end
                  @model.send(subresource_name)
                end
      
      raise ResourceNotFound if @record.nil?      
    end

    def get
      case @format
      when "html"
        {
          :template => "resources/#{model.to_s.underscore}",
          :locals => { model.to_s.pluralize.underscore.to_sym => @record }
        }
      when "json"
        {
          :json => @record.represent( @config_out.exposed_attributes,
                                      @config_out.exposed_associations,
                                      @base_uri,
                                      @config_out.media_type),
          :status => :ok
        }
      else
        raise ResourceNotFound
      end
    end


    def put
      raise MethodNotAllowed
    end

    def post payload
      raise MethodNotAllowed
    end

    def delete
      raise MethodNotAllowed
    end

    def link l
      raise MethodNotAllowed
    end

    def unlink l
      raise MethodNotAllowed
    end
  end
end
