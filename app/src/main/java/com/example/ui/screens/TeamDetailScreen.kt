package com.example.ui.screens

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.model.RequestStatus
import com.example.data.model.TeamRole
import com.example.data.repository.ManitRepository
import com.example.ui.components.ManitVerificationBadge
import com.example.ui.components.RequestStatusBadge
import com.example.ui.components.SkillChip
import com.example.ui.components.StatusPill
import com.example.ui.theme.*

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun TeamDetailScreen(
    teamId: String,
    onBack: () -> Unit,
    onOpenTeamChat: (String, String) -> Unit,
    onEditTeam: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val teams by ManitRepository.teams.collectAsState()
    val team = teams.find { it.id == teamId }
    val currentUser by ManitRepository.currentUser.collectAsState()
    val joinRequests by ManitRepository.joinRequests.collectAsState()

    var showApplyDialog by remember { mutableStateOf(false) }
    var pitchNote by remember { mutableStateOf("") }
    var applyError by remember { mutableStateOf<String?>(null) }
    var showDeleteConfirmDialog by remember { mutableStateOf(false) }

    if (team == null) {
        Box(
            modifier = modifier
                .fillMaxSize()
                .background(MidnightNavy),
            contentAlignment = Alignment.Center
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text("Team not found", color = TextPrimary, fontSize = 16.sp)
                Spacer(modifier = Modifier.height(10.dp))
                Button(onClick = onBack) { Text("Go Back") }
            }
        }
        return
    }

    val isOwner = currentUser?.id == team.ownerId
    val isMember = team.members.any { it.userId == currentUser?.id }
    val myRequest = joinRequests.find { it.teamId == team.id && it.applicantId == currentUser?.id }

    Scaffold(
        topBar = {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(MidnightNavy)
                    .statusBarsPadding()
                    .padding(horizontal = 8.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    IconButton(onClick = onBack, modifier = Modifier.testTag("team_detail_back_btn")) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = TextPrimary)
                    }
                    Text(
                        text = "Team Overview",
                        color = TextPrimary,
                        fontSize = 17.sp,
                        fontWeight = FontWeight.Bold
                    )
                }

                if (isOwner) {
                    Row {
                        IconButton(onClick = { onEditTeam(team.id) }) {
                            Icon(Icons.Default.Edit, contentDescription = "Edit Team", tint = CyanLight)
                        }
                        IconButton(onClick = { showDeleteConfirmDialog = true }) {
                            Icon(Icons.Default.Delete, contentDescription = "Delete Team", tint = CoralLight)
                        }
                    }
                }
            }
        },
        bottomBar = {
            Surface(
                color = CharcoalSurface,
                tonalElevation = 6.dp,
                border = androidx.compose.foundation.BorderStroke(1.dp, CharcoalBorder),
                modifier = Modifier
                    .fillMaxWidth()
                    .navigationBarsPadding()
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 12.dp)
                ) {
                    when {
                        isOwner || isMember -> {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(10.dp)
                            ) {
                                Button(
                                    onClick = { onOpenTeamChat(team.id, team.title) },
                                    colors = ButtonDefaults.buttonColors(containerColor = ElectricViolet),
                                    shape = RoundedCornerShape(12.dp),
                                    modifier = Modifier
                                        .weight(1f)
                                        .height(48.dp)
                                        .testTag("team_open_chat_btn")
                                ) {
                                    Icon(Icons.Default.Chat, contentDescription = null, tint = White, modifier = Modifier.size(18.dp))
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Text("Team Chat", fontWeight = FontWeight.Bold)
                                }

                                if (!team.whatsappGroupLink.isNullOrBlank()) {
                                    Button(
                                        onClick = {
                                            try {
                                                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(team.whatsappGroupLink))
                                                context.startActivity(intent)
                                            } catch (e: Exception) {
                                                // Handle fallback
                                            }
                                        },
                                        colors = ButtonDefaults.buttonColors(containerColor = StatusSuccess),
                                        shape = RoundedCornerShape(12.dp),
                                        modifier = Modifier
                                            .height(48.dp)
                                            .testTag("team_whatsapp_btn")
                                    ) {
                                        Icon(Icons.Default.Share, contentDescription = null, tint = White, modifier = Modifier.size(16.dp))
                                        Spacer(modifier = Modifier.width(6.dp))
                                        Text("WhatsApp Hub", fontWeight = FontWeight.Bold)
                                    }
                                }
                            }
                        }
                        myRequest != null && myRequest.status == RequestStatus.PENDING -> {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Column {
                                    Text("Application Status", color = TextMuted, fontSize = 11.sp)
                                    RequestStatusBadge(status = myRequest.status)
                                }
                                OutlinedButton(
                                    onClick = {
                                        ManitRepository.withdrawJoinRequest(myRequest.id)
                                    },
                                    colors = ButtonDefaults.outlinedButtonColors(contentColor = CoralLight),
                                    border = androidx.compose.foundation.BorderStroke(1.dp, CoralLight),
                                    shape = RoundedCornerShape(10.dp),
                                    modifier = Modifier.testTag("team_withdraw_btn")
                                ) {
                                    Text("Withdraw Application")
                                }
                            }
                        }
                        myRequest != null && myRequest.status == RequestStatus.REJECTED -> {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text("Application was declined.", color = CoralLight, fontSize = 13.sp)
                                Button(
                                    onClick = { showApplyDialog = true },
                                    colors = ButtonDefaults.buttonColors(containerColor = ElectricViolet),
                                    shape = RoundedCornerShape(10.dp)
                                ) {
                                    Text("Re-Apply")
                                }
                            }
                        }
                        team.isFull -> {
                            Button(
                                onClick = {},
                                enabled = false,
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(48.dp)
                            ) {
                                Text("Team Roster Full")
                            }
                        }
                        else -> {
                            Button(
                                onClick = { showApplyDialog = true },
                                colors = ButtonDefaults.buttonColors(containerColor = ElectricViolet),
                                shape = RoundedCornerShape(12.dp),
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(48.dp)
                                    .testTag("team_apply_btn")
                            ) {
                                Icon(Icons.Default.PersonAdd, contentDescription = null, tint = White, modifier = Modifier.size(18.dp))
                                Spacer(modifier = Modifier.width(8.dp))
                                Text("Request to Join Team", fontWeight = FontWeight.Bold, fontSize = 15.sp)
                            }
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
            verticalArrangement = Arrangement.spacedBy(18.dp)
        ) {
            // Event & Category Header Banner
            Card(
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = CharcoalSurface),
                border = androidx.compose.foundation.BorderStroke(1.dp, CharcoalBorder),
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
                                .clip(RoundedCornerShape(8.dp))
                                .background(CyanSubtle)
                                .padding(horizontal = 8.dp, vertical = 4.dp)
                        ) {
                            Text(
                                text = team.eventName,
                                color = CyanLight,
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Bold
                            )
                        }

                        StatusPill(
                            vacancies = team.vacanciesLeft,
                            isRecruiting = team.isRecruiting
                        )
                    }

                    Text(
                        text = team.title,
                        color = TextPrimary,
                        fontSize = 20.sp,
                        fontWeight = FontWeight.ExtraBold,
                        lineHeight = 26.sp
                    )

                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Text(
                            text = "Category: ${team.projectCategory.displayName}",
                            color = MagentaLight,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.SemiBold
                        )
                        Text(
                            text = "• Capacity: ${team.members.size}/${team.maxTeamSize} members",
                            color = TextSecondary,
                            fontSize = 12.sp
                        )
                    }
                }
            }

            // Project Description
            Card(
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = CharcoalSurface),
                border = androidx.compose.foundation.BorderStroke(1.dp, CharcoalBorder),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = "Project Overview & Vision",
                        color = TextPrimary,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = team.description,
                        color = TextSecondary,
                        fontSize = 13.sp,
                        lineHeight = 20.sp
                    )
                }
            }

            // Required Skills
            Card(
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = CharcoalSurface),
                border = androidx.compose.foundation.BorderStroke(1.dp, CharcoalBorder),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Text(
                        text = "Required Skills & Roles",
                        color = TextPrimary,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Bold
                    )
                    FlowRow(
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                        verticalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        team.requiredSkills.forEach { skill ->
                            val myMatch = currentUser?.skills?.any { it.equals(skill, ignoreCase = true) } == true
                            SkillChip(skill = skill, isSelected = myMatch)
                        }
                    }
                }
            }

            // Current Team Roster
            Card(
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = CharcoalSurface),
                border = androidx.compose.foundation.BorderStroke(1.dp, CharcoalBorder),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = "Confirmed Roster (${team.members.size}/${team.maxTeamSize})",
                            color = TextPrimary,
                            fontSize = 15.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }

                    team.members.forEach { member ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(10.dp))
                                .background(CharcoalSurfaceVariant)
                                .padding(10.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(10.dp)
                            ) {
                                Box(
                                    modifier = Modifier
                                        .size(36.dp)
                                        .clip(CircleShape)
                                        .background(Brush.linearGradient(listOf(ElectricViolet, MagentaAccent))),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text(
                                        text = member.fullName.take(1).uppercase(),
                                        color = White,
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 14.sp
                                    )
                                }
                                Column {
                                    Text(
                                        text = member.fullName,
                                        color = TextPrimary,
                                        fontSize = 13.sp,
                                        fontWeight = FontWeight.Bold
                                    )
                                    Text(
                                        text = "${member.branch} • ${member.academicYear}",
                                        color = TextSecondary,
                                        fontSize = 11.sp
                                    )
                                }
                            }

                            Column(horizontalAlignment = Alignment.End) {
                                Box(
                                    modifier = Modifier
                                        .clip(RoundedCornerShape(6.dp))
                                        .background(if (member.role == TeamRole.OWNER) ElectricVioletSubtle else CharcoalBorder)
                                        .padding(horizontal = 6.dp, vertical = 2.dp)
                                ) {
                                    Text(
                                        text = member.role.label,
                                        color = if (member.role == TeamRole.OWNER) ElectricVioletLight else TextSecondary,
                                        fontSize = 10.sp,
                                        fontWeight = FontWeight.Bold
                                    )
                                }
                                if (member.isManitVerified) {
                                    Spacer(modifier = Modifier.height(3.dp))
                                    ManitVerificationBadge(isVerified = true)
                                }
                            }
                        }
                    }
                }
            }

            // WhatsApp Integration Notice
            if (!team.whatsappGroupLink.isNullOrBlank()) {
                Card(
                    shape = RoundedCornerShape(14.dp),
                    colors = CardDefaults.cardColors(containerColor = CharcoalSurface),
                    border = androidx.compose.foundation.BorderStroke(1.dp, StatusSuccessSubtle),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        modifier = Modifier.padding(14.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        Icon(Icons.Default.Share, contentDescription = null, tint = StatusSuccess, modifier = Modifier.size(24.dp))
                        Column {
                            Text("Official WhatsApp Coordination Link", color = TextPrimary, fontSize = 13.sp, fontWeight = FontWeight.Bold)
                            Text(
                                if (isOwner || isMember) "Accessible directly above for team planning & standups."
                                else "Direct WhatsApp coordination link unlocks automatically once accepted by the team owner.",
                                color = TextSecondary,
                                fontSize = 11.sp
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(20.dp))
        }
    }

    // Apply to Join Modal Dialog
    if (showApplyDialog) {
        AlertDialog(
            onDismissRequest = { showApplyDialog = false },
            title = {
                Text("Join Request: ${team.title}", color = TextPrimary, fontSize = 16.sp, fontWeight = FontWeight.Bold)
            },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text(
                        "Introduce yourself to ${team.ownerName} and state how your skills align with this project:",
                        color = TextSecondary,
                        fontSize = 12.sp
                    )
                    OutlinedTextField(
                        value = pitchNote,
                        onValueChange = { if (it.length <= 250) pitchNote = it },
                        placeholder = { Text("e.g. I am 1st year CSE with strong Kotlin and Compose experience. I built SIH 2024 UI prototype.") },
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = ElectricVioletLight,
                            unfocusedBorderColor = CharcoalBorder,
                            focusedTextColor = TextPrimary,
                            unfocusedTextColor = TextPrimary
                        ),
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(110.dp)
                            .testTag("apply_pitch_note_input")
                    )
                    Text("${pitchNote.length}/250 characters", color = TextMuted, fontSize = 11.sp)

                    if (applyError != null) {
                        Text(applyError ?: "", color = CoralLight, fontSize = 12.sp)
                    }
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        val result = ManitRepository.sendJoinRequest(team.id, pitchNote)
                        result.onSuccess {
                            showApplyDialog = false
                            pitchNote = ""
                        }.onFailure {
                            applyError = it.message ?: "Application failed"
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = ElectricViolet),
                    modifier = Modifier.testTag("apply_submit_btn")
                ) {
                    Text("Submit Application")
                }
            },
            dismissButton = {
                TextButton(onClick = { showApplyDialog = false }) {
                    Text("Cancel", color = TextSecondary)
                }
            },
            containerColor = CharcoalSurface,
            shape = RoundedCornerShape(16.dp)
        )
    }

    // Delete Team Confirmation Dialog
    if (showDeleteConfirmDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteConfirmDialog = false },
            title = { Text("Delete Team?", color = CoralLight, fontWeight = FontWeight.Bold) },
            text = {
                Text(
                    "Are you sure you want to delete '${team.title}'? All current applications and chat channels will be closed permanently.",
                    color = TextSecondary,
                    fontSize = 13.sp
                )
            },
            confirmButton = {
                Button(
                    onClick = {
                        ManitRepository.deleteTeam(team.id)
                        showDeleteConfirmDialog = false
                        onBack()
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = CoralAccent)
                ) {
                    Text("Delete Permanently")
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteConfirmDialog = false }) {
                    Text("Cancel", color = TextSecondary)
                }
            },
            containerColor = CharcoalSurface,
            shape = RoundedCornerShape(16.dp)
        )
    }
}
