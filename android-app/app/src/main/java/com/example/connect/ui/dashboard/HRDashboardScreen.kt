package com.example.connect.ui.dashboard

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.navigation3.runtime.NavKey
import com.example.connect.Landing
import com.example.connect.network.HRAnalyticsResponse
import com.example.connect.network.RetrofitClient
import com.example.connect.network.SessionManager
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HRDashboardScreen(onNavigate: (NavKey) -> Unit) {
    var analytics by remember { mutableStateOf<HRAnalyticsResponse?>(null) }
    val coroutineScope = rememberCoroutineScope()

    LaunchedEffect(Unit) {
        val token = SessionManager.token
        if (token != null) {
            try {
                val response = RetrofitClient.instance.getHRAnalytics("Bearer $token")
                if (response.isSuccessful) {
                    analytics = response.body()
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Connect HR", fontWeight = FontWeight.Bold) },
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
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text("Dashboard Overview", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold, modifier = Modifier.align(Alignment.Start))
            Spacer(modifier = Modifier.height(16.dp))

            // Analytics Cards
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                AnalyticsCard(title = "Total Employees", value = analytics?.totalEmployees?.toString() ?: "--", modifier = Modifier.weight(1f))
                Spacer(modifier = Modifier.width(8.dp))
                AnalyticsCard(title = "Present Today", value = analytics?.todayAttendance?.toString() ?: "--", modifier = Modifier.weight(1f))
                Spacer(modifier = Modifier.width(8.dp))
                AnalyticsCard(title = "Pending Leaves", value = analytics?.pendingLeaves?.toString() ?: "--", modifier = Modifier.weight(1f))
            }

            Spacer(modifier = Modifier.height(32.dp))
            Text("Quick Actions", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold, modifier = Modifier.align(Alignment.Start))
            Spacer(modifier = Modifier.height(16.dp))
            
            ActionCard("Manage Employees", "Add, edit, or remove company employees", onClick = { onNavigate(com.example.connect.HREmployeesScreen) })
            Spacer(modifier = Modifier.height(12.dp))
            ActionCard("Company Attendance", "View all employee punch-in records", onClick = { onNavigate(com.example.connect.HRAttendanceScreen) })
            Spacer(modifier = Modifier.height(12.dp))
            ActionCard("Leave Approvals", "Review and manage leave requests", onClick = { onNavigate(com.example.connect.HRLeavesScreen) })
            
            Spacer(modifier = Modifier.weight(1f))
            
            Button(
                onClick = {
                    SessionManager.token = null
                    onNavigate(Landing) 
                },
                colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error),
                modifier = Modifier.fillMaxWidth().height(56.dp)
            ) {
                Text("Logout", style = MaterialTheme.typography.titleMedium)
            }
        }
    }
}

@Composable
fun AnalyticsCard(title: String, value: String, modifier: Modifier = Modifier) {
    Card(
        modifier = modifier.aspectRatio(1f),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer),
        shape = RoundedCornerShape(16.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier.fillMaxSize().padding(12.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(text = value, style = MaterialTheme.typography.displaySmall, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.onPrimaryContainer)
            Spacer(modifier = Modifier.height(8.dp))
            Text(text = title, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onPrimaryContainer, textAlign = androidx.compose.ui.text.style.TextAlign.Center)
        }
    }
}

@Composable
fun ActionCard(title: String, subtitle: String, onClick: () -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth().clickable { onClick() },
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
        shape = RoundedCornerShape(12.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(text = title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
            Spacer(modifier = Modifier.height(4.dp))
            Text(text = subtitle, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}
