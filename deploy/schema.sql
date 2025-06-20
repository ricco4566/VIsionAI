CREATE TABLE product_types (
    product_type_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT
);

CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    parent_id INTEGER REFERENCES categories(category_id),
    description TEXT
);

CREATE TABLE brands (
    brand_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    logo_url VARCHAR(255)
);

CREATE TABLE colors (
    color_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    hex_code VARCHAR(7),
    description TEXT
);

CREATE TABLE materials (
    material_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT
);

CREATE TABLE styles (
    style_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT
);

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    brand_id INTEGER REFERENCES brands(brand_id),
    manufacturer_sku VARCHAR(100),
    description TEXT,
    manufacturer_url VARCHAR(255),
    model_3d_url VARCHAR(255),
    images_folder_url VARCHAR(255),
    dimensions VARCHAR(100),
    main_color_id INTEGER REFERENCES colors(color_id),
    main_material_id INTEGER REFERENCES materials(material_id),
    category_id INTEGER REFERENCES categories(category_id),
    style_id INTEGER REFERENCES styles(style_id),
    price DECIMAL(10, 2),
    currency VARCHAR(3) DEFAULT 'RUB',
    in_stock BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    product_type_id INTEGER REFERENCES product_types(product_type_id),
    search_vector TSVECTOR
);

CREATE TABLE doors (
    door_id SERIAL PRIMARY KEY,
    product_id INTEGER UNIQUE REFERENCES products(product_id),
    room_type VARCHAR(100),
    material VARCHAR(100),
    opening_type VARCHAR(50)
);

CREATE TABLE curtains (
    curtain_id SERIAL PRIMARY KEY,
    product_id INTEGER UNIQUE REFERENCES products(product_id),
    length DECIMAL(6, 2),
    width DECIMAL(6, 2),
    curtain_type VARCHAR(50)
);

CREATE TABLE textures (
    texture_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    texture_file_url VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE product_textures (
    product_texture_id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    texture_id INTEGER NOT NULL REFERENCES textures(texture_id) ON DELETE CASCADE,
    application_area VARCHAR(100),
    is_default BOOLEAN DEFAULT FALSE,
    UNIQUE (product_id, texture_id, application_area)
);

CREATE TABLE user_saved_filters (
    filter_id SERIAL PRIMARY KEY,
    user_id INTEGER,
    name VARCHAR(100) NOT NULL,
    filters JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_products_filter ON products(category_id, price, is_active);
CREATE INDEX idx_doors_room ON doors(room_type) INCLUDE (product_id);
CREATE INDEX idx_product_textures_product_id ON product_textures(product_id);
CREATE INDEX idx_products_search ON products USING GIN(search_vector);

CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_search_vector()
RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector = 
        to_tsvector('english', NEW.name) ||
        to_tsvector('english', COALESCE(NEW.description, ''));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_timestamp
BEFORE UPDATE ON products
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trg_search
BEFORE INSERT OR UPDATE ON products
FOR EACH ROW EXECUTE FUNCTION update_search_vector();