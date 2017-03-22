
require 'sinatra'
require 'endpoint_base'

Dir[File.dirname(__FILE__) + '/**/*.rb'].each { |f| require f }

class ContentfulEndpoint < EndpointBase::Sinatra::Base
  set :logging, true
  attr_reader :payload

  def contentful_client
    @contentful_client ||= ::ContentfulClient.new
  end

  post '/add_product' do
    begin
      product = contentful_client.add_product(payload)
      message  = "added product #{product.name}"

      add_value 'products', [
        {
          channel: 'Contentful',
          sku: product.sku,
          permalink: product.permalink,
          id: product.id,
          name: product.name
        }
      ]
      code     = 200
    rescue => e
      message  = e.message
      code     = 500
    end

    result code, message
  end

  post '/add_taxon' do
    begin
      taxon = contentful_client.add_taxon(payload)
      message  = "added taxon #{taxon.name}"
      add_value(
        'taxons',
        [
          {
            id: taxon.id,
            channel: 'Contentful',
            name: taxon.name,
            solidus_id: taxon.solidus_id,
            permalink: taxon.permalink,
            content_type_id: taxon.sys[:contentType].id
          }
        ]
      )

      code     = 200
    rescue => e
      message  = e.message
      code     = 500
    end

    result code, message
  end
end
