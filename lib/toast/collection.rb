module Toast
  class Collection < Resource

    attr_reader :model

    def initialize model_or_relation, subresource_name, params, config_in, config_out

      subresource_name ||= "all"

      unless config_out.collections.include? subresource_name
        raise ResourceNotFound
      end

      @target_model = (model_or_relation.klass rescue false) ? 
                       model_or_relation.klass :
                       model_or_relation
 
      @model_or_relation = model_or_relation
      @collection = subresource_name
      @params = params
      @format = params[:format]
      @config_out = config_out
      @config_in = config_in
    end

    def get

      unless @model_or_relation.respond_to?(@collection)
        raise "Toast Error: Cannot find class method '#{@collection}' of model '#{@model_or_relation}', which is configured in 'acts_as_resource > collections'."
      end
      
      # FIXME: This is a lot of hallooballoo to check if the #send
      #        will be successful, but if it's not checked the error
      #        message is not helpful to find the error.

      records = if @config_out.pass_params_to.include?(@collection)                                  
                  if @target_model.method(@collection).arity != 1  
                    raise "Toast Error: Class method '#{@collection}' of model '#{@target_model}' must accept one parameter, as configured by 'acts_as_resource > pass_params_to'."
                  end
                  # fetch results 
                  @model_or_relation.send(@collection, @params)

                else

                  if @target_model.method(@collection).arity > 0
                    raise "Toast Error: Class method '#{@collection}' of model '#{@model_or_relation}' must not accept any parameter, as configured by 'acts_as_resource'"
                  end
                  # fetch results
                  @model_or_relation.send(@collection)
                end

      case @format
      when "html"
        {
          :template => "resources/#{@target_model.to_s.pluralize.underscore}",
          :locals => { @target_model.to_s.pluralize.underscore.to_sym => records }
        }
      when "json"
        {
          :json => records.map{|r|
            r.represent( @config_out.in_collection.exposed_attributes,
                         @config_out.in_collection.exposed_associations,
                         self.base_uri,
                         @config_out.media_type)
          },
          :status => :ok,
          :content_type => @config_out.in_collection.media_type
        }
      else
        raise ResourceNotFound
      end
    end

    def put
      raise MethodNotAllowed
    end

    def post payload, media_type
      raise MethodNotAllowed unless @config_in.postable?

      if media_type != @config_in.media_type
        raise UnsupportedMediaType
      end

      if @collection != "all"
        raise MethodNotAllowed
      end

      begin
        payload = ActiveSupport::JSON.decode(payload)
      rescue
        raise PayloadFormatError
      end
      unless payload.is_a? Hash
        raise PayloadFormatError
      end

      # silently ignore all exposed readable, but not writable fields
      (@config_in.readables - @config_in.writables + ["self"]).each do |rof|
        payload.delete(rof)
      end

      begin
        record = @model_or_relation.create! payload

        {
          :json => record.represent( @config_out.exposed_attributes,
                                     @config_out.exposed_associations,
                                     self.base_uri,
                                     @config_out.media_type),
          :location => self.base_uri + record.uri_path,
          :status => :created,
          :content_type => @config_out.media_type
        }

      rescue ActiveRecord::RecordInvalid => e
        # model validation failed
        raise PayloadInvalid.new(e.message)
      end
    end

    def delete
      raise MethodNotAllowed
    end
  end
end