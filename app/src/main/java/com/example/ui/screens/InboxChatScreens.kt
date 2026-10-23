package com.example.ui.screens

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.model.AppNotification
import com.example.data.model.ChatMessage
import com.example.data.repository.ManitRepository
import com.example.ui.components.EmptyStateCard
import com.example.ui.components.ManitVerificationBadge
import com.example.ui.theme.*
import java.text.SimpleDateFormat
import java.util.*

@Composable
fun InboxScreen(
    onOpenTeamChat: (String, String) -> Unit,
    modifier: Modifier = Modifier
) {
    val currentUser by ManitRepository.currentUser.collectAsState()
    val teams by ManitRepository.teams.collectAsState()
    val allMessages by ManitRepository.messages.collectAsState()

    // Teams user is involved in
    val myTeams = remember(teams, currentUser) {
        teams.filter { team ->
            team.ownerId == currentUser?.id || team.members.any { it.userId == currentUser?.id }
        }
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(MidnightNavy)
    ) {
        // Channels Header
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Icon(Icons.Default.Forum, contentDescription = null, tint = ElectricVioletLight, modifier = Modifier.size(20.dp))
                Text(
                    text = "Project Team Channels",
                    color = TextPrimary,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold
                )
            }

            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(8.dp))
                    .background(ElectricVioletSubtle)
                    .padding(horizontal = 8.dp, vertical = 3.dp)
            ) {
                Text(
                    text = "${myTeams.size} Active",
                    color = ElectricVioletLight,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }

        // Team Conversations
        if (myTeams.isEmpty()) {
            EmptyStateCard(
                title = "No Active Chat Channels",
                description = "When you create or join a team, your secure in-app team chatroom and coordinator hub will appear here.",
                icon = Icons.Default.ChatBubbleOutline
            )
        } else {
            LazyColumn(
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                items(myTeams, key = { it.id }) { team ->
                    val lastMsg = allMessages.filter { it.teamId == team.id }.lastOrNull()
                    Card(
                        shape = RoundedCornerShape(14.dp),
                        colors = CardDefaults.cardColors(containerColor = CharcoalSurface),
                        border = androidx.compose.foundation.BorderStroke(1.dp, CharcoalBorder),
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onOpenTeamChat(team.id, team.title) }
                            .testTag("chat_channel_${team.id}")
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(14.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(46.dp)
                                    .clip(CircleShape)
                                    .background(ElectricVioletSubtle),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(Icons.Default.Groups, contentDescription = null, tint = ElectricVioletLight)
                            }

                            Column(modifier = Modifier.weight(1f)) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(
                                        text = team.title,
                                        color = TextPrimary,
                                        fontSize = 14.sp,
                                        fontWeight = FontWeight.Bold,
                                        maxLines = 1,
                                        overflow = TextOverflow.Ellipsis,
                                        modifier = Modifier.weight(1f)
                                    )
                                    if (lastMsg != null) {
                                        Text(
                                            text = SimpleDateFormat("h:mm a", Locale.getDefault()).format(Date(lastMsg.timestamp)),
                                            color = TextMuted,
                                            fontSize = 10.sp
                                        )
                                    }
                                }

                                Spacer(modifier = Modifier.height(3.dp))

                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                                ) {
                                    Text(
                                        text = team.eventName,
                                        color = CyanLight,
                                        fontSize = 11.sp,
                                        fontWeight = FontWeight.SemiBold
                                    )
                                    Text(
                                        text = "•",
                                        color = TextMuted,
                                        fontSize = 11.sp
                                    )
                                    Text(
                                        text = "${team.members.size} members",
                                        color = TextMuted,
                                        fontSize = 11.sp
                                    )
                                }

                                Spacer(modifier = Modifier.height(2.dp))

                                Text(
                                    text = if (lastMsg != null) "${lastMsg.senderName}: ${lastMsg.content}" else "No messages yet. Tap to start discussion!",
                                    color = TextSecondary,
                                    fontSize = 12.sp,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun ChatRoomScreen(
    teamId: String,
    title: String,
    onBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val currentUser by ManitRepository.currentUser.collectAsState()
    val allMessages by ManitRepository.messages.collectAsState()
    val teams by ManitRepository.teams.collectAsState()
    val team = teams.find { it.id == teamId }

    val teamMessages = remember(allMessages, teamId) {
        allMessages.filter { it.teamId == teamId }.sortedBy { it.timestamp }
    }

    var messageInput by remember { mutableStateOf("") }
    val listState = rememberLazyListState()

    LaunchedEffect(teamMessages.size) {
        if (teamMessages.isNotEmpty()) {
            listState.animateScrollToItem(teamMessages.size - 1)
        }
    }

    Scaffold(
        topBar = {
            Surface(
                color = MidnightNavy,
                tonalElevation = 4.dp,
                border = androidx.compose.foundation.BorderStroke(1.dp, CharcoalBorder),
                modifier = Modifier
                    .fillMaxWidth()
                    .statusBarsPadding()
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 8.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(4.dp),
                        modifier = Modifier.weight(1f)
                    ) {
                        IconButton(onClick = onBack) {
                            Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = TextPrimary)
                        }
                        Column {
                            Text(
                                text = title,
                                color = TextPrimary,
                                fontSize = 15.sp,
                                fontWeight = FontWeight.Bold,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                            Text(
                                text = "${team?.members?.size ?: 1} members active",
                                color = CyanLight,
                                fontSize = 11.sp
                            )
                        }
                    }

                    // Direct WhatsApp group launcher if present
                    if (!team?.whatsappGroupLink.isNullOrBlank()) {
                        IconButton(
                            onClick = {
                                try {
                                    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(team?.whatsappGroupLink))
                                    context.startActivity(intent)
                                } catch (e: Exception) {
                                    // Fallback
                                }
                            },
                            modifier = Modifier
                                .clip(CircleShape)
                                .background(StatusSuccessSubtle)
                                .testTag("chat_whatsapp_btn")
                        ) {
                            Icon(
                                Icons.Default.Share,
                                contentDescription = "Open WhatsApp Group",
                                tint = StatusSuccess,
                                modifier = Modifier.size(20.dp)
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
                        .padding(horizontal = 12.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedTextField(
                        value = messageInput,
                        onValueChange = { messageInput = it },
                        placeholder = { Text("Type a message to team...", color = TextMuted, fontSize = 13.sp) },
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = ElectricVioletLight,
                            unfocusedBorderColor = CharcoalBorder,
                            focusedTextColor = TextPrimary,
                            unfocusedTextColor = TextPrimary
                        ),
                        shape = RoundedCornerShape(20.dp),
                        modifier = Modifier
                            .weight(1f)
                            .testTag("chat_input_field")
                    )

                    IconButton(
                        onClick = {
                            if (messageInput.isNotBlank()) {
                                ManitRepository.sendMessage(
                                    teamId = teamId,
                                    content = messageInput
                                )
                                messageInput = ""
                            }
                        },
                        modifier = Modifier
                            .size(44.dp)
                            .clip(CircleShape)
                            .background(ElectricViolet)
                            .testTag("chat_send_btn")
                    ) {
                        Icon(Icons.Default.Send, contentDescription = "Send", tint = White, modifier = Modifier.size(18.dp))
                    }
                }
            }
        },
        containerColor = MidnightNavy
    ) { innerPadding ->
        LazyColumn(
            state = listState,
            modifier = modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(horizontal = 16.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            item {
                Card(
                    shape = RoundedCornerShape(12.dp),
                    colors = CardDefaults.cardColors(containerColor = CharcoalSurface),
                    border = androidx.compose.foundation.BorderStroke(1.dp, CharcoalBorder),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(
                        modifier = Modifier.padding(12.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text("🔒 End-to-End In-App Team Channel", color = CyanLight, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                        Text("Messages are restricted to accepted team members only.", color = TextMuted, fontSize = 11.sp)
                    }
                }
            }

            items(teamMessages, key = { it.id }) { msg ->
                val isMe = msg.senderId == currentUser?.id

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = if (isMe) Arrangement.End else Arrangement.Start
                ) {
                    Column(
                        horizontalAlignment = if (isMe) Alignment.End else Alignment.Start,
                        modifier = Modifier.widthIn(max = 280.dp)
                    ) {
                        if (!isMe) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(4.dp),
                                modifier = Modifier.padding(bottom = 2.dp)
                            ) {
                                Text(msg.senderName, color = TextSecondary, fontSize = 11.sp, fontWeight = FontWeight.Bold)
                                if (msg.senderIsManitVerified) {
                                    Icon(Icons.Default.Shield, contentDescription = null, tint = ElectricVioletLight, modifier = Modifier.size(10.dp))
                                }
                            }
                        }

                        Box(
                            modifier = Modifier
                                .clip(
                                    RoundedCornerShape(
                                        topStart = 14.dp,
                                        topEnd = 14.dp,
                                        bottomStart = if (isMe) 14.dp else 2.dp,
                                        bottomEnd = if (isMe) 2.dp else 14.dp
                                    )
                                )
                                .background(if (isMe) ElectricViolet else CharcoalSurfaceVariant)
                                .padding(horizontal = 12.dp, vertical = 9.dp)
                        ) {
                            Text(
                                text = msg.content,
                                color = if (isMe) White else TextPrimary,
                                fontSize = 13.sp,
                                lineHeight = 18.sp
                            )
                        }

                        Text(
                            text = SimpleDateFormat("h:mm a", Locale.getDefault()).format(Date(msg.timestamp)),
                            color = TextMuted,
                            fontSize = 9.sp,
                            modifier = Modifier.padding(top = 2.dp, start = 4.dp, end = 4.dp)
                        )
                    }
                }
            }
        }
    }
}
