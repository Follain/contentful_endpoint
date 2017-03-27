require 'contentful'
require 'contentful/management'
require 'slugify'

class ContentfulClient
  def add_product(payload)
    brand = payload[:product][:taxons].index_by(&:first)['Brand'].try(:last)
    sku = payload[:product][:sku]
    permalink = payload[:product][:permalink]
    name = [brand, payload[:product][:name]].join(' / ')

    existing = display_client.entries(content_type: 'product', 'fields.sku' => sku).first
    if existing.present?
      product = space.entries.find(existing.id)
      product.name = name
      product.brand = brand
      product.permalink = permalink
      product.save
    else
      product = create(
        :product,
        locale: 'en-US',
        sku: sku,
        permalink: permalink,
        name: name, brand: brand
      )
    end

    product.publish

    product
  end

  def permalink_field
    Contentful::Management::Field.new.tap do |field|
      field.id = 'permalink'
      field.localized = false
      field.name = 'Permalink'
      field.type = 'Symbol'
      field.required = true
    end
  end

  def name_field
    Contentful::Management::Field.new.tap do |field|
      field.id = 'name'
      field.localized = false
      field.name = 'Name'
      field.type = 'Symbol'
      field.required = true
    end
  end

  def solidus_id_field
    Contentful::Management::Field.new.tap do |field|
      field.id = 'solidusId'
      field.localized = false
      field.name = 'Solidus ID'
      field.type = 'Integer'
      field.required = true
    end
  end

  def content_type(name)
    id = name.gsub(' ', '_').camelize(:lower)

    content_type = space.content_types.find(id)
    return content_type if content_type.kind_of?(Contentful::Management::ContentType)

    space.content_types
      .create(name: name, id: id, fields: [name_field, permalink_field, solidus_id_field])
      .tap(&:publish)
  end

  def add_taxon(payload)
    permalink = payload[:taxon][:permalink]
    name = payload[:taxon][:name]
    taxonomy_name = payload[:taxon][:taxonomy_name]
    solidus_id = payload[:taxon][:id]

    content_type = self.content_type(taxonomy_name)

    existing = display_client.entries(content_type: content_type.id, 'fields.solidusId' => solidus_id).first

    taxon = if existing.present?
      space.entries.find(existing.id).tap do |taxon|
        taxon.permalink = permalink
        taxon.name = name
        taxon.save
      end
    else
      create(
        content_type.id,
        locale: 'en-US',
        solidusId: solidus_id,
        name: name,
        permalink: permalink
      )
    end

    taxon.tap(&:publish)
  end

  def create(content_type_id, attributes)
    space.content_types.find(content_type_id.to_s).entries.create attributes
  end

  def display_client
    @display_client ||= ::Contentful::Client.new(
      access_token: ENV.fetch('CONTENTFUL_DELIVERY_TOKEN'),
      space: ENV.fetch('CONTENTFUL_SPACE_ID')
    )
  end

  def management_client
    @management_client ||= ::Contentful::Management::Client.new(
      ENV.fetch('CONTENTFUL_MANAGEMENT_TOKEN')
    )
  end

  def space
    @space ||= management_client.spaces.find(ENV.fetch('CONTENTFUL_SPACE_ID'))
  end
end
