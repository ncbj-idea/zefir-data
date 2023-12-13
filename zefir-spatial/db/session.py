from sqlalchemy import create_engine
from sqlalchemy.engine.url import URL
from sqlalchemy.orm import sessionmaker

from config import settings

SQLALCHEMY_URL = str(
    URL.create(
        drivername="postgresql",
        username=settings.POSTGRES_USER,
        password=settings.POSTGRES_PASSWORD,
        host=settings.POSTGRES_HOST_ADDRESS,
        port=settings.POSTGRES_HOST_PORT,
        database=settings.POSTGRES_DB,
    )
)
engine = create_engine(SQLALCHEMY_URL, echo=False, pool_pre_ping=True)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
