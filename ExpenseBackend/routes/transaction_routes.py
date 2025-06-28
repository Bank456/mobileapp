from flask import Blueprint, request, jsonify
from db import db
from models.transaction import Transaction
from models.user import User
from sqlalchemy import func
from datetime import datetime
from dateutil import parser

transaction_bp = Blueprint('transaction', __name__)

# POST: เพิ่ม transaction ใหม่
@transaction_bp.route('/transactions', methods=['POST'])
def create_transaction():
    data = request.json
    try:
        created_at_str = data.get('created_at')
        if created_at_str:
            try:
                created_at = parser.isoparse(created_at_str)
            except Exception:
                return jsonify({'error': 'รูปแบบวันที่ไม่ถูกต้อง'}), 400
        else:
            created_at = datetime.utcnow()

        new_transaction = Transaction(
            user_id=data['user_id'],
            title=data['title'],
            amount=data['amount'],
            type=data['type'],
            category=data.get('category'),
            note=data.get('note'),
            created_at=created_at
        )
        db.session.add(new_transaction)
        db.session.commit()
        db.session.refresh(new_transaction)
        return jsonify({'message': 'เพิ่มรายการสำเร็จ', 'transaction': new_transaction.id}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

# GET: ดู transaction ของ user (พร้อมกรอง type)
@transaction_bp.route('/transactions', methods=['GET'])
def get_transactions():
    user_id = request.args.get('user_id')
    type_filter = request.args.get('type')  # กรองเฉพาะ income หรือ expense
    date_filter = request.args.get('date')  # รับพารามิเตอร์วันที่ (format: 'YYYY-MM-DD')
    start_date_str = request.args.get('start_date')  # format: 'YYYY-MM-DD'
    end_date_str = request.args.get('end_date')      # format: 'YYYY-MM-DD'

    try:
        query = db.session.query(Transaction).filter_by(user_id=user_id)

        if type_filter in ['income', 'expense']:
            query = query.filter(Transaction.type == type_filter)

        # กรองวันที่แบบระบุวันเดียว (date_filter)
        if date_filter:
            try:
                date_obj = datetime.strptime(date_filter, '%Y-%m-%d').date()
                query = query.filter(func.date(Transaction.created_at) == date_obj)
            except ValueError:
                pass

        # กรองวันที่แบบช่วง start_date ถึง end_date
        else:
            if start_date_str:
                try:
                    start_date = datetime.strptime(start_date_str, '%Y-%m-%d')
                    query = query.filter(Transaction.created_at >= start_date)
                except ValueError:
                    pass

            if end_date_str:
                try:
                    # เผื่อให้กรองถึงวันนั้นเต็มวัน (23:59:59)
                    end_date = datetime.strptime(end_date_str, '%Y-%m-%d')  
                    end_date = end_date.replace(hour=23, minute=59, second=59)
                    query = query.filter(Transaction.created_at <= end_date)
                except ValueError:
                    pass

        transactions = query.order_by(Transaction.created_at.desc()).all()

        result = [
            {
                'id': t.id,
                'title': t.title,
                'amount': float(t.amount),
                'type': t.type,
                'category': t.category,
                'note': t.note,
                'created_at': t.created_at.isoformat()
            }
            for t in transactions
        ]
        return jsonify(result), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# PUT: แก้ไข transaction
@transaction_bp.route('/transactions/<int:id>', methods=['PUT'])
def update_transaction(id):
    data = request.json
    try:
        transaction = db.session.query(Transaction).get(id)
        if not transaction:
            return jsonify({'error': 'ไม่พบรายการ'}), 404

        transaction.title = data.get('title', transaction.title)
        transaction.amount = data.get('amount', transaction.amount)
        transaction.type = data.get('type', transaction.type)
        transaction.category = data.get('category', transaction.category)
        transaction.note = data.get('note', transaction.note)

        db.session.commit()
        return jsonify({'message': 'แก้ไขเรียบร้อย'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

# DELETE: ลบ transaction
@transaction_bp.route('/transactions/<int:id>', methods=['DELETE'])
def delete_transaction(id):
    try:
        transaction = db.session.query(Transaction).get(id)
        if not transaction:
            return jsonify({'error': 'ไม่พบรายการ'}), 404

        db.session.delete(transaction)
        db.session.commit()
        return jsonify({'message': 'ลบรายการสำเร็จ'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

# GET: ดึง transaction รายการเดียวด้วย ID
@transaction_bp.route('/transactions/<int:id>', methods=['GET'])
def get_transaction(id):
    try:
        transaction = db.session.query(Transaction).get(id)
        if not transaction:
            return jsonify({'error': 'ไม่พบรายการ'}), 404

        result = {
            'id': transaction.id,
            'title': transaction.title,
            'amount': float(transaction.amount),
            'type': transaction.type,
            'category': transaction.category,
            'note': transaction.note,
            'created_at': transaction.created_at.isoformat()
        }
        return jsonify(result), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# GET: ดึงข้อมูล User ตาม ID (ชื่อ, อีเมล)
@transaction_bp.route('/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    try:
        user = db.session.query(User).get(user_id)
        if not user:
            return jsonify({'error': 'ไม่พบผู้ใช้'}), 404

        result = {
            'id': user.id,
            'username': user.username,
            'email': user.email
        }
        return jsonify(result), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# GET: สรุปยอดรายรับ รายจ่าย และยอดคงเหลือของ user
@transaction_bp.route('/users/<int:user_id>/summary', methods=['GET'])
def get_user_summary(user_id):
    try:
        income_sum = db.session.query(
            func.coalesce(func.sum(Transaction.amount), 0)
        ).filter_by(user_id=user_id, type='income').scalar()

        expense_sum = db.session.query(
            func.coalesce(func.sum(Transaction.amount), 0)
        ).filter_by(user_id=user_id, type='expense').scalar()

        balance = income_sum - expense_sum

        result = {
            'total_income': float(income_sum),
            'total_expense': float(expense_sum),
            'balance': float(balance)
        }
        return jsonify(result), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500
