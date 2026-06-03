from flask import Flask, request, jsonify
from flask_restful import Api, Resource
from pymongo import MongoClient
import os
from dotenv import load_dotenv
from werkzeug.security import generate_password_hash, check_password_hash
import jwt
import datetime
from functools import wraps
from bson.objectid import ObjectId

load_dotenv()

app = Flask(__name__)
api = Api(app)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'default-secret-key')

# MongoDB Setup
MONGO_URI = os.getenv('MONGO_URI')
if MONGO_URI:
    client = MongoClient(MONGO_URI)
    db = client.hrapp_db
else:
    db = None

def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            token = auth_header.split(" ")[1] if "Bearer " in auth_header else auth_header
        if not token:
            return {'message': 'Token is missing'}, 401
        try:
            data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
            current_user = db.employees.find_one({'_id': ObjectId(data['user_id'])})
            if not current_user:
                current_user = db.hr_users.find_one({'_id': ObjectId(data['user_id'])})
            if not current_user:
                return {'message': 'Invalid user token'}, 401
        except Exception as e:
            return {'message': 'Token is invalid'}, 401
        return f(*args, **kwargs, current_user=current_user)
    return decorated

def hr_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            token = auth_header.split(" ")[1] if "Bearer " in auth_header else auth_header
        if not token:
            return {'message': 'Token is missing'}, 401
        try:
            data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
            current_user = db.hr_users.find_one({'_id': ObjectId(data['user_id'])})
            if not current_user or current_user.get('role') != 'HR':
                return {'message': 'Invalid user token or HR access required'}, 403
        except Exception as e:
            return {'message': 'Token is invalid'}, 401
        return f(*args, **kwargs, current_user=current_user)
    return decorated

class Signup(Resource):
    def post(self):
        if db is None:
            return {'message': 'Database not configured'}, 500
        
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')
        name = data.get('name')
        role = data.get('role', 'employee')
        
        if role == 'HR':
            if db.hr_users.find_one({'email': email}):
                return {'message': 'User already exists'}, 400
            db.hr_users.insert_one({
                'name': name,
                'email': email,
                'password': hashed_password,
                'role': role,
                'department': 'Unassigned'
            })
        else:
            if db.employees.find_one({'email': email}):
                return {'message': 'User already exists'}, 400
            db.employees.insert_one({
                'name': name,
                'email': email,
                'password': hashed_password,
                'role': role,
                'department': 'Unassigned'
            })
        
        return {'message': 'User created successfully'}, 201

class Login(Resource):
    def post(self):
        if db is None:
            return {'message': 'Database not configured'}, 500
            
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')
        
        user = db.employees.find_one({'email': email})
        if not user:
            user = db.hr_users.find_one({'email': email})
        
        if not user or not check_password_hash(user['password'], password):
            return {'message': 'Invalid credentials'}, 401
            
        token = jwt.encode({
            'user_id': str(user['_id']),
            'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=24)
        }, app.config['SECRET_KEY'], algorithm='HS256')
        
        return {'token': token, 'role': user['role']}

class Profile(Resource):
    @token_required
    def get(self, current_user):
        user_data = {
            'name': current_user.get('name'),
            'email': current_user.get('email'),
            'role': current_user.get('role', 'employee'),
            'department': current_user.get('department', 'N/A')
        }
        return user_data, 200

class Attendance(Resource):
    @token_required
    def post(self, current_user):
        data = request.get_json()
        action = data.get('action')
        today = datetime.datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
        
        record = db.attendance.find_one({'employee_id': current_user['_id'], 'date': today})
        now = datetime.datetime.utcnow()
        
        if action == 'punch_in':
            if record and record.get('punch_in'):
                return {'message': 'Already punched in today'}, 400
            if record:
                db.attendance.update_one({'_id': record['_id']}, {'$set': {'punch_in': now}})
            else:
                db.attendance.insert_one({'employee_id': current_user['_id'], 'date': today, 'punch_in': now})
            return {'message': 'Punched in successfully'}, 200
            
        elif action == 'punch_out':
            if not record or not record.get('punch_in'):
                return {'message': 'Must punch in first'}, 400
            if record.get('punch_out'):
                return {'message': 'Already punched out today'}, 400
            db.attendance.update_one({'_id': record['_id']}, {'$set': {'punch_out': now}})
            return {'message': 'Punched out successfully'}, 200
            
        return {'message': 'Invalid action'}, 400

    @token_required
    def get(self, current_user):
        records = db.attendance.find({'employee_id': current_user['_id']}).sort('date', -1).limit(30)
        history = []
        for r in records:
            history.append({
                'date': r.get('date').strftime('%Y-%m-%d') if r.get('date') else '',
                'punch_in': r.get('punch_in').strftime('%H:%M:%S') if r.get('punch_in') else '',
                'punch_out': r.get('punch_out').strftime('%H:%M:%S') if r.get('punch_out') else ''
            })
        return history, 200

