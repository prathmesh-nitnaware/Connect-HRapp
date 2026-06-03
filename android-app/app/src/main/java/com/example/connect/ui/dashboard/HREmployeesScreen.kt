package com.example.connect.ui.dashboard

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.navigation3.runtime.NavKey
import com.example.connect.network.HREmployee
import com.example.connect.network.HREmployeeUpdateRequest
import com.example.connect.network.RetrofitClient
import com.example.connect.network.SessionManager
import com.example.connect.network.SignupRequest
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HREmployeesScreen(onNavigate: (NavKey) -> Unit) {
    var employees by remember { mutableStateOf<List<HREmployee>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }
    var statusMessage by remember { mutableStateOf("") }
    var showHireDialog by remember { mutableStateOf(false) }
    val coroutineScope = rememberCoroutineScope()

    fun loadEmployees() {
        coroutineScope.launch {
            isLoading = true
            try {
                val token = SessionManager.token ?: ""
                val response = RetrofitClient.instance.getHREmployees(token)
                if (response.isSuccessful) {
                    employees = response.body() ?: emptyList()
                } else {
                    statusMessage = "Failed to load employees"
                }
            } catch (e: Exception) {
                statusMessage = "Error: ${e.message}"
            } finally {
                isLoading = false
            }
        }
    }

    LaunchedEffect(Unit) {
        loadEmployees()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Manage Employees", fontWeight = FontWeight.Bold) },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    titleContentColor = MaterialTheme.colorScheme.onPrimary,
                )
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = { showHireDialog = true },
                containerColor = MaterialTheme.colorScheme.secondary,
                contentColor = MaterialTheme.colorScheme.onSecondary,
                shape = RoundedCornerShape(16.dp)
            ) {
                Text("+", style = MaterialTheme.typography.headlineMedium)
            }
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
                    items(employees) { employee ->
                        EmployeeItem(
                            employee = employee,
                            onUpdateDept = { newDept ->
                                coroutineScope.launch {
                                    try {
                                        val token = SessionManager.token ?: ""
                                        RetrofitClient.instance.updateHREmployee(token, employee.id, HREmployeeUpdateRequest(newDept, null))
                                        employees = employees.map { if (it.id == employee.id) it.copy(department = newDept) else it }
                                    } catch (e: Exception) {
                                        statusMessage = "Error updating: ${e.message}"
                                    }
                                }
                            },
                            onDelete = {
                                coroutineScope.launch {
                                    try {
                                        val token = SessionManager.token ?: ""
                                        RetrofitClient.instance.deleteHREmployee(token, employee.id)
                                        employees = employees.filter { it.id != employee.id }
                                    } catch (e: Exception) {
                                        statusMessage = "Error deleting: ${e.message}"
                                    }
                                }
                            }
                        )
                    }
                }
            }
        }
    }

    if (showHireDialog) {
        var newName by remember { mutableStateOf("") }
        var newEmail by remember { mutableStateOf("") }
        var newPassword by remember { mutableStateOf("") }
        var newRole by remember { mutableStateOf("employee") }

        AlertDialog(
            onDismissRequest = { showHireDialog = false },
            title = { Text("Hire New Employee", fontWeight = FontWeight.Bold) },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedTextField(value = newName, onValueChange = { newName = it }, label = { Text("Name") }, modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(12.dp))
                    OutlinedTextField(value = newEmail, onValueChange = { newEmail = it }, label = { Text("Email") }, modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(12.dp))
                    OutlinedTextField(value = newPassword, onValueChange = { newPassword = it }, label = { Text("Password") }, modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(12.dp))
                    OutlinedTextField(value = newRole, onValueChange = { newRole = it }, label = { Text("Role (employee/HR)") }, modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(12.dp))
                }
            },
            confirmButton = {
                Button(onClick = {
                    showHireDialog = false
                    coroutineScope.launch {
                        try {
                            val token = SessionManager.token ?: ""
                            val res = RetrofitClient.instance.createHREmployee(token, SignupRequest(newName, newEmail, newPassword, newRole))
                            if (res.isSuccessful) {
                                loadEmployees()
                            } else {
                                statusMessage = "Failed to hire employee"
                            }
                        } catch (e: Exception) {
                            statusMessage = "Error hiring: ${e.message}"
                        }
                    }
                }, shape = RoundedCornerShape(12.dp)) { Text("Hire") }
            },
            dismissButton = {
                TextButton(onClick = { showHireDialog = false }) { Text("Cancel") }
            }
        )
    }
}

@Composable
fun EmployeeItem(employee: HREmployee, onUpdateDept: (String) -> Unit, onDelete: () -> Unit) {
    var expanded by remember { mutableStateOf(false) }
    val departments = listOf("IT", "HR", "Sales", "Marketing", "Engineering", "Unassigned")
    
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    modifier = Modifier
                        .size(48.dp)
                        .clip(CircleShape)
                        .background(MaterialTheme.colorScheme.primary),
                    contentAlignment = Alignment.Center
                ) {
                    Text(employee.name.take(1).uppercase(), color = MaterialTheme.colorScheme.onPrimary, style = MaterialTheme.typography.titleLarge)
                }
                Spacer(modifier = Modifier.width(16.dp))
                Column {
                    Text(employee.name, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                    Text(employee.email, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            Spacer(modifier = Modifier.height(16.dp))
            
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                Surface(
                    color = MaterialTheme.colorScheme.primaryContainer,
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Text(employee.department, modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onPrimaryContainer)
                }
                
                Row {
                    Box {
                        TextButton(onClick = { expanded = true }) {
                            Text("Change Dept")
                        }
                        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
                            departments.forEach { dept ->
                                DropdownMenuItem(
                                    text = { Text(dept) },
                                    onClick = { expanded = false; onUpdateDept(dept) }
                                )
                            }
                        }
                    }
                    TextButton(onClick = onDelete, colors = ButtonDefaults.textButtonColors(contentColor = MaterialTheme.colorScheme.error)) {
                        Text("Delete")
                    }
                }
            }
        }
    }
}
