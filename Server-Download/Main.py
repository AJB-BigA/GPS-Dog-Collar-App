from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from datetime import datetime
from typing import Optional , List, Tuple
from sqlalchemy import create_engine, Column, Integer, String, Float, func,select, Boolean, JSON, ForeignKey
from sqlalchemy.orm import sessionmaker, declarative_base
from fastapi import Depends
import PushNotification

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

class DeviceFenceState(Base):
    __tablename__ = "device_fence_state"

    device_id = Column(String, primary_key=True)    
    fence_id  = Column(Integer, ForeignKey("geo_fence.id"), primary_key=True)
    inside    = Column(Boolean, default=True)

class APNHolder(Base):
    __tablename__ = "apn_storage"

    id = Column(Integer, primary_key=True, index=True)
    device_id = Column(String, unique=True, index=True) 
    token = Column(String, nullable = False)

#make sure this is called after the classes
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
    id: int
    name: str
    points: List[Tuple[float, float]]

class APNIn(BaseModel):
    device_id : str
    token: str

class IdBasedNotification(BaseModel):
    device_id : str
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
    ts = loc.timestamp or datetime.utcnow().isoformat()

    db_obj = Location(
        device_id=loc.device_id,
        lat=loc.lat,
        lng=loc.lng,
        bat=loc.bat,
        timestamp=ts,
        status=loc.status
    )
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)

    # Check all fences associated with this device
    device = db.query(APNHolder).all()
    fences = db.query(GeoFence).all()
    

    for fence in fences:
        
        is_inside_now = is_inside_fence(loc.lat, loc.lng, fence.points)

        state = db.query(DeviceFenceState).filter_by(
            device_id=loc.device_id,
            fence_id=fence.id
        ).first()

        if state is None:
            db.add(DeviceFenceState(device_id=loc.device_id, fence_id=fence.id, inside=is_inside_now))
        elif state.inside and not is_inside_now:
            for apn in device:
                PushNotification.send_notification(apn.token, fence.name, loc.device_id)
        if state:
            state.inside = is_inside_now

    db.commit()

    return LocationOut(
        device_id=db_obj.device_id,
        lat=db_obj.lat,
        lng=db_obj.lng,
        bat=db_obj.bat,
        timestamp=db_obj.timestamp,
        status=db_obj.status
    )

@app.post("/api/lostWifi")
def wifi_lost_notification(incoming_id : IdBasedNotification, db=Depends(get_db)):
    """Recives when the dog leaves wifi for the first time"""
    collar_warning = incoming_id.device_id
    devices = db.query(APNHolder).all()

    for device in devices:
        PushNotification.send_warning(device.token, collar_warning)

@app.post("/api/geo_fence/new-fence/", response_model = GeoFenceOut)
def add_new_fence(fence: GeoFenceIn, db=Depends(get_db)):
    """Adds new geo fences to the database"""
    db_obj = GeoFence(
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

@app.post("/api/APNHolder/store", response_model = APNIn)
def store_apn_value(apn : APNIn, db=Depends(get_db)):
    """Stores the data for the apn numbers"""
    db_object = db.query(APNHolder).filter(APNHolder.device_id == apn.device_id).first()
    print(apn.token)
    if db_object:
        db_object.token = apn.token  # update existing
    else:
        db_object = APNHolder(device_id=apn.device_id, token=apn.token)  # create new

    db.add(db_object)
    db.commit()
    db.refresh(db_object)

    return db_object
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

    return obj

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

@app.get("/api/geoFence/data")
def get_geo_data(db=Depends(get_db)):
    """Returns the data for geo fences"""
    geofence = db.execute(select(GeoFence)).scalars().all()
    return geofence
    
#delete v------------------------------------------------------v


@app.delete("/api/geoFence/{fence_id}")
def delete_geo_fence(fence_id: int, db=Depends(get_db)):
    """Deletes a geoFence by ID"""
    obj = db.get(GeoFence, fence_id)
    if not obj:
        raise HTTPException(status_code =404, detail = "details not found")

    db.delete(obj)
    db.commit()

    return {"Deleted", fence_id}



#other functions V-----------------------------------------------------V
def is_inside_fence(lat, lng, polygon):
    """Returns true if the point is inside a fence"""

    n = len(polygon)
    inside = False
    j = n - 1
    for i in range(n):
        xi, yi = polygon[i][1], polygon[i][0]  # lng, lat
        xj, yj = polygon[j][1], polygon[j][0]  # lng, lat
        if ((yi > lng) != (yj > lng)) and (lat < (xj - xi) * (lng - yi) / (yj - yi) + xi):
            inside = not inside
        j = i
    return inside