class Leave(Resource):
    @token_required
    def post(self, current_user):
        data = request.get_json()
        leave_type = data.get('leave_type')
        reason = data.get('reason')
        date_str = data.get('date')
        
        db.leaves.insert_one({
            'employee_id': current_user['_id'],
            'leave_type': leave_type,
            'reason': reason,
            'date': date_str,
            'status': 'Pending'
        })
        return {'message': 'Leave applied successfully'}, 201

    @token_required
    def get(self, current_user):
        records = db.leaves.find({'employee_id': current_user['_id']}).sort('_id', -1)
        history = []
        for r in records:
            history.append({
                'leave_type': r.get('leave_type'),
                'reason': r.get('reason'),
                'date': r.get('date'),
                'status': r.get('status')
            })
        return history, 200

# Add routes
api.add_resource(Signup, '/api/auth/signup')
api.add_resource(Login, '/api/auth/login')
api.add_resource(Profile, '/api/employee/profile')
api.add_resource(Attendance, '/api/attendance')
api.add_resource(Leave, '/api/leave')

class HREmployees(Resource):
    @hr_required
    def get(self, current_user):
        employees = db.employees.find({}, {'password': 0})
        result = []
        for emp in employees:
            result.append({
                'id': str(emp['_id']),
                'name': emp.get('name'),
                'email': emp.get('email'),
                'role': emp.get('role', 'employee'),
                'department': emp.get('department', 'Unassigned')
            })
        return result, 200

    @hr_required
    def post(self, current_user):
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')
        name = data.get('name')
        role = data.get('role', 'employee')
        department = data.get('department', 'Unassigned')
        
        if db.employees.find_one({'email': email}):
            return {'message': 'User already exists'}, 400
            
        hashed_password = generate_password_hash(password)
        db.employees.insert_one({
            'name': name,
            'email': email,
            'password': hashed_password,
            'role': role,
            'department': department
        })
        
        return {'message': 'Employee hired successfully'}, 201

class HREmployeeDetail(Resource):
    @hr_required
    def put(self, current_user, employee_id):
        data = request.get_json()
        update_fields = {}
        if 'department' in data:
            update_fields['department'] = data['department']
        if 'role' in data:
            update_fields['role'] = data['role']
            
        if update_fields:
            db.employees.update_one({'_id': ObjectId(employee_id)}, {'$set': update_fields})
            return {'message': 'Employee updated successfully'}, 200
        return {'message': 'No fields to update'}, 400

    @hr_required
    def delete(self, current_user, employee_id):
        result = db.employees.delete_one({'_id': ObjectId(employee_id)})
        if result.deleted_count:
            return {'message': 'Employee deleted successfully'}, 200
        return {'message': 'Employee not found'}, 404

class HRLeaves(Resource):
    @hr_required
    def get(self, current_user):
        records = db.leaves.find().sort('_id', -1)
        result = []
        for r in records:
            emp = db.employees.find_one({'_id': r['employee_id']})
            emp_name = emp['name'] if emp else 'Unknown'
            result.append({
                'id': str(r['_id']),
                'employee_name': emp_name,
                'leave_type': r.get('leave_type'),
                'reason': r.get('reason'),
                'date': r.get('date'),
                'status': r.get('status')
            })
        return result, 200

class HRLeaveDetail(Resource):
    @hr_required
    def put(self, current_user, leave_id):
        data = request.get_json()
        status = data.get('status')
        if status in ['Approved', 'Rejected']:
            db.leaves.update_one({'_id': ObjectId(leave_id)}, {'$set': {'status': status}})
            return {'message': f'Leave {status.lower()} successfully'}, 200
        return {'message': 'Invalid status'}, 400

class HRAttendance(Resource):
    @hr_required
    def get(self, current_user):
        records = db.attendance.find().sort('date', -1).limit(100)
        result = []
        for r in records:
            emp = db.employees.find_one({'_id': r['employee_id']})
            emp_name = emp['name'] if emp else 'Unknown'
            result.append({
                'id': str(r['_id']),
                'employee_name': emp_name,
                'date': r.get('date').strftime('%Y-%m-%d') if r.get('date') else '',
                'punch_in': r.get('punch_in').strftime('%H:%M:%S') if r.get('punch_in') else '',
                'punch_out': r.get('punch_out').strftime('%H:%M:%S') if r.get('punch_out') else ''
            })
        return result, 200

class HRAnalytics(Resource):
    @hr_required
    def get(self, current_user):
        total_employees = db.employees.count_documents({})
        pending_leaves = db.leaves.count_documents({'status': 'Pending'})
        today = datetime.datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
        today_attendance = db.attendance.count_documents({'date': today})
        
        return {
            'totalEmployees': total_employees,
            'pendingLeaves': pending_leaves,
            'todayAttendance': today_attendance
        }, 200

api.add_resource(HREmployees, '/api/hr/employees')
api.add_resource(HREmployeeDetail, '/api/hr/employees/<string:employee_id>')
api.add_resource(HRLeaves, '/api/hr/leaves')
api.add_resource(HRLeaveDetail, '/api/hr/leaves/<string:leave_id>')
api.add_resource(HRAttendance, '/api/hr/attendance')
api.add_resource(HRAnalytics, '/api/hr/analytics')

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
