package com.example.connect

import androidx.navigation3.runtime.NavKey
import kotlinx.serialization.Serializable

@Serializable data object Landing : NavKey
@Serializable data object EmployeeLogin : NavKey
@Serializable data object HRLogin : NavKey
@Serializable data object Signup : NavKey
@Serializable data object EmployeeDashboard : NavKey
@Serializable data object HRDashboard : NavKey
@Serializable data object HREmployeesScreen : NavKey
@Serializable data object HRLeavesScreen : NavKey
@Serializable data object HRAttendanceScreen : NavKey
