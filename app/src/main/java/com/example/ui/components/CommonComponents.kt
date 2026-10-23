package com.example.ui.components

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.School
import androidx.compose.material.icons.filled.Shield
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.R
import com.example.data.model.MembershipStatus
import com.example.data.model.RequestStatus
import com.example.ui.theme.*

@Composable
fun ManitVerificationBadge(
    isVerified: Boolean,
    status: MembershipStatus = MembershipStatus.MANIT_STUDENT,
    scholarNumber: String? = null,
    modifier: Modifier = Modifier
) {
    if (isVerified && status == MembershipStatus.MANIT_STUDENT) {
        Surface(
            shape = RoundedCornerShape(20.dp),
            color = ElectricVioletSubtle,
            border = androidx.compose.foundation.BorderStroke(1.dp, ElectricVioletLight),
            modifier = modifier.testTag("badge_manit_verified")
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(4.dp),
                modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.Shield,
                    contentDescription = "MANIT Verified",
                    tint = ElectricVioletLight,
                    modifier = Modifier.size(12.dp)
                )
                Text(
                    text = if (scholarNumber != null) "MANIT #$scholarNumber" else "MANIT Verified",
                    color = ElectricVioletLight,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    } else if (status == MembershipStatus.OTHER_COLLEGE) {
        Surface(
            shape = RoundedCornerShape(20.dp),
            color = CharcoalSurfaceVariant,
            border = androidx.compose.foundation.BorderStroke(1.dp, CharcoalBorder),
            modifier = modifier.testTag("badge_external_student")
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(4.dp),
                modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.School,
                    contentDescription = "Visiting Student",
                    tint = CyanLight,
                    modifier = Modifier.size(12.dp)
                )
                Text(
                    text = "Visiting Student",
                    color = CyanLight,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Medium
                )
            }
        }
    } else {
        Surface(
            shape = RoundedCornerShape(20.dp),
            color = CharcoalSurfaceVariant,
            border = androidx.compose.foundation.BorderStroke(1.dp, CharcoalBorder),
            modifier = modifier.testTag("badge_guest")
        ) {
            Text(
                text = "Guest / Open",
                color = TextMuted,
                fontSize = 11.sp,
                fontWeight = FontWeight.Normal,
                modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
            )
        }
    }
}

@Composable
fun SkillChip(
    skill: String,
    isSelected: Boolean = false,
    onClick: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    val bg = if (isSelected) ElectricVioletSubtle else CharcoalSurfaceVariant
    val borderCol = if (isSelected) ElectricVioletLight else CharcoalBorder
    val textCol = if (isSelected) ElectricVioletLight else TextSecondary

    Box(
        modifier = modifier
            .clip(RoundedCornerShape(8.dp))
            .background(bg)
            .border(1.dp, borderCol, RoundedCornerShape(8.dp))
            .then(if (onClick != null) Modifier.clickable { onClick() } else Modifier)
            .padding(horizontal = 10.dp, vertical = 5.dp)
            .testTag("skill_chip_${skill.lowercase().replace(" ", "_")}")
    ) {
        Text(
            text = skill,
            color = textCol,
            fontSize = 12.sp,
            fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal
        )
    }
}

@Composable
fun StatusPill(
    vacancies: Int,
    isRecruiting: Boolean,
    modifier: Modifier = Modifier
) {
    val (bg, textCol, label) = when {
        !isRecruiting -> Triple(CharcoalSurfaceVariant, TextMuted, "Roster Locked")
        vacancies > 0 -> Triple(CoralSubtle, CoralLight, "$vacancies slot${if (vacancies > 1) "s" else ""} left")
        else -> Triple(StatusWarningSubtle, StatusWarning, "Team Full")
    }

    Box(
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .background(bg)
            .padding(horizontal = 8.dp, vertical = 3.dp)
            .testTag("status_pill")
    ) {
        Text(
            text = label,
            color = textCol,
            fontSize = 11.sp,
            fontWeight = FontWeight.SemiBold
        )
    }
}

