package com.example.connect.network

import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.Header
import retrofit2.http.POST

data class LoginRequest(val email: String, val password: String)
data class LoginResponse(val token: String?, val role: String?, val message: String?)

data class SignupRequest(val name: String, val email: String, val password: String, val role: String = "employee")
data class SignupResponse(val message: String?)

data class ProfileResponse(val name: String, val email: String, val role: String, val department: String)

data class AttendanceRequest(val action: String)
data class AttendanceResponse(val message: String)

data class AttendanceHistory(val date: String, val punch_in: String, val punch_out: String)

data class LeaveRequest(val leave_type: String, val reason: String, val date: String)
data class LeaveResponse(val message: String)

data class HREmployee(val id: String, val name: String, val email: String, val role: String, val department: String)
data class HREmployeeUpdateRequest(val department: String?, val role: String?)

data class HRLeave(val id: String, val employee_name: String, val leave_type: String, val reason: String, val date: String, val status: String)
data class HRLeaveUpdateRequest(val status: String)

data class HRAttendanceRecord(val id: String, val employee_name: String, val date: String, val punch_in: String, val punch_out: String)

data class HRAnalyticsResponse(val totalEmployees: Int, val pendingLeaves: Int, val todayAttendance: Int)

interface ApiService {
    @POST("auth/login")
    suspend fun login(@Body request: LoginRequest): Response<LoginResponse>

    @POST("auth/signup")
    suspend fun signup(@Body request: SignupRequest): Response<SignupResponse>

    @GET("employee/profile")
    suspend fun getProfile(@Header("Authorization") token: String): Response<ProfileResponse>

    @POST("attendance")
    suspend fun punchAttendance(@Header("Authorization") token: String, @Body request: AttendanceRequest): Response<AttendanceResponse>

    @GET("attendance")
    suspend fun getAttendanceHistory(@Header("Authorization") token: String): Response<List<AttendanceHistory>>

    @POST("leave")
    suspend fun applyLeave(@Header("Authorization") token: String, @Body request: LeaveRequest): Response<LeaveResponse>

    @GET("hr/employees")
    suspend fun getHREmployees(@Header("Authorization") token: String): Response<List<HREmployee>>

    @POST("hr/employees")
    suspend fun createHREmployee(@Header("Authorization") token: String, @Body request: SignupRequest): Response<SignupResponse>

    @retrofit2.http.PUT("hr/employees/{id}")
    suspend fun updateHREmployee(@Header("Authorization") token: String, @retrofit2.http.Path("id") id: String, @Body request: HREmployeeUpdateRequest): Response<SignupResponse>

    @retrofit2.http.DELETE("hr/employees/{id}")
    suspend fun deleteHREmployee(@Header("Authorization") token: String, @retrofit2.http.Path("id") id: String): Response<SignupResponse>

    @GET("hr/leaves")
    suspend fun getHRLeaves(@Header("Authorization") token: String): Response<List<HRLeave>>

    @retrofit2.http.PUT("hr/leaves/{id}")
    suspend fun updateHRLeave(@Header("Authorization") token: String, @retrofit2.http.Path("id") id: String, @Body request: HRLeaveUpdateRequest): Response<SignupResponse>

    @GET("hr/attendance")
    suspend fun getHRAttendance(@Header("Authorization") token: String): Response<List<HRAttendanceRecord>>

    @GET("hr/analytics")
    suspend fun getHRAnalytics(@Header("Authorization") token: String): Response<HRAnalyticsResponse>
}
