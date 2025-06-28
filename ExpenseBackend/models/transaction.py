from datetime import datetime
from db import db  # Import db จากไฟล์ db.py ที่ประกาศ SQLAlchemy()

class Transaction(db.Model):
    __tablename__ = 'transactions'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    title = db.Column(db.String(100), nullable=False)
    amount = db.Column(db.Numeric(10, 2), nullable=False)
    type = db.Column(db.String(10), nullable=False)  # income หรือ expense
    category = db.Column(db.String(50))
    note = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    __table_args__ = (
        db.CheckConstraint("type IN ('income', 'expense')", name='check_transaction_type'),
    )

    user = db.relationship('User', back_populates='transactions')

    def __repr__(self):
        return f"<Transaction(id={self.id}, user_id={self.user_id}, title='{self.title}', amount={self.amount}, type='{self.type}')>"
