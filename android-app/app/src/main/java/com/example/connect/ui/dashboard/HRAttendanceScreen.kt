package com.example.connect.ui.dashboard

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.navigation3.runtime.NavKey
import com.example.connect.network.HRAttendanceRecord
import com.example.connect.network.RetrofitClient
import com.example.connect.network.SessionManager

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HRAttendanceScreen(onNavigate: (NavKey) -> Unit) {
    var records by remember { mutableStateOf<List<HRAttendanceRecord>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }
    var statusMessage by remember { mutableStateOf("") }

    LaunchedEffect(Unit) {
        try {
            val token = SessionManager.token ?: ""
            val response = RetrofitClient.instance.getHRAttendance(token)
            if (response.isSuccessful) {
                records = response.body() ?: emptyList()
            } else {
                statusMessage = "Failed to load attendance records"
            }
        } catch (e: Exception) {
            statusMessage = "Error: ${e.message}"
        } finally {
            isLoading = false
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Company Attendance") },
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
            if (isLoading) {
                CircularProgressIndicator()
            } else if (statusMessage.isNotEmpty()) {
                Text(statusMessage, color = MaterialTheme.colorScheme.error)
            } else {
                LazyColumn {
                    items(records) { record ->
                        AttendanceRecordItem(record)
                    }
                }
            }
        }
    }
}

@Composable
fun AttendanceRecordItem(record: HRAttendanceRecord) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text("${record.employee_name} - ${record.date}", style = MaterialTheme.typography.titleMedium)
            Spacer(modifier = Modifier.height(4.dp))
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text("In: ${if (record.punch_in.isNotEmpty()) record.punch_in else "--:--:--"}", style = MaterialTheme.typography.bodyMedium)
                Text("Out: ${if (record.punch_out.isNotEmpty()) record.punch_out else "--:--:--"}", style = MaterialTheme.typography.bodyMedium)
            }
        }
    }
}
