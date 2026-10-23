package com.example.ui.screens

import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.model.JoinRequest
import com.example.data.model.RequestStatus
import com.example.data.model.Team
import com.example.data.repository.ManitRepository
import com.example.ui.components.EmptyStateCard
import com.example.ui.components.ManitVerificationBadge
import com.example.ui.components.RequestStatusBadge
import com.example.ui.components.StatusPill
import com.example.ui.theme.*

@Composable
fun MyTeamsScreen(
    onTeamClick: (String) -> Unit,
    onOpenChat: (String, String) -> Unit,
    onCreateTeamClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    var selectedSubTab by remember { mutableStateOf(0) } // 0: Leading, 1: Joined, 2: Applications
    val currentUser by ManitRepository.currentUser.collectAsState()
    val allTeams by ManitRepository.teams.collectAsState()
    val allRequests by ManitRepository.joinRequests.collectAsState()

    val myLedTeams = remember(allTeams, currentUser) {
        allTeams.filter { it.ownerId == currentUser?.id }
    }

    val myJoinedTeams = remember(allTeams, currentUser) {
        allTeams.filter { team ->
            team.ownerId != currentUser?.id && team.members.any { it.userId == currentUser?.id }
        }
    }

    val myApplications = remember(allRequests, currentUser) {
        allRequests.filter { it.applicantId == currentUser?.id }
    }

    // Pending requests for teams led by me
    val pendingRequestsForMe = remember(allRequests, myLedTeams) {
        val myTeamIds = myLedTeams.map { it.id }.toSet()
        allRequests.filter { myTeamIds.contains(it.teamId) && it.status == RequestStatus.PENDING }
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(MidnightNavy)
    ) {
        // Tab Header
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(CharcoalSurface)
                .border(1.dp, CharcoalBorder, RoundedCornerShape(12.dp))
                .padding(4.dp)
        ) {
            Box(
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(9.dp))
                    .background(if (selectedSubTab == 0) ElectricViolet else Color.Transparent)
                    .clickable { selectedSubTab = 0 }
                    .padding(vertical = 8.dp)
                    .testTag("myteams_tab_lead"),
                contentAlignment = Alignment.Center
            ) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(
                        "Leading (${myLedTeams.size})",
                        color = if (selectedSubTab == 0) White else TextSecondary,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold
                    )
                    if (pendingRequestsForMe.isNotEmpty()) {
                        Box(
                            modifier = Modifier
                                .clip(CircleShape)
                                .background(CoralAccent)
                                .padding(horizontal = 5.dp, vertical = 1.dp)
                        ) {
                            Text("${pendingRequestsForMe.size}", color = White, fontSize = 10.sp, fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }

            Box(
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(9.dp))
                    .background(if (selectedSubTab == 1) ElectricViolet else Color.Transparent)
                    .clickable { selectedSubTab = 1 }
                    .padding(vertical = 8.dp)
                    .testTag("myteams_tab_joined"),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    "Joined (${myJoinedTeams.size})",
                    color = if (selectedSubTab == 1) White else TextSecondary,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold
                )
            }

            Box(
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(9.dp))
                    .background(if (selectedSubTab == 2) ElectricViolet else Color.Transparent)
                    .clickable { selectedSubTab = 2 }
                    .padding(vertical = 8.dp)
                    .testTag("myteams_tab_applications"),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    "Applied (${myApplications.size})",
                    color = if (selectedSubTab == 2) White else TextSecondary,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }

        when (selectedSubTab) {
            0 -> {
                // Teams I Lead
                if (myLedTeams.isEmpty()) {
                    EmptyStateCard(
                        title = "No Teams Created",
                        description = "You haven't launched a project team yet. Start a team for SIH 2026, campus hackathons, or research!",
                        icon = Icons.Default.Groups,
                        actionLabel = "Create a Team",
                        onAction = onCreateTeamClick
                    )
                } else {
                    LazyColumn(
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        items(myLedTeams, key = { it.id }) { team ->
                            LedTeamCard(
                                team = team,
                                pendingRequests = allRequests.filter { it.teamId == team.id && it.status == RequestStatus.PENDING },
                                onTeamClick = { onTeamClick(team.id) },
                                onOpenChat = { onOpenChat(team.id, team.title) },
                                onAccept = { reqId -> ManitRepository.acceptJoinRequest(reqId) },
                                onReject = { reqId -> ManitRepository.rejectJoinRequest(reqId) }
                            )
                        }
                    }
                }
            }
            1 -> {
                // Teams Joined
                if (myJoinedTeams.isEmpty()) {
                    EmptyStateCard(
                        title = "No Joined Teams Yet",
                        description = "Explore active hackathon projects in the Discover tab and apply to collaborate with peers.",
                        icon = Icons.Default.Handshake
                    )
                } else {
                    LazyColumn(
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(14.dp)
                    ) {
                        items(myJoinedTeams, key = { it.id }) { team ->
                            JoinedTeamCard(
                                team = team,
                                onTeamClick = { onTeamClick(team.id) },
                                onOpenChat = { onOpenChat(team.id, team.title) }
                            )
                        }
                    }
                }
            }
            2 -> {
                // My Applications
                if (myApplications.isEmpty()) {
                    EmptyStateCard(
                        title = "No Sent Applications",
                        description = "You have not submitted joining requests to any project teams yet.",
                        icon = Icons.Default.AssignmentReturn
                    )
                } else {
                    LazyColumn(
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(myApplications, key = { it.id }) { req ->
                            SentApplicationCard(
                                request = req,
                                onWithdraw = { ManitRepository.withdrawJoinRequest(req.id) }
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun LedTeamCard(
    team: Team,
    pendingRequests: List<JoinRequest>,
    onTeamClick: () -> Unit,
    onOpenChat: () -> Unit,
    onAccept: (String) -> Unit,
    onReject: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = CharcoalSurface),
        border = androidx.compose.foundation.BorderStroke(1.dp, CharcoalBorder),
        modifier = modifier
            .fillMaxWidth()
            .clickable { onTeamClick() }
            .testTag("led_team_${team.id}")
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
                    text = team.title,
                    color = TextPrimary,
                    fontSize = 17.sp,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.weight(1f)
                )
                StatusPill(vacancies = team.vacanciesLeft, isRecruiting = team.isRecruiting)
            }

            Text(
                text = "${team.eventName} • ${team.members.size}/${team.maxTeamSize} members",
                color = CyanLight,
                fontSize = 12.sp
            )

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Button(
                    onClick = onOpenChat,
                    colors = ButtonDefaults.buttonColors(containerColor = ElectricViolet),
                    shape = RoundedCornerShape(10.dp),
                    modifier = Modifier.weight(1f)
                ) {
                    Icon(Icons.Default.Chat, contentDescription = null, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(6.dp))
                    Text("Team Chat")
                }

                OutlinedButton(
                    onClick = onTeamClick,
                    shape = RoundedCornerShape(10.dp),
                    border = androidx.compose.foundation.BorderStroke(1.dp, CharcoalBorder)
                ) {
                    Text("Roster", color = TextPrimary)
                }
            }

            // Pending Applicants Review Section
            if (pendingRequests.isNotEmpty()) {
                Divider(color = CharcoalDivider)
                Text(
                    text = "Pending Applications (${pendingRequests.size})",
                    color = CoralLight,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold
                )

                pendingRequests.forEach { req ->
                    Card(
                        shape = RoundedCornerShape(12.dp),
                        colors = CardDefaults.cardColors(containerColor = CharcoalSurfaceVariant),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(12.dp),
                            verticalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Column {
                                    Text(req.applicantName, color = TextPrimary, fontWeight = FontWeight.Bold, fontSize = 13.sp)
                                    Text("${req.applicantBranch} • ${req.applicantYear}", color = TextSecondary, fontSize = 11.sp)
                                }
                                ManitVerificationBadge(isVerified = req.applicantIsManitVerified)
                            }

                            if (req.pitchNote.isNotBlank()) {
                                Text(
                                    "\"${req.pitchNote}\"",
                                    color = TextSecondary,
                                    fontSize = 12.sp,
                                    fontStyle = androidx.compose.ui.text.font.FontStyle.Italic
                                )
                            }

                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.End,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                TextButton(
                                    onClick = { onReject(req.id) },
                                    colors = ButtonDefaults.textButtonColors(contentColor = CoralLight)
                                ) {
                                    Text("Decline")
                                }
                                Spacer(modifier = Modifier.width(6.dp))
                                Button(
                                    onClick = { onAccept(req.id) },
                                    colors = ButtonDefaults.buttonColors(containerColor = StatusSuccess),
                                    shape = RoundedCornerShape(8.dp)
                                ) {
                                    Text("Accept & Add")
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
fun JoinedTeamCard(
    team: Team,
    onTeamClick: () -> Unit,
    onOpenChat: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = CharcoalSurface),
        border = androidx.compose.foundation.BorderStroke(1.dp, CharcoalBorder),
        modifier = modifier
            .fillMaxWidth()
            .clickable { onTeamClick() }
            .testTag("joined_team_${team.id}")
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
                Text(
                    text = team.title,
                    color = TextPrimary,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold
                )
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(6.dp))
                        .background(ElectricVioletSubtle)
                        .padding(horizontal = 6.dp, vertical = 2.dp)
                ) {
                    Text("Member", color = ElectricVioletLight, fontSize = 10.sp, fontWeight = FontWeight.Bold)
                }
            }

            Text("Led by ${team.ownerName} • ${team.eventName}", color = TextSecondary, fontSize = 12.sp)

            Button(
                onClick = onOpenChat,
                colors = ButtonDefaults.buttonColors(containerColor = ElectricViolet),
                shape = RoundedCornerShape(10.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Icon(Icons.Default.Chat, contentDescription = null, modifier = Modifier.size(16.dp))
                Spacer(modifier = Modifier.width(6.dp))
                Text("Open Team Chat")
            }
        }
    }
}

@Composable
fun SentApplicationCard(
    request: JoinRequest,
    onWithdraw: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(containerColor = CharcoalSurface),
        border = androidx.compose.foundation.BorderStroke(1.dp, CharcoalBorder),
        modifier = modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(14.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = request.teamTitle,
                    color = TextPrimary,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold
                )
                RequestStatusBadge(status = request.status)
            }

            if (request.pitchNote.isNotBlank()) {
                Text(
                    text = "Pitch: \"${request.pitchNote}\"",
                    color = TextSecondary,
                    fontSize = 12.sp
                )
            }

            if (request.status == RequestStatus.PENDING) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.End
                ) {
                    TextButton(
                        onClick = onWithdraw,
                        colors = ButtonDefaults.textButtonColors(contentColor = CoralLight)
                    ) {
                        Text("Withdraw Request", fontSize = 12.sp)
                    }
                }
            }
        }
    }
}
