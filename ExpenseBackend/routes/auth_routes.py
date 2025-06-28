from flask import Blueprint, request, jsonify
from werkzeug.security import generate_password_hash, check_password_hash
from db import db
from models.user import User

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.json
    username = data.get('username')
    email = data.get('email')
    password = data.get('password')

    if not username or not email or not password:
        return jsonify({'error': 'ข้อมูลไม่ครบถ้วน'}), 400

    hashed_password = generate_password_hash(password)

    try:
        existing_user = db.session.query(User).filter((User.username == username) | (User.email == email)).first()
        if existing_user:
            return jsonify({'error': 'Username หรือ Email นี้ถูกใช้แล้ว'}), 409

        new_user = User(username=username, email=email, password=hashed_password)
        db.session.add(new_user)
        db.session.commit()
        return jsonify({'message': 'ลงทะเบียนสำเร็จ', 'username': username}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.json
    email = data.get('email')
    password = data.get('password')

    if not email or not password:
        return jsonify({'error': 'ข้อมูลไม่ครบถ้วน'}), 400

    try:
        user = db.session.query(User).filter(User.email == email).first()
        if user and check_password_hash(user.password, password):
            return jsonify({
                'message': 'เข้าสู่ระบบสำเร็จ',
                'email': user.email,
                'userId': user.id
            }), 200
        else:
            return jsonify({'error': 'อีเมลหรือรหัสผ่านไม่ถูกต้อง'}), 401
    except Exception as e:
        return jsonify({'error': str(e)}), 500
