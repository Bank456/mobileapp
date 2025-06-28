from flask import Blueprint, request, jsonify
from sqlalchemy import func
from db import db
from models.transaction import Transaction
from datetime import datetime

summary_bp = Blueprint('summary', __name__)

@summary_bp.route('/summary/expenses', methods=['GET'])
def summary_expenses():
    user_id = request.args.get('user_id', type=int)
    month = request.args.get('month', type=str)  # format: YYYY-MM
    type_filter = request.args.get('type', 'expense')  # default = expense

    if not user_id or not month:
        return jsonify({'error': 'ต้องระบุ user_id และ month'}), 400

    try:
        year, month_num = map(int, month.split('-'))
        start_date = datetime(year, month_num, 1)
        if month_num == 12:
            end_date = datetime(year + 1, 1, 1)
        else:
            end_date = datetime(year, month_num + 1, 1)
    except Exception:
        return jsonify({'error': 'รูปแบบเดือนไม่ถูกต้อง (YYYY-MM)'}), 400

    try:
        query = (
            db.session.query(
                Transaction.category,
                func.sum(Transaction.amount).label('amount')
            )
            .filter(
                Transaction.user_id == user_id,
                Transaction.created_at >= start_date,
                Transaction.created_at < end_date
            )
        )

        if type_filter != 'all':
            query = query.filter(Transaction.type == type_filter)

        results = query.group_by(Transaction.category).all()
        total = sum([r.amount for r in results])

        return jsonify({
            'total_expense': f"{total:.2f}",
            'by_category': [
                {'category': r.category, 'amount': float(r.amount)} for r in results
            ]
        })

    except Exception as e:
        return jsonify({'error': f'เกิดข้อผิดพลาด: {str(e)}'}), 500
