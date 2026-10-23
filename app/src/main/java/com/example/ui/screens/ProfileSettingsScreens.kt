package com.example.ui.screens

import android.content.Intent
import android.net.Uri
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.model.UserProfile
import com.example.data.repository.ManitRepository
import com.example.ui.components.ManitVerificationBadge
import com.example.ui.components.SkillChip
import com.example.ui.theme.*

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun ProfileScreen(
    onSignOut: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val currentUser by ManitRepository.currentUser.collectAsState()
    val blockedIds by ManitRepository.blockedUserIds.collectAsState()
    val teams by ManitRepository.teams.collectAsState()
    val requests by ManitRepository.joinRequests.collectAsState()

    var showEditProfileDialog by remember { mutableStateOf(false) }
    var showSafetyDialog by remember { mutableStateOf(false) }
    var showDeleteAccountConfirm by remember { mutableStateOf(false) }
    var showSaveToast by remember { mutableStateOf(false) }

    val user = currentUser ?: return

    val teamsLedCount = remember(teams, user) {
        teams.count { it.ownerId == user.id }
    }
    val teamsJoinedCount = remember(teams, user) {
        teams.count { t -> t.ownerId != user.id && t.members.any { it.userId == user.id } }
    }
    val applicationsCount = remember(requests, user) {
        requests.count { it.applicantId == user.id }
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(MidnightNavy)
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Save Feedback Banner
        AnimatedVisibility(
            visible = showSaveToast,
            enter = fadeIn() + expandVertically(),
            exit = fadeOut() + shrinkVertically()
        ) {
            Card(
                colors = CardDefaults.cardColors(containerColor = StatusSuccessSubtle),
                border = androidx.compose.foundation.BorderStroke(1.dp, StatusSuccess),
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier.padding(12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Icon(Icons.Default.CheckCircle, contentDescription = null, tint = StatusSuccess)
                    Text("Profile information saved successfully!", color = StatusSuccessLight, fontSize = 13.sp, fontWeight = FontWeight.Bold)
                }
            }
        }

        // Main Student Profile Card
        Card(
            shape = RoundedCornerShape(18.dp),
            colors = CardDefaults.cardColors(containerColor = CharcoalSurface),
            border = androidx.compose.foundation.BorderStroke(1.dp, CharcoalBorder),
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(20.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                // Profile Avatar with Glowing Ring
                Box(
                    modifier = Modifier
                        .size(80.dp)
                        .clip(CircleShape)
                        .background(
                            Brush.linearGradient(
                                listOf(ElectricViolet, MagentaAccent, CyanAccent)
                            )
                        )
                        .padding(3.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .clip(CircleShape)
                            .background(CharcoalSurface),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = user.fullName.take(1).uppercase(),
                            color = TextLavender,
                            fontSize = 32.sp,
                            fontWeight = FontWeight.ExtraBold
                        )
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                Text(
                    text = user.fullName,
                    color = TextPrimary,
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold
                )

                Text(
                    text = "${user.branch} • ${user.academicYear}",
                    color = TextSecondary,
                    fontSize = 13.sp,
                    modifier = Modifier.padding(top = 2.dp)
                )

                Spacer(modifier = Modifier.height(10.dp))

                ManitVerificationBadge(
                    isVerified = user.isManitVerified,
                    status = user.membershipStatus,
                    scholarNumber = user.scholarNumber
                )

                Spacer(modifier = Modifier.height(6.dp))

                Text(
                    text = user.collegeName,
                    color = CyanLight,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.SemiBold
                )

                if (user.bio.isNotBlank()) {
                    Spacer(modifier = Modifier.height(12.dp))
                    Text(
                        text = user.bio,
                        color = TextSecondary,
                        fontSize = 13.sp,
                        lineHeight = 18.sp,
                        textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                        modifier = Modifier.padding(horizontal = 8.dp)
                    )
                }

                Spacer(modifier = Modifier.height(18.dp))

                // Real Statistics Strip
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                        .background(CharcoalSurfaceVariant)
                        .padding(vertical = 10.dp, horizontal = 12.dp),
                    horizontalArrangement = Arrangement.SpaceAround,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    ProfileStatItem(count = "$teamsLedCount", label = "Leading")
                    ProfileStatItem(count = "$teamsJoinedCount", label = "Joined")
                    ProfileStatItem(count = "$applicationsCount", label = "Applied")
                    ProfileStatItem(count = "${user.skills.size}", label = "Skills")
                }

                Spacer(modifier = Modifier.height(16.dp))

                Button(
                    onClick = { showEditProfileDialog = true },
                    colors = ButtonDefaults.buttonColors(containerColor = CharcoalSurfaceVariant),
                    border = androidx.compose.foundation.BorderStroke(1.dp, ElectricVioletLight),
                    shape = RoundedCornerShape(10.dp),
                    modifier = Modifier.testTag("edit_profile_btn")
                ) {
                    Icon(Icons.Default.Edit, contentDescription = null, tint = ElectricVioletLight, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(6.dp))
                    Text("Edit Profile & Credentials", color = ElectricVioletLight, fontWeight = FontWeight.Bold)
                }
            }
        }

        // Skills & Technical Stack
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
                Text("Skills & Proficiencies", color = TextPrimary, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                FlowRow(
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    verticalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    user.skills.forEach { skill ->
                        SkillChip(skill = skill)
                    }
                }
            }
        }

        // Links & Contact Hub
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
                Text("Portfolio & Social Handles", color = TextPrimary, fontSize = 15.sp, fontWeight = FontWeight.Bold)

                if (!user.githubUrl.isNullOrBlank()) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable {
                                try {
                                    context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(user.githubUrl)))
                                } catch (e: Exception) {}
                            }
                            .padding(vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        Icon(Icons.Default.Code, contentDescription = null, tint = CyanLight)
                        Text(user.githubUrl ?: "", color = CyanLight, fontSize = 13.sp)
                    }
                }

                if (!user.linkedinUrl.isNullOrBlank()) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable {
                                try {
                                    context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(user.linkedinUrl)))
                                } catch (e: Exception) {}
                            }
                            .padding(vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        Icon(Icons.Default.Work, contentDescription = null, tint = ElectricVioletLight)
                        Text(user.linkedinUrl ?: "", color = ElectricVioletLight, fontSize = 13.sp)
                    }
                }

                if (!user.whatsappNumber.isNullOrBlank()) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        Icon(Icons.Default.Phone, contentDescription = null, tint = StatusSuccess)
                        Text("WhatsApp: ${user.whatsappNumber}", color = TextPrimary, fontSize = 13.sp)
                    }
                }
            }
        }

        // Privacy Controls & Safety Center
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
                Text("Privacy & Moderation Controls", color = TextPrimary, fontSize = 15.sp, fontWeight = FontWeight.Bold)

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text("Public Discovery Visibility", color = TextPrimary, fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
                        Text("Visible in student discovery & network graph", color = TextSecondary, fontSize = 11.sp)
                    }
                    Switch(
                        checked = user.isProfilePublic,
                        onCheckedChange = {
                            ManitRepository.updateProfile(user.copy(isProfilePublic = it))
                        },
                        colors = SwitchDefaults.colors(checkedThumbColor = White, checkedTrackColor = ElectricViolet)
                    )
                }

                Divider(color = CharcoalDivider)

                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { showSafetyDialog = true }
                        .padding(vertical = 6.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        Icon(Icons.Default.Shield, contentDescription = null, tint = CoralLight)
                        Text("Safety & Blocked Users (${blockedIds.size})", color = TextPrimary, fontSize = 13.sp)
                    }
                    Icon(Icons.Default.ChevronRight, contentDescription = null, tint = TextMuted)
                }
            }
        }

        // Account Actions
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            OutlinedButton(
                onClick = {
                    ManitRepository.signOut()
                    onSignOut()
                },
                shape = RoundedCornerShape(10.dp),
                border = androidx.compose.foundation.BorderStroke(1.dp, CharcoalBorder),
                modifier = Modifier
                    .weight(1f)
                    .height(48.dp)
                    .testTag("sign_out_btn")
            ) {
                Icon(Icons.Default.Logout, contentDescription = null, tint = TextSecondary, modifier = Modifier.size(16.dp))
                Spacer(modifier = Modifier.width(6.dp))
                Text("Sign Out", color = TextSecondary)
            }

            Button(
                onClick = { showDeleteAccountConfirm = true },
                colors = ButtonDefaults.buttonColors(containerColor = CoralSubtle),
                border = androidx.compose.foundation.BorderStroke(1.dp, CoralLight),
                shape = RoundedCornerShape(10.dp),
                modifier = Modifier
                    .weight(1f)
                    .height(48.dp)
                    .testTag("delete_account_btn")
            ) {
                Icon(Icons.Default.DeleteForever, contentDescription = null, tint = CoralLight, modifier = Modifier.size(16.dp))
                Spacer(modifier = Modifier.width(6.dp))
                Text("Delete Account", color = CoralLight)
            }
        }

        Spacer(modifier = Modifier.height(20.dp))
    }

    // Edit Profile Modal Dialog
    if (showEditProfileDialog) {
        var editName by remember { mutableStateOf(user.fullName) }
        var editBio by remember { mutableStateOf(user.bio) }
        var editBranch by remember { mutableStateOf(user.branch) }
        var editYear by remember { mutableStateOf(user.academicYear) }
        var editGithub by remember { mutableStateOf(user.githubUrl ?: "") }
        var editLinkedin by remember { mutableStateOf(user.linkedinUrl ?: "") }
        var editWhatsapp by remember { mutableStateOf(user.whatsappNumber ?: "") }
        var editSkillsString by remember { mutableStateOf(user.skills.joinToString(", ")) }

        AlertDialog(
            onDismissRequest = { showEditProfileDialog = false },
            title = { Text("Edit Student Profile", color = TextPrimary, fontWeight = FontWeight.Bold) },
            text = {
                Column(
                    modifier = Modifier.verticalScroll(rememberScrollState()),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    OutlinedTextField(
                        value = editName,
                        onValueChange = { editName = it },
                        label = { Text("Full Name") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                    OutlinedTextField(
                        value = editBranch,
                        onValueChange = { editBranch = it },
                        label = { Text("Branch / Department") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                    OutlinedTextField(
                        value = editYear,
                        onValueChange = { editYear = it },
                        label = { Text("Academic Year") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                    OutlinedTextField(
                        value = editBio,
                        onValueChange = { editBio = it },
                        label = { Text("Bio / Statement") },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(80.dp)
                    )
                    OutlinedTextField(
                        value = editSkillsString,
                        onValueChange = { editSkillsString = it },
                        label = { Text("Skills (comma separated)") },
                        modifier = Modifier.fillMaxWidth()
                    )
                    OutlinedTextField(
                        value = editGithub,
                        onValueChange = { editGithub = it },
                        label = { Text("GitHub Profile URL") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                    OutlinedTextField(
                        value = editLinkedin,
                        onValueChange = { editLinkedin = it },
                        label = { Text("LinkedIn Profile URL") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                    OutlinedTextField(
                        value = editWhatsapp,
                        onValueChange = { editWhatsapp = it },
                        label = { Text("WhatsApp Phone Number") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        val parsedSkills = editSkillsString.split(",").map { it.trim() }.filter { it.isNotBlank() }
                        ManitRepository.updateProfile(
                            user.copy(
                                fullName = editName.trim(),
                                branch = editBranch.trim(),
                                academicYear = editYear.trim(),
                                bio = editBio.trim(),
                                skills = if (parsedSkills.isNotEmpty()) parsedSkills else user.skills,
                                githubUrl = editGithub.trim().ifBlank { null },
                                linkedinUrl = editLinkedin.trim().ifBlank { null },
                                whatsappNumber = editWhatsapp.trim().ifBlank { null }
                            )
                        )
                        showEditProfileDialog = false
                        showSaveToast = true
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = ElectricViolet)
                ) {
                    Text("Save Changes")
                }
            },
            dismissButton = {
                TextButton(onClick = { showEditProfileDialog = false }) {
                    Text("Cancel", color = TextSecondary)
                }
            },
            containerColor = CharcoalSurface,
            shape = RoundedCornerShape(16.dp)
        )
    }

    // Safety and Moderation Dialog
    if (showSafetyDialog) {
        AlertDialog(
            onDismissRequest = { showSafetyDialog = false },
            title = { Text("Safety & Blocked Users", color = TextPrimary, fontWeight = FontWeight.Bold) },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text(
                        "Blocked accounts cannot view your profile or message your teams.",
                        color = TextSecondary,
                        fontSize = 12.sp
                    )
                    if (blockedIds.isEmpty()) {
                        Text("No users currently blocked.", color = TextMuted, fontSize = 12.sp)
                    } else {
                        blockedIds.forEach { id ->
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(CharcoalSurfaceVariant)
                                    .padding(8.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text("User $id", color = TextPrimary, fontSize = 12.sp)
                                TextButton(onClick = { ManitRepository.unblockUser(id) }) {
                                    Text("Unblock", color = CyanLight, fontSize = 11.sp)
                                }
                            }
                        }
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = { showSafetyDialog = false }) {
                    Text("Done", color = ElectricVioletLight)
                }
            },
            containerColor = CharcoalSurface,
            shape = RoundedCornerShape(16.dp)
        )
    }

    // Delete Account Confirmation Dialog
    if (showDeleteAccountConfirm) {
        AlertDialog(
            onDismissRequest = { showDeleteAccountConfirm = false },
            title = { Text("Delete Account Permanently?", color = CoralLight, fontWeight = FontWeight.Bold) },
            text = {
                Text(
                    "This action cannot be undone. All your project teams, membership applications, and chats will be immediately removed in compliance with data privacy standards.",
                    color = TextSecondary,
                    fontSize = 13.sp
                )
            },
            confirmButton = {
                Button(
                    onClick = {
                        ManitRepository.deleteAccount()
                        showDeleteAccountConfirm = false
                        onSignOut()
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = CoralAccent)
                ) {
                    Text("Delete Everything")
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteAccountConfirm = false }) {
                    Text("Cancel", color = TextSecondary)
                }
            },
            containerColor = CharcoalSurface,
            shape = RoundedCornerShape(16.dp)
        )
    }
}

@Composable
fun ProfileStatItem(
    count: String,
    label: String,
    modifier: Modifier = Modifier
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = modifier
    ) {
        Text(text = count, color = TextLavender, fontSize = 16.sp, fontWeight = FontWeight.ExtraBold)
        Text(text = label, color = TextMuted, fontSize = 10.sp, fontWeight = FontWeight.Medium)
    }
}
