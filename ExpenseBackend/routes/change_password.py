from flask import Blueprint, request, jsonify
from werkzeug.security import check_password_hash, generate_password_hash
from db import db
from models.user import User

change_password_bp = Blueprint('change_password', __name__)

@change_password_bp.route('/change-password/<int:user_id>', methods=['PUT'])
def change_password(user_id):
    data = request.json
    old_password = data.get('old_password')
    new_password = data.get('new_password')

    if not old_password or not new_password:
        return jsonify({'error': 'กรุณากรอกรหัสผ่านเดิมและรหัสผ่านใหม่'}), 400

    try:
        user = db.session.query(User).get(user_id)
        if not user:
            return jsonify({'error': 'ไม่พบผู้ใช้'}), 404

        if not check_password_hash(user.password, old_password):
            return jsonify({'error': 'รหัสผ่านเดิมไม่ถูกต้อง'}), 400

        user.password = generate_password_hash(new_password)
        db.session.commit()
        return jsonify({'message': 'เปลี่ยนรหัสผ่านสำเร็จ'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'เกิดข้อผิดพลาด: {str(e)}'}), 500
