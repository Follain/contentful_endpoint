
require 'sinatra'
require 'endpoint_base'

Dir[File.dirname(__FILE__) + '/lib/**/*.rb'].each { |f| require f }

class ContentfulEndpoint < EndpointBase::Sinatra::Base
  set :logging, true
  attr_reader :payload

  def contentful_client
    Thread.current[:contentful_client] ||= ::ContentfulClient.new
  end

  post '/add_product' do
    begin
      product = contentful_client.add_product(payload)
      message  = "added product #{product.name}"

      add_value 'products', [{ channel: 'Contentful', sku: product.sku, id: product.id, name: product.name }]
      code     = 200
    rescue => e
      message  = e.message
      code     = 500
    end

    result code, message
  end
end
