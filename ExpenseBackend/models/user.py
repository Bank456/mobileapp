from datetime import datetime
from db import db

class User(db.Model):
    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True, index=True)
    username = db.Column(db.String(50), unique=True, nullable=False)
    email = db.Column(db.String(100), unique=True, nullable=False)
    password = db.Column(db.String(255), nullable=False)    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    # ความสัมพันธ์กับตาราง Transaction
    transactions = db.relationship('Transaction', back_populates='user')
