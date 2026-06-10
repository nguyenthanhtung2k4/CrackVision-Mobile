from sqlalchemy import create_engine, event
from sqlalchemy.orm import DeclarativeBase, sessionmaker, Session
from typing import Generator
from app.core.config import settings


# SQLite cần pragma foreign_keys để CASCADE hoạt động
def _set_sqlite_pragma(dbapi_conn, _):
    cursor = dbapi_conn.cursor()
    cursor.execute("PRAGMA foreign_keys=ON")
    cursor.close()


def _build_engine():
    if settings.is_sqlite:
        engine = create_engine(
            settings.database_url,
            connect_args={"check_same_thread": False},
        )
        event.listen(engine, "connect", _set_sqlite_pragma)
    else:
        engine = create_engine(settings.database_url, pool_pre_ping=True)
    return engine


engine = _build_engine()

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    pass


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
