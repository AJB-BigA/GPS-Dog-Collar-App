from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from sqlalchemy import create_engine, Column, Integer, String, Float, func,select
from sqlalchemy.orm import sessionmaker, declarative_base

# ---------- DB SETUP ----------
DATABASE_URL = "sqlite:///./gps.db"  # file in the current folder

engine = create_engine(
    DATABASE_URL, connect_args={"check_same_thread": False}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

class Location(Base):
    __tablename__ = "locations"
    id = Column(Integer, primary_key=True, index=True)
    device_id = Column(String, index=True)
    lat = Column(Float, nullable=False)
    lng = Column(Float, nullable=False)
    bat = Column(Integer, nullable = False)
    timestamp = Column(String, nullable=False)

Base.metadata.create_all(bind=engine)

# ---------- API MODELS ----------
class LocationIn(BaseModel):
    device_id: str
    lat: float
    lng: float
    bat: int
    timestamp: Optional[str] = None  # allow server to fill in

class LocationOut(BaseModel):
    device_id: str
    lat: float
    lng: float
    bat: int
    timestamp: str

# ---------- FASTAPI ----------
app = FastAPI(title="GPS Dog Collar API")

# Dependency to get a DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

from fastapi import Depends

@app.post("/api/location", response_model=LocationOut)
def add_location(loc: LocationIn, db=Depends(get_db)):
    # Fill timestamp if not provided
    ts = loc.timestamp or datetime.utcnow().isoformat()

    db_obj = Location(
        device_id=loc.device_id,
        lat=loc.lat,
        lng=loc.lng,
        bat=loc.bat,
        timestamp=ts,
    )
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)

    return LocationOut(
        device_id=db_obj.device_id,
        lat=db_obj.lat,
        lng=db_obj.lng,
        bat=db_obj.bat,
        timestamp=db_obj.timestamp,
    )

@app.get("/api/location/latest", response_model=LocationOut)
def latest_location(device_id: str, db=Depends(get_db)):
    # get latest location for this device
    obj = (
        db.query(Location)
        .filter(Location.device_id == device_id)
        .order_by(Location.id.desc())
        .first()
    )
    if not obj:
        raise HTTPException(status_code=404, detail="No locations for this device")

    return LocationOut(
        device_id=obj.device_id,
        lat=obj.lat,
        lng=obj.lng,
        bat=obj.bat,
        timestamp=obj.timestamp,
    )

@app.get("/api/dogs")
def number_of_entrys(db=Depends(get_db)):
    #returns number of entries (dogs)
    return db.query(func.count(func.distinct(Location.device_id))).scalar()
    


@app.get("/api/device_id")
def get_id(db=Depends(get_db)):
    stmt = select(Location.device_id).distinct()
    result = db.execute(stmt).scalars().all()
    return result