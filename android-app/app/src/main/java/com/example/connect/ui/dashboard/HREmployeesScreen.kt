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
                title = { Text("Manage Employees") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    titleContentColor = MaterialTheme.colorScheme.onPrimary,
                )
            )
        },
        floatingActionButton = {
            FloatingActionButton(onClick = { showHireDialog = true }) {
                Text("+")
            }
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
            title = { Text("Hire New Employee") },
            text = {
                Column {
                    OutlinedTextField(value = newName, onValueChange = { newName = it }, label = { Text("Name") }, modifier = Modifier.fillMaxWidth())
                    OutlinedTextField(value = newEmail, onValueChange = { newEmail = it }, label = { Text("Email") }, modifier = Modifier.fillMaxWidth())
                    OutlinedTextField(value = newPassword, onValueChange = { newPassword = it }, label = { Text("Password") }, modifier = Modifier.fillMaxWidth())
                    OutlinedTextField(value = newRole, onValueChange = { newRole = it }, label = { Text("Role (employee/HR)") }, modifier = Modifier.fillMaxWidth())
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
                                loadEmployees() // Refresh the list
                            } else {
                                statusMessage = "Failed to hire employee"
                            }
                        } catch (e: Exception) {
                            statusMessage = "Error hiring: ${e.message}"
                        }
                    }
                }) { Text("Hire") }
            },
            dismissButton = {
                Button(onClick = { showHireDialog = false }) { Text("Cancel") }
            }
        )
    }
}

@Composable
fun EmployeeItem(employee: HREmployee, onUpdateDept: (String) -> Unit, onDelete: () -> Unit) {
    var expanded by remember { mutableStateOf(false) }
    val departments = listOf("IT", "HR", "Sales", "Marketing", "Engineering", "Unassigned")
    
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(employee.name, style = MaterialTheme.typography.titleMedium)
            Text(employee.email, style = MaterialTheme.typography.bodyMedium)
            Text("Role: ${employee.role}", style = MaterialTheme.typography.bodySmall)
            Spacer(modifier = Modifier.height(8.dp))
            
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("Dept: ${employee.department}", modifier = Modifier.weight(1f))
                Box {
                    Button(onClick = { expanded = true }) {
                        Text("Change Dept")
                    }
                    DropdownMenu(
                        expanded = expanded,
                        onDismissRequest = { expanded = false }
                    ) {
                        departments.forEach { dept ->
                            DropdownMenuItem(
                                text = { Text(dept) },
                                onClick = {
                                    expanded = false
                                    onUpdateDept(dept)
                                }
                            )
                        }
                    }
                }
                Spacer(modifier = Modifier.width(8.dp))
                Button(
                    onClick = onDelete,
                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error)
                ) {
                    Text("Delete")
                }
            }
        }
    }
}
