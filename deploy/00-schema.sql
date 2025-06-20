CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    parent_id INTEGER REFERENCES categories(category_id),
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE brands (
    brand_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    country VARCHAR(100),
    delivery_countries TEXT,
    website VARCHAR(255),
    logo_url VARCHAR(255),
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE colors (
    color_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    hex_code VARCHAR(7),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE materials (
    material_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE styles (
    style_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE locks (
    lock_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT
);

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    manufacturer_sku VARCHAR(100),
    description TEXT,
    brand_id INTEGER REFERENCES brands(brand_id),
    category_id INTEGER REFERENCES categories(category_id),
    style_id INTEGER REFERENCES styles(style_id),
    main_color_id INTEGER REFERENCES colors(color_id),
    main_material_id INTEGER REFERENCES materials(material_id),
    manufacturer_url VARCHAR(255),
    model_3d_url VARCHAR(255),
    images_folder_url VARCHAR(255),
    dimensions VARCHAR(100),
    price DECIMAL(10, 2),
    currency VARCHAR(3) DEFAULT 'RUB',
    in_stock BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE product_doors (
    product_id INTEGER PRIMARY KEY REFERENCES products(product_id) ON DELETE CASCADE,
    door_type VARCHAR(100),
    opening_direction VARCHAR(50),
    opening_mechanism VARCHAR(100)
);

CREATE TABLE product_windows (
    product_id INTEGER PRIMARY KEY REFERENCES products(product_id) ON DELETE CASCADE
);

CREATE TABLE product_furniture (
    product_id INTEGER PRIMARY KEY REFERENCES products(product_id) ON DELETE CASCADE,
    room_name VARCHAR(100),
    furniture_subtype VARCHAR(100)
);

CREATE TABLE product_appliances (
    product_id INTEGER PRIMARY KEY REFERENCES products(product_id) ON DELETE CASCADE,
    room_name VARCHAR(100),
    requires_power BOOLEAN
);

CREATE TABLE product_decor (
    product_id INTEGER PRIMARY KEY REFERENCES products(product_id) ON DELETE CASCADE,
    placement VARCHAR(100),
    requires_power BOOLEAN
);

CREATE TABLE product_plumbing (
    product_id INTEGER PRIMARY KEY REFERENCES products(product_id) ON DELETE CASCADE,
    room_name VARCHAR(100),
    placement VARCHAR(100),
    requires_power BOOLEAN,
    requires_water BOOLEAN
);

CREATE TABLE product_surface_materials (
    product_id INTEGER PRIMARY KEY REFERENCES products(product_id) ON DELETE CASCADE,
    room_name VARCHAR(100),
    warm_floor_compatible BOOLEAN,
    sales_unit VARCHAR(50)
);

CREATE TABLE product_switches (
    product_id INTEGER PRIMARY KEY REFERENCES products(product_id) ON DELETE CASCADE,
    switch_type VARCHAR(100),
    sections_count INTEGER,
    switch_subtype VARCHAR(100)
);

CREATE TABLE product_sockets (
    product_id INTEGER PRIMARY KEY REFERENCES products(product_id) ON DELETE CASCADE,
    wifi_support BOOLEAN,
    socket_type VARCHAR(100),
    plugs_count INTEGER,
    plug_type VARCHAR(100)
);

CREATE TABLE product_lighting (
    product_id INTEGER PRIMARY KEY REFERENCES products(product_id) ON DELETE CASCADE,
    rgb_control BOOLEAN,
    luminous_flux_lm INTEGER,
    color_temperature_k INTEGER,
    voltage_v VARCHAR(50),
    max_wattage_per_bulb_w INTEGER,
    number_of_bulbs INTEGER,
    socket_type VARCHAR(50),
    light_source_type VARCHAR(100)
);

CREATE TABLE product_textures (
    texture_id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    preview_image_url VARCHAR(255),
    texture_file_url VARCHAR(255) NOT NULL,
    texture_color_id INTEGER REFERENCES colors(color_id),
    texture_material_id INTEGER REFERENCES materials(material_id),
    is_default BOOLEAN DEFAULT FALSE
);

CREATE TABLE door_available_locks (
    door_product_id INTEGER NOT NULL REFERENCES product_doors(product_id) ON DELETE CASCADE,
    lock_id INTEGER NOT NULL REFERENCES locks(lock_id) ON DELETE CASCADE,
    PRIMARY KEY (door_product_id, lock_id)
);

CREATE TABLE user_saved_filters (
    filter_id SERIAL PRIMARY KEY,
    user_id INTEGER,
    name VARCHAR(100) NOT NULL,
    filters JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_products_filter ON products(category_id, price, is_active);
CREATE INDEX idx_product_textures_product_id ON product_textures(product_id);

CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_products_timestamp
BEFORE UPDATE ON products
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trg_brands_timestamp
BEFORE UPDATE ON brands
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trg_categories_timestamp
BEFORE UPDATE ON categories
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trg_colors_timestamp
BEFORE UPDATE ON colors
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trg_materials_timestamp
BEFORE UPDATE ON materials
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trg_styles_timestamp
BEFORE UPDATE ON styles
FOR EACH ROW EXECUTE FUNCTION update_timestamp();