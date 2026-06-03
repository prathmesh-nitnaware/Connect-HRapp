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
import com.example.connect.network.HRLeave
import com.example.connect.network.HRLeaveUpdateRequest
import com.example.connect.network.RetrofitClient
import com.example.connect.network.SessionManager
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HRLeavesScreen(onNavigate: (NavKey) -> Unit) {
    var leaves by remember { mutableStateOf<List<HRLeave>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }
    var statusMessage by remember { mutableStateOf("") }
    val coroutineScope = rememberCoroutineScope()

    LaunchedEffect(Unit) {
        try {
            val token = SessionManager.token ?: ""
            val response = RetrofitClient.instance.getHRLeaves(token)
            if (response.isSuccessful) {
                leaves = response.body() ?: emptyList()
            } else {
                statusMessage = "Failed to load leaves"
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
                title = { Text("Approve Leaves") },
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
                    items(leaves) { leave ->
                        LeaveItem(leave) { newStatus ->
                            coroutineScope.launch {
                                try {
                                    val token = SessionManager.token ?: ""
                                    RetrofitClient.instance.updateHRLeave(token, leave.id, HRLeaveUpdateRequest(newStatus))
                                    leaves = leaves.map { if (it.id == leave.id) it.copy(status = newStatus) else it }
                                } catch (e: Exception) {
                                    statusMessage = "Error updating: ${e.message}"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun LeaveItem(leave: HRLeave, onUpdateStatus: (String) -> Unit) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text("${leave.employee_name} - ${leave.date}", style = MaterialTheme.typography.titleMedium)
            Text("Type: ${leave.leave_type}", style = MaterialTheme.typography.bodyMedium)
            Text("Reason: ${leave.reason}", style = MaterialTheme.typography.bodyMedium)
            Text("Status: ${leave.status}", style = MaterialTheme.typography.bodyMedium, color = if (leave.status == "Pending") MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.primary)
            
            Spacer(modifier = Modifier.height(8.dp))
            
            if (leave.status == "Pending") {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Button(onClick = { onUpdateStatus("Approved") }, modifier = Modifier.weight(1f)) {
                        Text("Approve")
                    }
                    Button(onClick = { onUpdateStatus("Rejected") }, modifier = Modifier.weight(1f), colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error)) {
                        Text("Reject")
                    }
                }
            }
        }
    }
}
