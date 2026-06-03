package com.example.connect.ui.dashboard

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
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
                title = { Text("Approve Leaves", fontWeight = FontWeight.Bold) },
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
                .background(MaterialTheme.colorScheme.background)
        ) {
            if (isLoading) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }
            } else if (statusMessage.isNotEmpty()) {
                Box(modifier = Modifier.fillMaxSize().padding(16.dp), contentAlignment = Alignment.Center) {
                    Text(statusMessage, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodyLarge)
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
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
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                Text(leave.employee_name, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                Surface(
                    color = if (leave.status == "Pending") MaterialTheme.colorScheme.errorContainer else MaterialTheme.colorScheme.primaryContainer,
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Text(leave.status, modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp), style = MaterialTheme.typography.bodySmall, color = if (leave.status == "Pending") MaterialTheme.colorScheme.onErrorContainer else MaterialTheme.colorScheme.onPrimaryContainer)
                }
            }
            Spacer(modifier = Modifier.height(4.dp))
            Text("${leave.leave_type} - ${leave.date}", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Spacer(modifier = Modifier.height(8.dp))
            Text(leave.reason, style = MaterialTheme.typography.bodyMedium)
            
            if (leave.status == "Pending") {
                Spacer(modifier = Modifier.height(16.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    Button(onClick = { onUpdateStatus("Approved") }, modifier = Modifier.weight(1f), shape = RoundedCornerShape(12.dp)) {
                        Text("Approve")
                    }
                    Button(onClick = { onUpdateStatus("Rejected") }, modifier = Modifier.weight(1f), colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error), shape = RoundedCornerShape(12.dp)) {
                        Text("Reject")
                    }
                }
            }
        }
    }
}
