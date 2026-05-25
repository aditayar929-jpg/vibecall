"""
VibeCall Backend API
FastAPI + PostgreSQL + Firebase + Agora
"""

from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List
import os
from datetime import datetime, timedelta
import hashlib
import secrets

app = FastAPI(
    title="VibeCall API",
    description="Backend API for VibeCall dating + video calling app",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ─── Models ───────────────────────────────────────────────────────────

class UserCreate(BaseModel):
    name: str
    email: Optional[str] = None
    phone: Optional[str] = None
    gender: Optional[str] = None
    age: Optional[int] = None
    interests: List[str] = []
    avatar: Optional[str] = None
    bio: Optional[str] = None
    location: Optional[str] = None

class UserUpdate(BaseModel):
    name: Optional[str] = None
    bio: Optional[str] = None
    gender: Optional[str] = None
    age: Optional[int] = None
    interests: Optional[List[str]] = None
    avatar: Optional[str] = None
    location: Optional[str] = None

class MatchRequest(BaseModel):
    user_id: str
    gender_filter: Optional[str] = "All"
    min_age: int = 18
    max_age: int = 60
    max_distance: int = 50

class VideoCallRequest(BaseModel):
    caller_id: str
    callee_id: str

class CoinTransaction(BaseModel):
    user_id: str
    amount: int
    type: str  # "earn", "spend", "purchase"
    description: str

class ReportRequest(BaseModel):
    reporter_id: str
    reported_id: str
    reason: str

class PremiumPurchase(BaseModel):
    user_id: str
    plan: str  # "monthly", "semi_annual", "annual"


# ─── In-memory store (replace with DB in production) ─────────────────

users_db = {}
matches_db = {}
calls_db = {}
coins_db = {}
reports_db = {}
premium_db = {}


# ─── Health Check ─────────────────────────────────────────────────────

@app.get("/")
async def root():
    return {
        "app": "VibeCall",
        "version": "1.0.0",
        "status": "running",
        "timestamp": datetime.utcnow().isoformat(),
    }


@app.get("/health")
async def health():
    return {"status": "healthy"}


# ─── Auth Endpoints ───────────────────────────────────────────────────

@app.post("/api/v1/auth/register")
async def register(user: UserCreate):
    user_id = hashlib.md5(f"{user.email or user.phone}{secrets.token_hex(8)}".encode()).hexdigest()[:16]
    users_db[user_id] = {
        "uid": user_id,
        "name": user.name,
        "email": user.email,
        "phone": user.phone,
        "gender": user.gender,
        "age": user.age,
        "interests": user.interests,
        "avatar": user.avatar or "",
        "bio": user.bio or "",
        "location": user.location or "",
        "is_online": True,
        "is_verified": False,
        "is_premium": False,
        "coins": 50,
        "followers": 0,
        "following": 0,
        "profile_completion": 40,
        "created_at": datetime.utcnow().isoformat(),
    }
    coins_db[user_id] = [
        {"amount": 50, "type": "earn", "description": "Welcome bonus", "timestamp": datetime.utcnow().isoformat()}
    ]
    return {"user_id": user_id, "status": "created", "welcome_coins": 50}


@app.get("/api/v1/auth/user/{user_id}")
async def get_user(user_id: str):
    if user_id not in users_db:
        raise HTTPException(status_code=404, detail="User not found")
    return users_db[user_id]


@app.put("/api/v1/auth/user/{user_id}")
async def update_user(user_id: str, update: UserUpdate):
    if user_id not in users_db:
        raise HTTPException(status_code=404, detail="User not found")
    user = users_db[user_id]
    for field, value in update.dict(exclude_unset=True).items():
        user[field] = value
    return {"status": "updated", "user": user}


# ─── Discovery / Matching ─────────────────────────────────────────────

@app.post("/api/v1/discover")
async def discover_users(req: MatchRequest):
    results = []
    for uid, user in users_db.items():
        if uid == req.user_id:
            continue
        if req.gender_filter != "All" and user.get("gender") != req.gender_filter:
            continue
        if user.get("age", 0) < req.min_age or user.get("age", 0) > req.max_age:
            continue
        results.append(user)
    return {"users": results[:20], "count": len(results[:20])}


@app.post("/api/v1/match/like")
async def like_user(liker_id: str, liked_id: str):
    if liker_id not in matches_db:
        matches_db[liker_id] = set()
    matches_db[liker_id].add(liked_id)

    # Check mutual match
    if liked_id in matches_db and liker_id in matches_db[liked_id]:
        return {"matched": True, "message": "It's a match!"}
    return {"matched": False, "message": "Like recorded"}


@app.get("/api/v1/matches/{user_id}")
async def get_matches(user_id: str):
    if user_id not in matches_db:
        return {"matches": []}
    mutual = []
    for liked_id in matches_db[user_id]:
        if liked_id in matches_db and user_id in matches_db[liked_id]:
            if liked_id in users_db:
                mutual.append(users_db[liked_id])
    return {"matches": mutual}


# ─── Video Calling ────────────────────────────────────────────────────

@app.post("/api/v1/call/start")
async def start_call(req: VideoCallRequest):
    call_id = secrets.token_hex(16)
    channel_name = f"vibecall_{call_id}"
    token = f"agora_token_{call_id}"

    calls_db[call_id] = {
        "call_id": call_id,
        "caller_id": req.caller_id,
        "callee_id": req.callee_id,
        "channel_name": channel_name,
        "token": token,
        "status": "ringing",
        "started_at": datetime.utcnow().isoformat(),
    }

    return {
        "call_id": call_id,
        "channel_name": channel_name,
        "token": token,
        "status": "ringing",
    }


@app.post("/api/v1/call/end/{call_id}")
async def end_call(call_id: str):
    if call_id not in calls_db:
        raise HTTPException(status_code=404, detail="Call not found")
    call = calls_db[call_id]
    call["status"] = "ended"
    call["ended_at"] = datetime.utcnow().isoformat()

    # Deduct coins
    caller_id = call["caller_id"]
    if caller_id in users_db:
        users_db[caller_id]["coins"] = max(0, users_db[caller_id]["coins"] - 15)

    return {"status": "ended", "duration": "calculated"}


# ─── Coins & Rewards ──────────────────────────────────────────────────

@app.get("/api/v1/wallet/{user_id}")
async def get_wallet(user_id: str):
    if user_id not in users_db:
        raise HTTPException(status_code=404, detail="User not found")
    return {
        "coins": users_db[user_id]["coins"],
        "transactions": coins_db.get(user_id, []),
    }


@app.post("/api/v1/wallet/claim-daily")
async def claim_daily(user_id: str):
    if user_id not in users_db:
        raise HTTPException(status_code=404, detail="User not found")
    users_db[user_id]["coins"] += 10
    if user_id not in coins_db:
        coins_db[user_id] = []
    coins_db[user_id].append({
        "amount": 10,
        "type": "earn",
        "description": "Daily reward",
        "timestamp": datetime.utcnow().isoformat(),
    })
    return {"coins": users_db[user_id]["coins"], "claimed": 10}


@app.post("/api/v1/wallet/gift")
async def send_gift(sender_id: str, receiver_id: str, amount: int):
    if sender_id not in users_db:
        raise HTTPException(status_code=404, detail="Sender not found")
    if receiver_id not in users_db:
        raise HTTPException(status_code=404, detail="Receiver not found")
    if users_db[sender_id]["coins"] < amount:
        raise HTTPException(status_code=400, detail="Insufficient coins")

    users_db[sender_id]["coins"] -= amount
    users_db[receiver_id]["coins"] += amount
    return {"status": "sent", "amount": amount, "sender_coins": users_db[sender_id]["coins"]}


# ─── Premium ──────────────────────────────────────────────────────────

PREMIUM_PLANS = {
    "monthly": {"price": 9.99, "coins_bonus": 100, "duration_days": 30},
    "semi_annual": {"price": 39.99, "coins_bonus": 500, "duration_days": 180},
    "annual": {"price": 59.99, "coins_bonus": 1000, "duration_days": 365},
}


@app.post("/api/v1/premium/purchase")
async def purchase_premium(req: PremiumPurchase):
    if req.plan not in PREMIUM_PLANS:
        raise HTTPException(status_code=400, detail="Invalid plan")
    plan = PREMIUM_PLANS[req.plan]
    if req.user_id in users_db:
        users_db[req.user_id]["is_premium"] = True
        users_db[req.user_id]["coins"] += plan["coins_bonus"]
    return {
        "status": "activated",
        "plan": req.plan,
        "coins_bonus": plan["coins_bonus"],
        "expires_at": (datetime.utcnow() + timedelta(days=plan["duration_days"])).isoformat(),
    }


@app.get("/api/v1/premium/plans")
async def get_plans():
    return {"plans": PREMIUM_PLANS}


# ─── Moderation ───────────────────────────────────────────────────────

@app.post("/api/v1/report")
async def report_user(req: ReportRequest):
    report_id = secrets.token_hex(8)
    reports_db[report_id] = {
        "report_id": report_id,
        "reporter_id": req.reporter_id,
        "reported_id": req.reported_id,
        "reason": req.reason,
        "status": "pending",
        "timestamp": datetime.utcnow().isoformat(),
    }
    return {"status": "reported", "report_id": report_id}


@app.post("/api/v1/block")
async def block_user(blocker_id: str, blocked_id: str):
    if blocker_id in users_db:
        if "blocked_users" not in users_db[blocker_id]:
            users_db[blocker_id]["blocked_users"] = []
        users_db[blocker_id]["blocked_users"].append(blocked_id)
    return {"status": "blocked"}


# ─── Admin Endpoints ──────────────────────────────────────────────────

@app.get("/api/v1/admin/stats")
async def admin_stats():
    return {
        "total_users": len(users_db),
        "total_matches": sum(len(v) for v in matches_db.values()),
        "total_calls": len(calls_db),
        "total_reports": len(reports_db),
        "premium_users": sum(1 for u in users_db.values() if u.get("is_premium")),
    }


@app.get("/api/v1/admin/users")
async def admin_users():
    return {"users": list(users_db.values())}


@app.get("/api/v1/admin/reports")
async def admin_reports():
    return {"reports": list(reports_db.values())}


@app.post("/api/v1/admin/ban/{user_id}")
async def ban_user(user_id: str, reason: str = "Violation"):
    if user_id in users_db:
        users_db[user_id]["is_banned"] = True
        users_db[user_id]["ban_reason"] = reason
    return {"status": "banned", "user_id": user_id, "reason": reason}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