@Composable
fun RequestStatusBadge(
    status: RequestStatus,
    modifier: Modifier = Modifier
) {
    val (bg, textCol) = when (status) {
        RequestStatus.PENDING -> StatusWarningSubtle to StatusWarning
        RequestStatus.ACCEPTED -> StatusSuccessSubtle to StatusSuccess
        RequestStatus.REJECTED -> CoralSubtle to CoralLight
        RequestStatus.WITHDRAWN -> CharcoalSurfaceVariant to TextMuted
    }

    Box(
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .background(bg)
            .padding(horizontal = 9.dp, vertical = 4.dp)
            .testTag("request_status_${status.name.lowercase()}")
    ) {
        Text(
            text = status.label,
            color = textCol,
            fontSize = 11.sp,
            fontWeight = FontWeight.Bold
        )
    }
}

@Composable
fun AppHeader(
    title: String,
    unreadNotificationsCount: Int = 0,
    onNotificationsClick: () -> Unit,
    onProfileClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .background(MidnightNavy)
            .statusBarsPadding()
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Image(
                painter = painterResource(id = R.drawable.ic_manit_teamup_logo),
                contentDescription = "MANIT TeamUp Logo",
                modifier = Modifier
                    .size(38.dp)
                    .clip(RoundedCornerShape(6.dp))
                    .border(1.dp, CharcoalBorder, RoundedCornerShape(6.dp))
            )
            Column {
                Text(
                    text = "MANIT TeamUp",
                    color = TextPrimary,
                    fontSize = 18.sp,
                    fontWeight = FontWeight.ExtraBold,
                    letterSpacing = (-0.5).sp
                )
                Text(
                    text = title,
                    color = ElectricVioletLight,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Medium
                )
            }
        }

        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            IconButton(
                onClick = onNotificationsClick,
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(CharcoalSurfaceVariant)
                    .testTag("header_notifications_btn")
            ) {
                BadgedBox(
                    badge = {
                        if (unreadNotificationsCount > 0) {
                            Badge(
                                containerColor = CoralAccent,
                                contentColor = White
                            ) {
                                Text("$unreadNotificationsCount")
                            }
                        }
                    }
                ) {
                    Icon(
                        imageVector = Icons.Default.Notifications,
                        contentDescription = "Notifications",
                        tint = TextPrimary,
                        modifier = Modifier.size(20.dp)
                    )
                }
            }

            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(
                        Brush.linearGradient(
                            listOf(ElectricViolet, MagentaAccent)
                        )
                    )
                    .clickable { onProfileClick() }
                    .testTag("header_profile_avatar"),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "MU",
                    color = White,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}

@Composable
fun EmptyStateCard(
    title: String,
    description: String,
    icon: ImageVector = Icons.Default.Info,
    actionLabel: String? = null,
    onAction: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    Card(
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = CharcoalSurface),
        border = androidx.compose.foundation.BorderStroke(1.dp, CharcoalBorder),
        modifier = modifier
            .fillMaxWidth()
            .padding(16.dp)
            .testTag("empty_state_card")
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(28.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(56.dp)
                    .clip(CircleShape)
                    .background(CharcoalSurfaceVariant),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = ElectricVioletLight,
                    modifier = Modifier.size(28.dp)
                )
            }

            Text(
                text = title,
                color = TextPrimary,
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center
            )

            Text(
                text = description,
                color = TextSecondary,
                fontSize = 13.sp,
                textAlign = TextAlign.Center,
                lineHeight = 18.sp
            )

            if (actionLabel != null && onAction != null) {
                Spacer(modifier = Modifier.height(4.dp))
                Button(
                    onClick = onAction,
                    colors = ButtonDefaults.buttonColors(containerColor = ElectricViolet),
                    shape = RoundedCornerShape(10.dp),
                    modifier = Modifier.testTag("empty_state_action_btn")
                ) {
                    Text(text = actionLabel, color = White, fontWeight = FontWeight.SemiBold)
                }
            }
        }
    }
}
