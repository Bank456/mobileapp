from flask import Flask
from db import db
from routes.auth_routes import auth_bp
from routes.transaction_routes import transaction_bp
from routes.change_password import change_password_bp
from routes.summary import summary_bp
from routes.user import user_bp
from models.user import User
from models.transaction import Transaction
from dotenv import load_dotenv
import os

# โหลดไฟล์ .env
load_dotenv()

app = Flask(__name__)

# อ่านค่า DATABASE_URL จาก environment variable
app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('DATABASE_URL')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# ถ้ามี SECRET_KEY ก็ใส่ด้วย
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'default_secret_key')

db.init_app(app)

# ลงทะเบียน Blueprint ต่าง ๆ
app.register_blueprint(auth_bp)
app.register_blueprint(transaction_bp)
app.register_blueprint(user_bp)
app.register_blueprint(summary_bp)
app.register_blueprint(change_password_bp)

with app.app_context():
    db.create_all()

if __name__ == '__main__':
    app.run(debug=True)
