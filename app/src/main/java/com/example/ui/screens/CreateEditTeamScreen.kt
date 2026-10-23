package com.example.ui.screens

import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.model.ProjectCategory
import com.example.data.model.Team
import com.example.data.repository.ManitRepository
import com.example.ui.components.ManitVerificationBadge
import com.example.ui.components.SkillChip
import com.example.ui.components.StatusPill
import com.example.ui.theme.*

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun CreateEditTeamScreen(
    editingTeamId: String? = null,
    onFinished: () -> Unit,
    onBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    val teams by ManitRepository.teams.collectAsState()
    val currentUser by ManitRepository.currentUser.collectAsState()
    val existingTeam = remember(editingTeamId, teams) {
        if (editingTeamId != null) teams.find { it.id == editingTeamId } else null
    }

    // Step state (0: Project Info, 1: Tech Stack, 2: Roster & WhatsApp, 3: Live Preview)
    var currentStep by remember { mutableStateOf(0) }

    var title by remember { mutableStateOf(existingTeam?.title ?: "") }
    var eventName by remember { mutableStateOf(existingTeam?.eventName ?: "SIH 2026") }
    var description by remember { mutableStateOf(existingTeam?.description ?: "") }
    var selectedCategory by remember { mutableStateOf(existingTeam?.projectCategory ?: ProjectCategory.HACKATHON) }
    var maxTeamSize by remember { mutableStateOf(existingTeam?.maxTeamSize ?: 4) }
    var isRecruiting by remember { mutableStateOf(existingTeam?.isRecruiting ?: true) }
    var whatsappLink by remember { mutableStateOf(existingTeam?.whatsappGroupLink ?: "") }

    var skillInput by remember { mutableStateOf("") }
    var requiredSkills by remember {
        mutableStateOf(existingTeam?.requiredSkills ?: listOf("Kotlin", "UI/UX", "Python"))
    }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    val popularSkills = listOf("Kotlin", "Jetpack Compose", "Python", "PyTorch", "React", "Next.js", "Solidity", "Figma", "Node.js", "C++", "ROS2", "Docker", "Flutter")

    Scaffold(
        topBar = {
            Surface(
                color = MidnightNavy,
                modifier = Modifier
                    .fillMaxWidth()
                    .statusBarsPadding()
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 8.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            IconButton(onClick = onBack, modifier = Modifier.testTag("create_team_back_btn")) {
                                Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = TextPrimary)
                            }
                            Text(
                                text = if (existingTeam != null) "Edit Project Team" else "Team Creation Studio",
                                color = TextPrimary,
                                fontSize = 17.sp,
                                fontWeight = FontWeight.Bold
                            )
                        }

                        Text(
                            text = "Step ${currentStep + 1} of 4",
                            color = CyanLight,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    // Step Progress Indicator Bar
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        for (i in 0..3) {
                            val isActive = i <= currentStep
                            Box(
                                modifier = Modifier
                                    .weight(1f)
                                    .height(4.dp)
                                    .clip(RoundedCornerShape(2.dp))
                                    .background(if (isActive) ElectricVioletLight else CharcoalBorder)
                            )
                        }
                    }
                }
            }
        },
        bottomBar = {
            Surface(
                color = CharcoalSurface,
                border = androidx.compose.foundation.BorderStroke(1.dp, CharcoalBorder),
                modifier = Modifier
                    .fillMaxWidth()
                    .navigationBarsPadding()
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 12.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    if (currentStep > 0) {
                        OutlinedButton(
                            onClick = { currentStep-- },
                            shape = RoundedCornerShape(10.dp),
                            border = androidx.compose.foundation.BorderStroke(1.dp, CharcoalBorder)
                        ) {
                            Text("Previous", color = TextSecondary)
                        }
                    } else {
                        Spacer(modifier = Modifier.width(1.dp))
                    }

                    if (currentStep < 3) {
                        Button(
                            onClick = {
                                errorMessage = null
                                when (currentStep) {
                                    0 -> {
                                        if (title.isBlank()) {
                                            errorMessage = "Please enter a project title."
                                            return@Button
                                        }
                                        currentStep++
                                    }
                                    1 -> {
                                        if (requiredSkills.isEmpty()) {
                                            errorMessage = "Please select at least 1 required skill."
                                            return@Button
                                        }
                                        currentStep++
                                    }
                                    2 -> {
                                        currentStep++
                                    }
                                }
                            },
                            colors = ButtonDefaults.buttonColors(containerColor = ElectricViolet),
                            shape = RoundedCornerShape(10.dp),
                            modifier = Modifier.testTag("step_next_btn")
                        ) {
                            Text("Next Step", fontWeight = FontWeight.Bold)
                            Spacer(modifier = Modifier.width(4.dp))
                            Icon(Icons.Default.ArrowForward, contentDescription = null, modifier = Modifier.size(16.dp))
                        }
                    } else {
                        // Final Publish / Save Button
                        Button(
                            onClick = {
                                if (existingTeam != null) {
                                    ManitRepository.updateTeam(
                                        existingTeam.copy(
                                            title = title.trim(),
                                            description = description.trim(),
                                            eventName = eventName.trim(),
                                            projectCategory = selectedCategory,
                                            maxTeamSize = maxTeamSize,
                                            requiredSkills = requiredSkills,
                                            isRecruiting = isRecruiting,
                                            whatsappGroupLink = whatsappLink.trim().ifBlank { null }
                                        )
                                    )
                                    onFinished()
                                } else {
                                    val res = ManitRepository.createTeam(
                                        title = title,
                                        description = description,
                                        category = selectedCategory,
                                        eventName = eventName,
                                        skills = requiredSkills,
                                        maxSize = maxTeamSize,
                                        whatsappLink = whatsappLink
                                    )
                                    res.onSuccess {
                                        onFinished()
                                    }.onFailure {
                                        errorMessage = it.message ?: "Failed to create team."
                                    }
                                }
                            },
                            colors = ButtonDefaults.buttonColors(containerColor = ElectricViolet),
                            shape = RoundedCornerShape(10.dp),
                            modifier = Modifier.testTag("save_team_btn")
                        ) {
                            Icon(Icons.Default.RocketLaunch, contentDescription = null, tint = White, modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(if (existingTeam != null) "Update Team" else "Launch Project", fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }
        },
        containerColor = MidnightNavy
    ) { innerPadding ->
        Column(
            modifier = modifier
                .fillMaxSize()
                .padding(innerPadding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            if (errorMessage != null) {
                Card(
                    colors = CardDefaults.cardColors(containerColor = CoralSubtle),
                    shape = RoundedCornerShape(10.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        modifier = Modifier.padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Icon(Icons.Default.ErrorOutline, contentDescription = null, tint = CoralLight)
                        Text(text = errorMessage ?: "", color = CoralLight, fontSize = 12.sp)
                    }
                }
            }

            // Step Content
            when (currentStep) {
                0 -> {
                    // Stage 1: Project Information
                    Text("1. Project Information", color = TextPrimary, fontSize = 18.sp, fontWeight = FontWeight.ExtraBold)
                    Text("Give your team an inspiring title and set the target competition or event.", color = TextSecondary, fontSize = 12.sp)

                    OutlinedTextField(
                        value = title,
                        onValueChange = { title = it },
                        label = { Text("Project / Team Title *") },
                        placeholder = { Text("e.g. KisanDrishti AI Scanner") },
                        singleLine = true,
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = ElectricVioletLight,
                            unfocusedBorderColor = CharcoalBorder,
                            focusedTextColor = TextPrimary,
                            unfocusedTextColor = TextPrimary
                        ),
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("team_title_input")
                    )

                    OutlinedTextField(
                        value = eventName,
                        onValueChange = { eventName = it },
                        label = { Text("Event / Hackathon / Course *") },
                        placeholder = { Text("e.g. Smart India Hackathon, Version '26, Minor Project") },
                        singleLine = true,
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = CyanAccent,
                            unfocusedBorderColor = CharcoalBorder,
                            focusedTextColor = TextPrimary,
                            unfocusedTextColor = TextPrimary
                        ),
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("team_event_input")
                    )

                    Text("Project Category", color = TextPrimary, fontSize = 14.sp, fontWeight = FontWeight.Bold)
                    FlowRow(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        ProjectCategory.values().forEach { cat ->
                            val isSelected = selectedCategory == cat
                            Box(
                                modifier = Modifier
                                    .clip(RoundedCornerShape(10.dp))
                                    .background(if (isSelected) ElectricVioletSubtle else CharcoalSurfaceVariant)
                                    .border(1.dp, if (isSelected) ElectricVioletLight else CharcoalBorder, RoundedCornerShape(10.dp))
                                    .clickable { selectedCategory = cat }
                                    .padding(horizontal = 12.dp, vertical = 8.dp)
                            ) {
                                Text(
                                    text = cat.displayName,
                                    color = if (isSelected) ElectricVioletLight else TextSecondary,
                                    fontSize = 12.sp,
                                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                                )
                            }
                        }
                    }

                    OutlinedTextField(
                        value = description,
                        onValueChange = { description = it },
                        label = { Text("Project Vision & Problem Statement") },
                        placeholder = { Text("Explain what you are building and why.") },
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = ElectricVioletLight,
                            unfocusedBorderColor = CharcoalBorder,
                            focusedTextColor = TextPrimary,
                            unfocusedTextColor = TextPrimary
                        ),
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(110.dp)
                            .testTag("team_desc_input")
                    )
                }

                1 -> {
                    // Stage 2: Tech Stack & Skills
                    Text("2. Required Skills & Roles", color = TextPrimary, fontSize = 18.sp, fontWeight = FontWeight.ExtraBold)
                    Text("Specify the technical proficiencies needed on your squad.", color = TextSecondary, fontSize = 12.sp)

                    // Selected Skills
                    Card(
                        shape = RoundedCornerShape(14.dp),
                        colors = CardDefaults.cardColors(containerColor = CharcoalSurface),
                        border = androidx.compose.foundation.BorderStroke(1.dp, CharcoalBorder),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(14.dp),
                            verticalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            Text("Current Required Skills (${requiredSkills.size}):", color = TextLavender, fontSize = 13.sp, fontWeight = FontWeight.Bold)

                            FlowRow(
                                horizontalArrangement = Arrangement.spacedBy(6.dp),
                                verticalArrangement = Arrangement.spacedBy(6.dp)
                            ) {
                                requiredSkills.forEach { skill ->
                                    Row(
                                        modifier = Modifier
                                            .clip(RoundedCornerShape(8.dp))
                                            .background(ElectricVioletSubtle)
                                            .border(1.dp, ElectricVioletLight, RoundedCornerShape(8.dp))
                                            .padding(horizontal = 8.dp, vertical = 4.dp),
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                                    ) {
                                        Text(skill, color = ElectricVioletLight, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                                        Icon(
                                            Icons.Default.Close,
                                            contentDescription = "Remove $skill",
                                            tint = ElectricVioletLight,
                                            modifier = Modifier
                                                .size(14.dp)
                                                .clickable { requiredSkills = requiredSkills - skill }
                                        )
                                    }
                                }
                            }

                            // Custom Input
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                OutlinedTextField(
                                    value = skillInput,
                                    onValueChange = { skillInput = it },
                                    placeholder = { Text("Add custom skill...") },
                                    singleLine = true,
                                    modifier = Modifier.weight(1f)
                                )
                                Button(
                                    onClick = {
                                        if (skillInput.isNotBlank() && !requiredSkills.contains(skillInput.trim())) {
                                            requiredSkills = requiredSkills + skillInput.trim()
                                            skillInput = ""
                                        }
                                    },
                                    colors = ButtonDefaults.buttonColors(containerColor = ElectricViolet),
                                    shape = RoundedCornerShape(10.dp)
                                ) {
                                    Text("Add")
                                }
                            }
                        }
                    }

                    Text("Popular Skill Suggestions:", color = TextMuted, fontSize = 12.sp)
                    FlowRow(
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                        verticalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        popularSkills.filter { !requiredSkills.contains(it) }.forEach { rec ->
                            Box(
                                modifier = Modifier
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(CharcoalSurfaceVariant)
                                    .clickable { requiredSkills = requiredSkills + rec }
                                    .padding(horizontal = 10.dp, vertical = 6.dp)
                            ) {
                                Text("+ $rec", color = CyanLight, fontSize = 12.sp)
                            }
                        }
                    }
                }

                2 -> {
                    // Stage 3: Roster Capacity & WhatsApp Link
                    Text("3. Roster Size & Coordination", color = TextPrimary, fontSize = 18.sp, fontWeight = FontWeight.ExtraBold)
                    Text("Control team capacity and link your external WhatsApp team room.", color = TextSecondary, fontSize = 12.sp)

                    Card(
                        shape = RoundedCornerShape(14.dp),
                        colors = CardDefaults.cardColors(containerColor = CharcoalSurface),
                        border = androidx.compose.foundation.BorderStroke(1.dp, CharcoalBorder),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(16.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Column {
                                Text("Target Team Capacity", color = TextPrimary, fontSize = 14.sp, fontWeight = FontWeight.Bold)
                                Text("Includes you as lead", color = TextSecondary, fontSize = 11.sp)
                            }
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(10.dp)
                            ) {
                                IconButton(
                                    onClick = { if (maxTeamSize > 2) maxTeamSize-- },
                                    enabled = maxTeamSize > 2
                                ) {
                                    Icon(Icons.Default.RemoveCircleOutline, contentDescription = "Decrease", tint = if (maxTeamSize > 2) ElectricVioletLight else TextMuted)
                                }
                                Text("$maxTeamSize", color = TextPrimary, fontSize = 18.sp, fontWeight = FontWeight.Bold)
                                IconButton(
                                    onClick = { if (maxTeamSize < 10) maxTeamSize++ },
                                    enabled = maxTeamSize < 10
                                ) {
                                    Icon(Icons.Default.AddCircleOutline, contentDescription = "Increase", tint = if (maxTeamSize < 10) ElectricVioletLight else TextMuted)
                                }
                            }
                        }
                    }

                    OutlinedTextField(
                        value = whatsappLink,
                        onValueChange = { whatsappLink = it },
                        label = { Text("WhatsApp Group Coordination Link") },
                        placeholder = { Text("https://chat.whatsapp.com/...") },
                        singleLine = true,
                        leadingIcon = { Icon(Icons.Default.Share, contentDescription = null, tint = StatusSuccess) },
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = StatusSuccess,
                            unfocusedBorderColor = CharcoalBorder,
                            focusedTextColor = TextPrimary,
                            unfocusedTextColor = TextPrimary
                        ),
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("team_whatsapp_input")
                    )

                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(14.dp))
                            .background(CharcoalSurface)
                            .padding(14.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Column {
                            Text("Actively Recruiting", color = TextPrimary, fontSize = 14.sp, fontWeight = FontWeight.Bold)
                            Text(if (isRecruiting) "Accepting applications from campus peers" else "Roster locked", color = TextSecondary, fontSize = 11.sp)
                        }
                        Switch(
                            checked = isRecruiting,
                            onCheckedChange = { isRecruiting = it },
                            colors = SwitchDefaults.colors(checkedThumbColor = White, checkedTrackColor = ElectricViolet)
                        )
                    }
                }

                3 -> {
                    // Stage 4: Live Preview & Launch
                    Text("4. Review & Live Preview", color = TextPrimary, fontSize = 18.sp, fontWeight = FontWeight.ExtraBold)
                    Text("This is exactly how students and hackathon peers will see your project in the Discover Hub:", color = TextSecondary, fontSize = 12.sp)

                    // High fidelity card preview
                    Card(
                        shape = RoundedCornerShape(18.dp),
                        colors = CardDefaults.cardColors(containerColor = CharcoalSurface),
                        border = androidx.compose.foundation.BorderStroke(1.5.dp, ElectricVioletLight),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(16.dp),
                            verticalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Box(
                                    modifier = Modifier
                                        .clip(RoundedCornerShape(6.dp))
                                        .background(CyanSubtle)
                                        .padding(horizontal = 8.dp, vertical = 3.dp)
                                ) {
                                    Text(eventName.ifBlank { "Campus Hackathon" }, color = CyanLight, fontSize = 11.sp, fontWeight = FontWeight.Bold)
                                }

                                StatusPill(vacancies = (maxTeamSize - 1).coerceAtLeast(0), isRecruiting = isRecruiting)
                            }

                            Text(
                                text = title.ifBlank { "Untitled Project" },
                                color = TextPrimary,
                                fontSize = 17.sp,
                                fontWeight = FontWeight.Bold
                            )

                            Text(
                                text = description.ifBlank { "No description entered." },
                                color = TextSecondary,
                                fontSize = 12.sp,
                                lineHeight = 17.sp
                            )

                            FlowRow(
                                horizontalArrangement = Arrangement.spacedBy(6.dp),
                                verticalArrangement = Arrangement.spacedBy(6.dp)
                            ) {
                                requiredSkills.forEach { skill ->
                                    SkillChip(skill = skill, isSelected = true)
                                }
                            }

                            Divider(color = CharcoalDivider)

                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                Box(
                                    modifier = Modifier
                                        .size(28.dp)
                                        .clip(CircleShape)
                                        .background(Brush.linearGradient(listOf(ElectricViolet, MagentaAccent))),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text(
                                        text = (currentUser?.fullName?.take(1) ?: "U").uppercase(),
                                        color = White,
                                        fontSize = 12.sp,
                                        fontWeight = FontWeight.Bold
                                    )
                                }
                                Text("Lead: ${currentUser?.fullName ?: "You"}", color = TextLavender, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                                ManitVerificationBadge(isVerified = currentUser?.isManitVerified ?: true)
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(20.dp))
        }
    }
}
