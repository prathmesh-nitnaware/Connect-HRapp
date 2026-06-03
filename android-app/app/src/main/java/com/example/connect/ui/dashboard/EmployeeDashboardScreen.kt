package com.example.connect.ui.dashboard

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.navigation3.runtime.NavKey
import com.example.connect.Landing
import com.example.connect.network.AttendanceRequest
import com.example.connect.network.LeaveRequest
import com.example.connect.network.RetrofitClient
import com.example.connect.network.SessionManager
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EmployeeDashboardScreen(onNavigate: (NavKey) -> Unit) {
    var statusMessage by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }
    val coroutineScope = rememberCoroutineScope()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Connect - Employee Dashboard") },
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
            Text("Welcome to Connect", style = MaterialTheme.typography.headlineMedium)
            Spacer(modifier = Modifier.height(32.dp))
            
            if (statusMessage.isNotEmpty()) {
                Text(text = statusMessage, color = MaterialTheme.colorScheme.primary)
                Spacer(modifier = Modifier.height(16.dp))
            }
            
            if (isLoading) {
                CircularProgressIndicator()
                Spacer(modifier = Modifier.height(16.dp))
            }

            // Attendance Section
            Card(
                modifier = Modifier.fillMaxWidth(),
                elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
            ) {
                Column(modifier = Modifier.padding(16.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                    Text("Attendance", style = MaterialTheme.typography.titleLarge)
                    Spacer(modifier = Modifier.height(16.dp))
                    Row(horizontalArrangement = Arrangement.SpaceEvenly, modifier = Modifier.fillMaxWidth()) {
                        Button(
                            enabled = !isLoading,
                            onClick = {
                            isLoading = true
                            coroutineScope.launch {
                                try {
                                    val token = SessionManager.token ?: ""
                                    val response = RetrofitClient.instance.punchAttendance(token, AttendanceRequest("punch_in"))
                                    statusMessage = response.body()?.message ?: "Punch In Failed"
                                } catch (e: Exception) {
                                    statusMessage = "Error: ${e.message}"
                                } finally { isLoading = false }
                            }
                        }) {
                            Text("Punch In")
                        }
                        Button(
                            enabled = !isLoading,
                            onClick = {
                            isLoading = true
                            coroutineScope.launch {
                                try {
                                    val token = SessionManager.token ?: ""
                                    val response = RetrofitClient.instance.punchAttendance(token, AttendanceRequest("punch_out"))
                                    statusMessage = response.body()?.message ?: "Punch Out Failed"
                                } catch (e: Exception) {
                                    statusMessage = "Error: ${e.message}"
                                } finally { isLoading = false }
                            }
                        }) {
                            Text("Punch Out")
                        }
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Leave Section
            Card(
                modifier = Modifier.fillMaxWidth(),
                elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
            ) {
                Column(modifier = Modifier.padding(16.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                    Text("Leave Management", style = MaterialTheme.typography.titleLarge)
                    Spacer(modifier = Modifier.height(16.dp))
                    Button(
                        enabled = !isLoading,
                        onClick = {
                        isLoading = true
                        coroutineScope.launch {
                            try {
                                val token = SessionManager.token ?: ""
                                val today = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
                                val response = RetrofitClient.instance.applyLeave(token, LeaveRequest("Sick Leave", "Not feeling well", today))
                                statusMessage = response.body()?.message ?: "Leave Application Failed"
                            } catch (e: Exception) {
                                statusMessage = "Error: ${e.message}"
                            } finally { isLoading = false }
                        }
                    }) {
                        Text("Apply for Leave (Test)")
                    }
                }
            }
            
            Spacer(modifier = Modifier.weight(1f))
            
            Button(onClick = { 
                SessionManager.token = null
                onNavigate(Landing) 
            }, colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error)) {
                Text("Logout")
            }
        }
    }
}
