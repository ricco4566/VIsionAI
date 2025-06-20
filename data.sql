INSERT INTO materials (name, description) VALUES 
('Массив дуба', 'Натуральный массив дуба, прочный и долговечный'),
('Стекло закаленное', 'Ударопрочное закаленное стекло толщиной 8мм'),
('Сталь', 'Легированная сталь с порошковым покрытием')
ON CONFLICT (name) DO NOTHING;

INSERT INTO styles (name, description) VALUES 
('Классический', 'Традиционный дизайн с элементами фрезеровки'),
('Хай-тек', 'Современный минималистичный стиль'),
('Лофт', 'Индустриальный стиль с грубыми текстурами')
ON CONFLICT (name) DO NOTHING;

INSERT INTO categories (name, description) VALUES
('Межкомнатные двери', 'Двери для установки внутри помещений'),
('Входные двери', 'Двери для установки на входе в здание')
ON CONFLICT (name) DO NOTHING;

INSERT INTO products (name, description, category_id, style_id, main_material_id, price, is_active)
VALUES (
    'Дверь "Версаль"',
    'Элегантная дверь из массива дуба в классическом стиле. Идеально для гостиной.',
    (SELECT category_id FROM categories WHERE name = 'Межкомнатные двери'),
    (SELECT style_id FROM styles WHERE name = 'Классический'),
    (SELECT material_id FROM materials WHERE name = 'Массив дуба'),
    35000.00,
    TRUE
);

INSERT INTO doors (product_id, room_type, material, opening_type)
VALUES (
    (SELECT product_id FROM products WHERE name = 'Дверь "Версаль"'),
    'Гостиная',
    'Массив дуба',
    'Распашная'
);

INSERT INTO products (name, description, category_id, style_id, main_material_id, price, is_active)
VALUES (
    'Дверь "Гласс-Про"',
    'Стильная дверь из закаленного матового стекла. Подходит для современных офисов и переговорных.',
    (SELECT category_id FROM categories WHERE name = 'Межкомнатные двери'),
    (SELECT style_id FROM styles WHERE name = 'Хай-тек'),
    (SELECT material_id FROM materials WHERE name = 'Стекло закаленное'),
    28000.00,
    TRUE
);

INSERT INTO doors (product_id, room_type, material, opening_type)
VALUES (
    (SELECT product_id FROM products WHERE name = 'Дверь "Гласс-Про"'),
    'Офис',
    'Стекло',
    'Маятниковая'
);

INSERT INTO products (name, description, category_id, style_id, main_material_id, price, is_active)
VALUES (
    'Дверь "Форт-Нокс"',
    'Взломостойкая входная дверь из легированной стали с отделкой в стиле лофт.',
    (SELECT category_id FROM categories WHERE name = 'Входные двери'),
    (SELECT style_id FROM styles WHERE name = 'Лофт'),
    (SELECT material_id FROM materials WHERE name = 'Сталь'),
    52000.00,
    TRUE
);

INSERT INTO doors (product_id, room_type, material, opening_type)
VALUES (
    (SELECT product_id FROM products WHERE name = 'Дверь "Форт-Нокс"'),
    'Входная',
    'Сталь',
    'Распашная'
);