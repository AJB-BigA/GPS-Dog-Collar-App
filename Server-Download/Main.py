from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from datetime import datetime
from typing import Optional , List, Tuple
from sqlalchemy import create_engine, Column, Integer, String, Float, func,select, Boolean, JSON
from sqlalchemy.orm import sessionmaker, declarative_base
from fastapi import Depends

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
    status = Column(Boolean, nullable = False)

class GeoFence(Base):
    __tablename__ = "geo_fence"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    points = Column(JSON, nullable=False)



Base.metadata.create_all(bind=engine)



# ---------- API MODELS ----------
class LocationIn(BaseModel):
    device_id: str
    lat: float
    lng: float
    bat: int
    status : bool
    timestamp: Optional[str] = None  # allow server to fill in

class LocationOut(BaseModel):
    device_id: str
    lat: float
    lng: float
    bat: int
    status: bool
    timestamp: str

class GeoFenceIn(BaseModel):
    name: str
    points: List[Tuple[float, float]]


class GeoFenceOut(BaseModel):
    name: str
    points: List[Tuple[float, float]]


# ---------- FASTAPI ----------
app = FastAPI(title="GPS Dog Collar API")

# Dependency to get a DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
#posts v----------------------------------------------v

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
        status = loc.status
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
        status = db_obj.status
    )



@app.post("/api/geo_fence/new-fence/", response_model = GeoFenceOut)
def add_new_fence(fence: GeoFenceIn, db=Depends(get_db)):
    """Adds new geo fences to the database"""
    db_obj = GeoFence(
        id = fence.id,
        name = fence.name,
        points = fence.points
    )

    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)

    return GeoFenceOut(
        id = db_obj.id,
        name = db_obj.name,
        points = db_obj.points
    )



#Getters v--------------------------------------v

@app.get("/api/location/latest", response_model=LocationOut)
def latest_location(device_id: str, db=Depends(get_db)):
    """get latest location for this device"""
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
        status = obj.status
    )

@app.get("/api/dogs")
def number_of_entrys(db=Depends(get_db)):
    """returns number of entries (dogs)"""
    return db.query(func.count(func.distinct(Location.device_id))).scalar()
    

@app.get("/api/device_id")
def get_id(db=Depends(get_db)):
    """Gets the set ids of each device"""
    stmt = select(Location.device_id).distinct()
    result = db.execute(stmt).scalars().all()
    return result

@app.get("/api/geoFence/rows")
def geo_rows(db=Depends(get_db)):
    """Returs the number of geo fences"""
    return db.query(func.count(func.distinct(GeoFence.id))).scalar()