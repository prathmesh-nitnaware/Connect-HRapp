package com.example.connect.ui.dashboard

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.navigation3.runtime.NavKey
import com.example.connect.Landing

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HRDashboardScreen(onNavigate: (NavKey) -> Unit) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Connect - HR Dashboard") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    titleContentColor = MaterialTheme.colorScheme.onPrimary,
                )
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text("HR Overview", style = MaterialTheme.typography.headlineMedium)
            Spacer(modifier = Modifier.height(32.dp))
            
            Text("Manage Employees, View Attendance, and Approve Leaves here.", textAlign = androidx.compose.ui.text.style.TextAlign.Center)
            Spacer(modifier = Modifier.height(32.dp))
            
            Button(
                onClick = { onNavigate(com.example.connect.HREmployeesScreen) },
                modifier = Modifier.fillMaxWidth().padding(horizontal = 32.dp, vertical = 8.dp)
            ) {
                Text("Manage Employees")
            }
            
            Button(
                onClick = { onNavigate(com.example.connect.HRAttendanceScreen) },
                modifier = Modifier.fillMaxWidth().padding(horizontal = 32.dp, vertical = 8.dp)
            ) {
                Text("View Company Attendance")
            }
            
            Button(
                onClick = { onNavigate(com.example.connect.HRLeavesScreen) },
                modifier = Modifier.fillMaxWidth().padding(horizontal = 32.dp, vertical = 8.dp)
            ) {
                Text("Approve Leaves")
            }
            
            Spacer(modifier = Modifier.weight(1f))
            
            Button(onClick = { onNavigate(Landing) }, colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error)) {
                Text("Logout")
            }
        }
    }
}
