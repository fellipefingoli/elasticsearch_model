require "elasticsearch"

class ElasticsearchModel
	
	attr_reader :client, :custom_index, :model

	def initialize index_name, model = nil
		@index_name = index_name
		config = YAML.load(File.read(Rails.root+"config/elasticsearch.yml"))[Rails.env]
		@client = Elasticsearch::Client.new host: config["host"]+":"+config["port"].to_s, request_timeout: config["request_timeout"]
    	custom_name = "lti_"+index_name
    	@model = model
    	@custom_index = {
			name:  custom_name,
			write: custom_name+"_write",
			read:  custom_name+"_read"
		}
	end

	def import_to_elastic data
	    @client.bulk body: [create_body(symbolize_keys_deep!( denormalize(data.id) ))]
	end

	def import_all_to_elastic
		create_index
	    @client.bulk body: denormalize.map{|value| create_body symbolize_keys_deep!(value)}
	    delete_index
	end

	def create_index
		current_index = @custom_index[:name]+"_"+Time.now.to_i.to_s
		@client.indices.create index(current_index)

		begin 
			@client.indices.get_alias(name: @custom_index[:write]).each do |index,aliases|
				@client.indices.delete_alias index: index, name: @custom_index[:write]
			end	
		rescue
			puts "Erro ao excluir alias do indice atual de escrita"
		end
		@client.indices.put_alias index: current_index, name: @custom_index[:write]
    end

    def delete_index
    	begin
	    	@client.indices.get_alias(name: @custom_index[:read]).each do |index,aliases|
				@client.indices.delete index: index
			end
		rescue
			puts "Erro ao excluir alias do indice atual de leitura"
		end

		@client.indices.get_alias(name: @custom_index[:write]).each do |index,aliases|
			@client.indices.put_alias index: index, name: @custom_index[:read]
		end
    end

    def search *args
    	body = {}
    	args.each do |arg| body.merge! arg end
      @client.search(index: @custom_index[:read], body: body)["hits"]
    end

    private

    def index index_name
    	obj = {}
    	obj[:index] = index_name
    	obj[:body] = mapping unless mapping.nil?
    	return obj
    end

	def create_body value
    	{index: {_index: @custom_index[:write], _type: @custom_index[:name] , _id: value[:id], data: value }}
    end

    def mapping
    	begin    		
    		mapping = File.read Rails.root.to_s+"/config/elasticsearch/mappings/"+@index_name+".json"
    	rescue
    		return nil
    	end
    	symbolize_keys_deep! JSON.parse(mapping)
    end
	
	def denormalize id = nil
		id.nil? ? @model.all : @model.find(id)
	end

	def symbolize_keys_deep! hash
	    hash.keys.each do |key|
	        key_s    = key.to_sym
	        hash[key_s] = hash.delete key
	        symbolize_keys_deep! hash[key_s] if hash[key_s].kind_of? Hash
	    end
	    hash
	end
end
