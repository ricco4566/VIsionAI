import asyncpg
import os
from typing import List, Optional

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
    texture_file_url: str
    application_area: Optional[str] = None

class ProductDetail(BaseModel):
    product_id: int
    name: str
    price: Optional[float] = None
    description: Optional[str] = None
    category: Optional[str] = None
    style: Optional[str] = None
    brand: Optional[str] = None
    material: Optional[str] = None
    room_type: Optional[str] = None
    textures: List[TextureInfo] = []

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
            min_size=1, 
            max_size=10
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


@app.get("/doors/", response_model=List[ProductDetail], summary="Получить список дверей")
async def get_doors(
    room_type: Optional[str] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    style: Optional[str] = None,
    material: Optional[str] = None,
    brand: Optional[str] = None,
    conn: asyncpg.Connection = Depends(get_connection)
):
    base_query = """
        SELECT
            p.product_id, p.name, p.price, p.description,
            cat.name as category,
            sty.name as style,
            b.name as brand,
            d.material, d.room_type,
            COALESCE(
                (SELECT jsonb_agg(jsonb_build_object(
                    'texture_id', t.texture_id,
                    'name', t.name,
                    'texture_file_url', t.texture_file_url,
                    'application_area', pt.application_area
                ))
                FROM product_textures pt
                JOIN textures t ON pt.texture_id = t.texture_id
                WHERE pt.product_id = p.product_id),
                '[]'::jsonb
            ) as textures
        FROM products p
        JOIN doors d ON p.product_id = d.product_id
        LEFT JOIN categories cat ON p.category_id = cat.category_id
        LEFT JOIN styles sty ON p.style_id = sty.style_id
        LEFT JOIN brands b ON p.brand_id = b.brand_id
    """
    
    conditions = ["p.is_active = TRUE"]
    params = []
    
    if room_type:
        params.append(f"%{room_type}%")
        conditions.append(f"d.room_type ILIKE ${len(params)}")
        
    if style:
        params.append(f"%{style}%")
        conditions.append(f"sty.name ILIKE ${len(params)}")

    if material:
        params.append(f"%{material}%")
        conditions.append(f"d.material ILIKE ${len(params)}")

    if brand:
        params.append(f"%{brand}%")
        conditions.append(f"b.name ILIKE ${len(params)}")

    if min_price is not None:
        params.append(min_price)
        conditions.append(f"p.price >= ${len(params)}")
        
    if max_price is not None:
        params.append(max_price)
        conditions.append(f"p.price <= ${len(params)}")
        
    query = base_query + " WHERE " + " AND ".join(conditions)
        
    return await conn.fetch(query, *params)


@app.post("/filters/", status_code=201, summary="Сохранить пользовательский фильтр")
async def save_filter(
    filter_data: SavedFilter,
    user_id: Optional[int] = None,
    conn: asyncpg.Connection = Depends(get_connection)
):
    if user_id:
        await conn.execute(
            "INSERT INTO user_saved_filters (user_id, name, filters) VALUES ($1, $2, $3)",
            user_id, filter_data.name, filter_data.filters
        )
        return {"status": "saved", "filter_name": filter_data.name}
    
    raise HTTPException(status_code=401, detail="User ID is required to save filters")