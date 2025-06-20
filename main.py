import asyncpg
import os
from typing import List, Optional, Any, Dict

from fastapi import FastAPI, Depends, HTTPException
from pydantic import BaseModel

app = FastAPI(
    title="Интерьерный Каталог API",
    description="API для получения информации о товарах для интерьера.",
    version="1.0.0"
)

DB_CONFIG = {
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", "postgres"),
    "database": os.getenv("DB_NAME", "interior_db"),
    "host": os.getenv("DB_HOST", "db"),
}

class TextureInfo(BaseModel):
    texture_id: int
    name: str
    preview_image_url: Optional[str]
    texture_file_url: str
    is_default: Optional[bool]

class Product(BaseModel):
    product_id: int
    name: str
    description: Optional[str]
    price: Optional[float]
    brand_name: Optional[str]
    style_name: Optional[str]
    category_name: Optional[str]
    specific_attributes: Dict[str, Any]
    textures: List[TextureInfo]

class SavedFilter(BaseModel):
    name: str
    filters: dict

@app.on_event("startup")
async def startup():
    try:
        app.state.pool = await asyncpg.create_pool(
            user=DB_CONFIG["user"],
            password=DB_CONFIG["password"],
            database=DB_CONFIG["database"],
            host=DB_CONFIG["host"],
        )
    except Exception as e:
        raise RuntimeError(f"Не удалось подключиться к базе данных: {e}")

@app.on_event("shutdown")
async def shutdown():
    if hasattr(app.state, "pool"):
        await app.state.pool.close()

async def get_connection():
    async with app.state.pool.acquire() as connection:
        yield connection

@app.get("/products/", response_model=List[Product])
async def get_products_by_category(
    category_name: str,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    style: Optional[str] = None,
    brand: Optional[str] = None,
    conn: asyncpg.Connection = Depends(get_connection)
):
    category_table_map = {
        'Двери': 'product_doors',
        'Окна': 'product_windows',
        'Мебель': 'product_furniture',
        'Бытовая техника': 'product_appliances',
        'Предметы декора': 'product_decor',
        'Сантехника': 'product_plumbing',
        'Материалы на стены': 'product_surface_materials',
        'Электрика - выключатели': 'product_switches',
        'Электрика - розетки': 'product_sockets',
        'Электрика - освещение': 'product_lighting',
    }
    
    specific_table = category_table_map.get(category_name)
    if not specific_table:
        raise HTTPException(status_code=404, detail="Категория не найдена или для нее не задана таблица атрибутов")

    query = f"""
        SELECT
            p.product_id,
            p.name,
            p.description,
            p.price,
            b.name as brand_name,
            s.name as style_name,
            c.name as category_name,
            row_to_json(spec.*) as specific_attributes,
            COALESCE(
                (SELECT jsonb_agg(jsonb_build_object(
                    'texture_id', t.texture_id,
                    'name', t.name,
                    'preview_image_url', t.preview_image_url,
                    'texture_file_url', t.texture_file_url,
                    'is_default', t.is_default
                ))
                FROM product_textures t
                WHERE t.product_id = p.product_id),
                '[]'::jsonb
            ) as textures
        FROM products p
        JOIN categories c ON p.category_id = c.category_id
        LEFT JOIN brands b ON p.brand_id = b.brand_id
        LEFT JOIN styles s ON p.style_id = s.style_id
        JOIN {specific_table} spec ON p.product_id = spec.product_id
    """

    conditions = ["c.name = $1", "p.is_active = TRUE"]
    params: List[Any] = [category_name]

    if min_price is not None:
        params.append(min_price)
        conditions.append(f"p.price >= ${len(params)}")
    if max_price is not None:
        params.append(max_price)
        conditions.append(f"p.price <= ${len(params)}")
    if style:
        params.append(style)
        conditions.append(f"s.name = ${len(params)}")
    if brand:
        params.append(brand)
        conditions.append(f"b.name = ${len(params)}")

    query += " WHERE " + " AND ".join(conditions)

    return await conn.fetch(query, *params)


@app.post("/filters/", status_code=201)
async def save_filter(
    filter_data: SavedFilter,
    user_id: Optional[int] = None,
    conn: asyncpg.Connection = Depends(get_connection)
):
    if not user_id:
        raise HTTPException(status_code=401, detail="User ID is required to save filters")

    await conn.execute(
        "INSERT INTO user_saved_filters (user_id, name, filters) VALUES ($1, $2, $3)",
        user_id, filter_data.name, filter_data.filters
    )
    return {"status": "saved", "filter_name": filter_data.name}