package com.example.connect

import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.navigation3.runtime.entryProvider
import androidx.navigation3.runtime.rememberNavBackStack
import androidx.navigation3.ui.NavDisplay
import com.example.connect.ui.auth.LandingScreen
import com.example.connect.ui.auth.EmployeeLoginScreen
import com.example.connect.ui.auth.HRLoginScreen
import com.example.connect.ui.auth.SignupScreen
import com.example.connect.ui.dashboard.EmployeeDashboardScreen
import com.example.connect.ui.dashboard.HRDashboardScreen

@Composable
fun MainNavigation() {
  val backStack = rememberNavBackStack(Landing)

  NavDisplay(
    backStack = backStack,
    onBack = { backStack.removeLastOrNull() },
    entryProvider =
      entryProvider {
        entry<Landing> {
          LandingScreen(onNavigate = { navKey -> backStack.add(navKey) })
        }
        entry<EmployeeLogin> {
          EmployeeLoginScreen(onNavigate = { navKey -> backStack.add(navKey) })
        }
        entry<HRLogin> {
          HRLoginScreen(onNavigate = { navKey -> backStack.add(navKey) })
        }
        entry<Signup> {
          SignupScreen(onNavigate = { navKey -> backStack.add(navKey) })
        }
        entry<EmployeeDashboard> {
          EmployeeDashboardScreen(onNavigate = { navKey -> backStack.add(navKey) })
        }
        entry<HRDashboard> {
          HRDashboardScreen(onNavigate = { navKey -> backStack.add(navKey) })
        }
        entry<HREmployeesScreen> {
          com.example.connect.ui.dashboard.HREmployeesScreen(onNavigate = { navKey -> backStack.add(navKey) })
        }
        entry<HRLeavesScreen> {
          com.example.connect.ui.dashboard.HRLeavesScreen(onNavigate = { navKey -> backStack.add(navKey) })
        }
        entry<HRAttendanceScreen> {
          com.example.connect.ui.dashboard.HRAttendanceScreen(onNavigate = { navKey -> backStack.add(navKey) })
        }
      },
  )
}
