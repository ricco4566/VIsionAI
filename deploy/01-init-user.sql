-- Создаем нового пользователя с паролем.
-- В реальном проекте пароль должен быть более сложным и управляться через секреты.
CREATE USER app_user WITH PASSWORD 'app_password';

-- Даем пользователю право подключаться к нашей базе данных.
GRANT CONNECT ON DATABASE interior_db TO app_user;

-- Даем пользователю права на использование схемы 'public'.
GRANT USAGE ON SCHEMA public TO app_user;

-- Даем права на все таблицы в схеме 'public'.
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;

-- Даем права на использование всех последовательностей (для автоинкрементных ID).
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user; 