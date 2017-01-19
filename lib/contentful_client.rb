class ContentfulClient
  def add_product(payload)
    brand = payload[:product][:taxons].index_by(&:first)["Brand"].try(:last)
    sku = payload[:product][:sku]
    name = [brand, payload[:product][:name]].join(' / ')

    existing = display_client.entries(content_type: 'product', 'fields.sku' => sku).first
    if existing.present?
      product = space.entries.find(existing.id)
      product.name = name
      product.brand = brand
      product.save
    else
      product = create(
        :product,
        locale: 'en-US',
        sku: sku,
        name: name, brand: brand
      )
    end

    product.publish

    product
  end

  private

  def create(content_type_id, attributes)
    space.content_types.find(content_type_id.to_s).entries.create attributes
  end

  def display_client
    @display_client ||= Contentful::Client.new(
      access_token: ENV.fetch('CONTENTFUL_DELIVERY_TOKEN'),
      space: ENV.fetch('CONTENTFUL_SPACE_ID')
    )
  end

  def management_client
    @management_client ||= Contentful::Management::Client.new(
      ENV.fetch('CONTENTFUL_MANAGEMENT_TOKEN')
    )
  end

  def space
    @space ||= management_client.spaces.find(ENV.fetch('CONTENTFUL_SPACE_ID'))
  end
end
