package com.example.ui.screens

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.model.ProjectCategory
import com.example.data.model.Team
import com.example.data.model.UserProfile
import com.example.data.repository.ManitRepository
import com.example.ui.components.EmptyStateCard
import com.example.ui.components.ManitVerificationBadge
import com.example.ui.components.SkillChip
import com.example.ui.components.StatusPill
import com.example.ui.theme.*

@OptIn(ExperimentalLayoutApi::class, ExperimentalMaterial3Api::class)
@Composable
fun DiscoverScreen(
    onTeamClick: (String) -> Unit,
    onStudentClick: (String) -> Unit,
    onCreateTeamClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    var selectedViewMode by remember { mutableStateOf(0) } // 0: Teams, 1: Students, 2: Interactive Network Graph
    var searchQuery by remember { mutableStateOf("") }
    var selectedCategory by remember { mutableStateOf<ProjectCategory?>(null) }
    var selectedSkillFilter by remember { mutableStateOf<String?>(null) }
    var onlyRecruiting by remember { mutableStateOf(false) }
    var onlyManitVerified by remember { mutableStateOf(false) }
    var showFilterSheet by remember { mutableStateOf(false) }

    val teams by ManitRepository.teams.collectAsState()
    val profiles by ManitRepository.allProfiles.collectAsState()
    val currentUser by ManitRepository.currentUser.collectAsState()
    val blockedIds by ManitRepository.blockedUserIds.collectAsState()

    // Filtered Teams
    val filteredTeams = remember(teams, searchQuery, selectedCategory, selectedSkillFilter, onlyRecruiting, onlyManitVerified, blockedIds) {
        teams.filter { team ->
            if (blockedIds.contains(team.ownerId)) return@filter false
            if (onlyRecruiting && !team.isRecruiting) return@filter false
            if (onlyManitVerified && !team.ownerIsManitVerified) return@filter false
            if (selectedCategory != null && team.projectCategory != selectedCategory) return@filter false
            if (selectedSkillFilter != null && !team.requiredSkills.any { it.equals(selectedSkillFilter, ignoreCase = true) }) return@filter false

            if (searchQuery.isNotBlank()) {
                val q = searchQuery.trim().lowercase()
                val matchTitle = team.title.lowercase().contains(q)
                val matchEvent = team.eventName.lowercase().contains(q)
                val matchDesc = team.description.lowercase().contains(q)
                val matchOwner = team.ownerName.lowercase().contains(q)
                val matchSkills = team.requiredSkills.any { it.lowercase().contains(q) }
                matchTitle || matchEvent || matchDesc || matchOwner || matchSkills
            } else {
                true
            }
        }
    }

    // Filtered Students
    val filteredStudents = remember(profiles, searchQuery, selectedSkillFilter, onlyManitVerified, blockedIds) {
        profiles.filter { student ->
            if (blockedIds.contains(student.id)) return@filter false
            if (onlyManitVerified && !student.isManitVerified) return@filter false
            if (selectedSkillFilter != null && !student.skills.any { it.equals(selectedSkillFilter, ignoreCase = true) }) return@filter false

            if (searchQuery.isNotBlank()) {
                val q = searchQuery.trim().lowercase()
                val matchName = student.fullName.lowercase().contains(q)
                val matchBranch = student.branch.lowercase().contains(q)
                val matchCollege = student.collegeName.lowercase().contains(q)
                val matchSkills = student.skills.any { it.lowercase().contains(q) }
                matchName || matchBranch || matchCollege || matchSkills
            } else {
                true
            }
        }
    }

    val availableSkills = listOf("Kotlin", "Python", "PyTorch", "React", "Next.js", "Solidity", "Figma", "C++", "ROS2", "Docker")
    val activeFiltersCount = (if (selectedCategory != null) 1 else 0) +
            (if (selectedSkillFilter != null) 1 else 0) +
            (if (onlyRecruiting) 1 else 0) +
            (if (onlyManitVerified) 1 else 0)

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(MidnightNavy)
    ) {
        // Search & Filter Header Row
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            OutlinedTextField(
                value = searchQuery,
                onValueChange = { searchQuery = it },
                placeholder = {
                    Text(
                        when (selectedViewMode) {
                            0 -> "Search teams, hackathons, or skills..."
                            1 -> "Search students by name, skill, branch..."
                            else -> "Filter interactive skill network..."
                        },
                        color = TextMuted,
                        fontSize = 13.sp
                    )
                },
                leadingIcon = {
                    Icon(Icons.Default.Search, contentDescription = "Search", tint = CyanLight)
                },
                trailingIcon = {
                    if (searchQuery.isNotEmpty()) {
                        IconButton(onClick = { searchQuery = "" }) {
                            Icon(Icons.Default.Clear, contentDescription = "Clear", tint = TextMuted)
                        }
                    }
                },
                singleLine = true,
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = ElectricVioletLight,
                    unfocusedBorderColor = CharcoalBorder,
                    focusedTextColor = TextPrimary,
                    unfocusedTextColor = TextPrimary,
                    focusedContainerColor = CharcoalSurface,
                    unfocusedContainerColor = CharcoalSurface
                ),
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier
                    .weight(1f)
                    .testTag("discover_search_bar")
            )

            // Filter button with active counter badge
            IconButton(
                onClick = { showFilterSheet = true },
                modifier = Modifier
                    .size(48.dp)
                    .clip(RoundedCornerShape(12.dp))
                    .background(if (activeFiltersCount > 0) ElectricVioletSubtle else CharcoalSurface)
                    .border(1.dp, if (activeFiltersCount > 0) ElectricVioletLight else CharcoalBorder, RoundedCornerShape(12.dp))
                    .testTag("discover_filters_btn")
            ) {
                BadgedBox(
                    badge = {
                        if (activeFiltersCount > 0) {
                            Badge(containerColor = CoralAccent, contentColor = White) {
                                Text("$activeFiltersCount")
                            }
                        }
                    }
                ) {
                    Icon(
                        imageVector = Icons.Default.Tune,
                        contentDescription = "Filters",
                        tint = if (activeFiltersCount > 0) ElectricVioletLight else TextSecondary
                    )
                }
            }
        }

        // View Mode Switcher: Teams | Students | Network Graph
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 4.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(CharcoalSurface)
                .border(1.dp, CharcoalBorder, RoundedCornerShape(12.dp))
                .padding(3.dp)
        ) {
            DiscoverModePill(
                title = "Teams (${filteredTeams.size})",
                icon = Icons.Default.Diversity3,
                isSelected = selectedViewMode == 0,
                onClick = { selectedViewMode = 0 },
                testTag = "discover_tab_teams",
                modifier = Modifier.weight(1f)
            )

            DiscoverModePill(
                title = "Students (${filteredStudents.size})",
                icon = Icons.Default.PersonSearch,
                isSelected = selectedViewMode == 1,
                onClick = { selectedViewMode = 1 },
                testTag = "discover_tab_students",
                modifier = Modifier.weight(1f)
            )

            DiscoverModePill(
                title = "Network Graph",
                icon = Icons.Default.Hub,
                isSelected = selectedViewMode == 2,
                onClick = { selectedViewMode = 2 },
                testTag = "discover_tab_graph",
                modifier = Modifier.weight(1f)
            )
        }

        // Quick Active Filter Badges Bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .horizontalScroll(rememberScrollState())
                .padding(horizontal = 16.dp, vertical = 6.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // MANIT Verified Quick Filter
            FilterChip(
                selected = onlyManitVerified,
                onClick = { onlyManitVerified = !onlyManitVerified },
                label = { Text("MANIT Verified", fontSize = 11.sp) },
                leadingIcon = {
                    Icon(Icons.Default.Shield, contentDescription = null, modifier = Modifier.size(13.dp))
                },
                colors = FilterChipDefaults.filterChipColors(
                    selectedContainerColor = ElectricVioletSubtle,
                    selectedLabelColor = ElectricVioletLight,
                    containerColor = CharcoalSurface,
                    labelColor = TextSecondary
                ),
                border = FilterChipDefaults.filterChipBorder(
                    borderColor = if (onlyManitVerified) ElectricVioletLight else CharcoalBorder,
                    enabled = true,
                    selected = onlyManitVerified
                )
            )

            if (selectedViewMode == 0) {
                FilterChip(
                    selected = onlyRecruiting,
                    onClick = { onlyRecruiting = !onlyRecruiting },
                    label = { Text("Open Slots", fontSize = 11.sp) },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = CoralSubtle,
                        selectedLabelColor = CoralLight,
                        containerColor = CharcoalSurface,
                        labelColor = TextSecondary
                    ),
                    border = FilterChipDefaults.filterChipBorder(
                        borderColor = if (onlyRecruiting) CoralLight else CharcoalBorder,
                        enabled = true,
                        selected = onlyRecruiting
                    )
                )

                ProjectCategory.values().forEach { cat ->
                    FilterChip(
                        selected = selectedCategory == cat,
                        onClick = {
                            selectedCategory = if (selectedCategory == cat) null else cat
                        },
                        label = { Text(cat.displayName, fontSize = 11.sp) },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = CharcoalSurfaceVariant,
                            selectedLabelColor = CyanLight,
                            containerColor = CharcoalSurface,
                            labelColor = TextMuted
                        ),
                        border = FilterChipDefaults.filterChipBorder(
                            borderColor = if (selectedCategory == cat) CyanLight else CharcoalBorder,
                            enabled = true,
                            selected = selectedCategory == cat
                        )
                    )
                }
            }

            availableSkills.forEach { skill ->
                FilterChip(
                    selected = selectedSkillFilter == skill,
                    onClick = {
                        selectedSkillFilter = if (selectedSkillFilter == skill) null else skill
                    },
                    label = { Text(skill, fontSize = 11.sp) },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = CharcoalSurfaceVariant,
                        selectedLabelColor = ElectricVioletLight,
                        containerColor = CharcoalSurface,
                        labelColor = TextMuted
                    ),
                    border = FilterChipDefaults.filterChipBorder(
                        borderColor = if (selectedSkillFilter == skill) ElectricVioletLight else CharcoalBorder,
                        enabled = true,
                        selected = selectedSkillFilter == skill
                    )
                )
            }
        }

        // View Mode Content
        when (selectedViewMode) {
            0 -> {
                // Teams List View
                if (filteredTeams.isEmpty()) {
                    EmptyStateCard(
                        title = "No Teams Found",
                        description = "No active teams match your current filters. Try resetting the filters or create your own project team!",
                        icon = Icons.Default.SearchOff,
                        actionLabel = "Create a Team",
                        onAction = onCreateTeamClick
                    )
                } else {
                    LazyColumn(
                        contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 4.dp, bottom = 80.dp),
                        verticalArrangement = Arrangement.spacedBy(14.dp)
                    ) {
                        items(filteredTeams, key = { it.id }) { team ->
                            TeamCard(
                                team = team,
                                currentUserSkills = currentUser?.skills ?: emptyList(),
                                onClick = { onTeamClick(team.id) }
                            )
                        }
                    }
                }
            }
            1 -> {
                // Students List View
                if (filteredStudents.isEmpty()) {
                    EmptyStateCard(
                        title = "No Students Found",
                        description = "No student profiles match the filter criteria. Clear filters to explore all peer collaborators.",
                        icon = Icons.Default.PersonOff,
                        actionLabel = "Clear Filters",
                        onAction = {
                            searchQuery = ""
                            selectedSkillFilter = null
                            onlyManitVerified = false
                        }
                    )
                } else {
                    LazyColumn(
                        contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 4.dp, bottom = 80.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(filteredStudents, key = { it.id }) { student ->
                            StudentCard(
                                student = student,
                                onClick = { onStudentClick(student.id) }
                            )
                        }
                    }
                }
            }
            2 -> {
                // Interactive SVG/Canvas Collaboration Network Graph
                InteractiveCollaborationNetwork(
                    profiles = filteredStudents,
                    onStudentSelect = { student ->
                        onStudentClick(student.id)
                    }
                )
            }
        }
    }

    // Filter Bottom Sheet Dialog
    if (showFilterSheet) {
        ModalBottomSheet(
            onDismissRequest = { showFilterSheet = false },
            containerColor = CharcoalSurface,
            shape = RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(20.dp)
                    .navigationBarsPadding(),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("Filter Discovery", color = TextPrimary, fontSize = 18.sp, fontWeight = FontWeight.Bold)
                    TextButton(onClick = {
                        selectedCategory = null
                        selectedSkillFilter = null
                        onlyRecruiting = false
                        onlyManitVerified = false
                        showFilterSheet = false
                    }) {
                        Text("Reset All", color = CoralLight)
                    }
                }

                Text("Academic Credential", color = TextSecondary, fontSize = 13.sp, fontWeight = FontWeight.Bold)
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text("Only Verified MANIT Students", color = TextPrimary, fontSize = 14.sp)
                    Switch(
                        checked = onlyManitVerified,
                        onCheckedChange = { onlyManitVerified = it },
                        colors = SwitchDefaults.colors(checkedThumbColor = White, checkedTrackColor = ElectricViolet)
                    )
                }

                Text("Team Vacancy Status", color = TextSecondary, fontSize = 13.sp, fontWeight = FontWeight.Bold)
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text("Only Teams with Open Slots", color = TextPrimary, fontSize = 14.sp)
                    Switch(
                        checked = onlyRecruiting,
                        onCheckedChange = { onlyRecruiting = it },
                        colors = SwitchDefaults.colors(checkedThumbColor = White, checkedTrackColor = CoralAccent)
                    )
                }

                Button(
                    onClick = { showFilterSheet = false },
                    colors = ButtonDefaults.buttonColors(containerColor = ElectricViolet),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(48.dp)
                ) {
                    Text("Apply Filters", fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}

@Composable
fun DiscoverModePill(
    title: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    isSelected: Boolean,
    onClick: () -> Unit,
    testTag: String,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(9.dp))
            .background(if (isSelected) ElectricViolet else Color.Transparent)
            .clickable { onClick() }
            .padding(vertical = 8.dp)
            .testTag(testTag),
        contentAlignment = Alignment.Center
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(5.dp)
        ) {
            Icon(
                icon,
                contentDescription = null,
                tint = if (isSelected) White else TextSecondary,
                modifier = Modifier.size(15.dp)
            )
            Text(
                text = title,
                color = if (isSelected) White else TextSecondary,
                fontWeight = FontWeight.Bold,
                fontSize = 11.sp,
                maxLines = 1
            )
        }
    }
}

/**
 * Advanced Interactive Collaboration Network Visualization
 * Real student nodes connected by shared skills/tech tags
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun InteractiveCollaborationNetwork(
    profiles: List<UserProfile>,
    onStudentSelect: (UserProfile) -> Unit,
    modifier: Modifier = Modifier
) {
    var selectedProfile by remember { mutableStateOf<UserProfile?>(profiles.firstOrNull()) }

    val infiniteTransition = rememberInfiniteTransition(label = "pulseNetwork")
    val pulseGlow by infiniteTransition.animateFloat(
        initialValue = 0.5f,
        targetValue = 0.95f,
        animationSpec = infiniteRepeatable(
            animation = tween(2400, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "pulseGlow"
    )

    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Network Graph Canvas Container
        Card(
            shape = RoundedCornerShape(18.dp),
            colors = CardDefaults.cardColors(containerColor = CharcoalSurface),
            border = androidx.compose.foundation.BorderStroke(1.dp, CharcoalBorder),
            modifier = Modifier
                .fillMaxWidth()
                .weight(1f)
        ) {
            Box(modifier = Modifier.fillMaxSize()) {
                Canvas(
                    modifier = Modifier
                        .fillMaxSize()
                        .pointerInput(profiles) {
                            detectTapGestures { offset ->
                                val w = size.width
                                val h = size.height
                                val n = profiles.size.coerceAtLeast(1)

                                // Check which node was tapped
                                profiles.forEachIndexed { i, p ->
                                    val angle = (2 * Math.PI * i / n) - (Math.PI / 2)
                                    val radius = minOf(w, h) * 0.36f
                                    val cx = (w / 2f) + (radius * kotlin.math.cos(angle)).toFloat()
                                    val cy = (h / 2f) + (radius * kotlin.math.sin(angle)).toFloat()

                                    val dist = kotlin.math.hypot(offset.x - cx, offset.y - cy)
                                    if (dist <= 30.dp.toPx()) {
                                        selectedProfile = p
                                    }
                                }
                            }
                        }
                ) {
                    val w = size.width
                    val h = size.height
                    val n = profiles.size
                    if (n == 0) return@Canvas

                    val centerOffset = Offset(w / 2f, h / 2f)
                    val radius = minOf(w, h) * 0.36f

                    // Calculate positions for each student profile node
                    val nodePositions = profiles.mapIndexed { i, _ ->
                        val angle = (2 * Math.PI * i / n) - (Math.PI / 2)
                        Offset(
                            x = centerOffset.x + (radius * kotlin.math.cos(angle)).toFloat(),
                            y = centerOffset.y + (radius * kotlin.math.sin(angle)).toFloat()
                        )
                    }

                    // Draw connecting lines based on real shared skills
                    for (i in 0 until n) {
                        for (j in (i + 1) until n) {
                            val p1 = profiles[i]
                            val p2 = profiles[j]
                            val sharedSkills = p1.skills.intersect(p2.skills.toSet())
                            if (sharedSkills.isNotEmpty()) {
                                val isSelectedEdge = (selectedProfile?.id == p1.id || selectedProfile?.id == p2.id)
                                val lineColor = if (isSelectedEdge) ElectricVioletLight else CyanAccent.copy(alpha = 0.3f)
                                val lineWidth = if (isSelectedEdge) 2.5.dp.toPx() else 1.2.dp.toPx()

                                drawLine(
                                    color = lineColor,
                                    start = nodePositions[i],
                                    end = nodePositions[j],
                                    strokeWidth = lineWidth
                                )
                            }
                        }
                    }

                    // Draw central collaboration core
                    drawCircle(
                        brush = Brush.radialGradient(
                            colors = listOf(ElectricVioletLight.copy(alpha = pulseGlow * 0.35f), Color.Transparent),
                            center = centerOffset,
                            radius = radius * 0.55f
                        )
                    )

                    // Draw individual student nodes
                    profiles.forEachIndexed { i, student ->
                        val pos = nodePositions[i]
                        val isSelected = selectedProfile?.id == student.id

                        // Outer ring glow
                        if (isSelected) {
                            drawCircle(
                                color = CyanLight.copy(alpha = 0.45f),
                                center = pos,
                                radius = 28.dp.toPx()
                            )
                        }

                        // Node body
                        drawCircle(
                            brush = Brush.linearGradient(
                                if (student.isManitVerified) listOf(ElectricViolet, MagentaAccent) else listOf(CyanAccent, TurquoiseAccent)
                            ),
                            center = pos,
                            radius = if (isSelected) 22.dp.toPx() else 18.dp.toPx()
                        )
                    }
                }

                // Tip hint in top-right
                Text(
                    text = "Tap any node to view shared skills & credentials",
                    color = TextMuted,
                    fontSize = 11.sp,
                    modifier = Modifier
                        .align(Alignment.TopCenter)
                        .padding(top = 12.dp)
                )
            }
        }

        // Selected Student Node Detail Card
        selectedProfile?.let { student ->
            Card(
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = CharcoalSurface),
                border = androidx.compose.foundation.BorderStroke(1.dp, ElectricVioletLight),
                modifier = Modifier.fillMaxWidth()
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
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(38.dp)
                                    .clip(CircleShape)
                                    .background(Brush.linearGradient(listOf(ElectricViolet, CyanAccent))),
                                contentAlignment = Alignment.Center
                            ) {
                                Text(
                                    text = student.fullName.take(1).uppercase(),
                                    color = White,
                                    fontSize = 15.sp,
                                    fontWeight = FontWeight.Bold
                                )
                            }
                            Column {
                                Text(student.fullName, color = TextPrimary, fontSize = 14.sp, fontWeight = FontWeight.Bold)
                                Text("${student.branch} • ${student.academicYear}", color = TextSecondary, fontSize = 11.sp)
                            }
                        }

                        ManitVerificationBadge(
                            isVerified = student.isManitVerified,
                            status = student.membershipStatus,
                            scholarNumber = student.scholarNumber
                        )
                    }

                    if (student.bio.isNotBlank()) {
                        Text(student.bio, color = TextSecondary, fontSize = 12.sp, maxLines = 2)
                    }

                    FlowRow(
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                        verticalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        student.skills.forEach { skill ->
                            SkillChip(skill = skill)
                        }
                    }

                    Button(
                        onClick = { onStudentSelect(student) },
                        colors = ButtonDefaults.buttonColors(containerColor = ElectricViolet),
                        shape = RoundedCornerShape(10.dp),
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(40.dp)
                    ) {
                        Text("Connect / View Profile", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun TeamCard(
    team: Team,
    currentUserSkills: List<String>,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = CharcoalSurface),
        border = androidx.compose.foundation.BorderStroke(1.dp, CharcoalBorder),
        modifier = modifier
            .fillMaxWidth()
            .clickable { onClick() }
            .testTag("team_card_${team.id}")
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
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(6.dp))
                            .background(CyanSubtle)
                            .padding(horizontal = 7.dp, vertical = 2.dp)
                    ) {
                        Text(
                            text = team.eventName,
                            color = CyanLight,
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                    Text(
                        text = "• ${team.projectCategory.displayName}",
                        color = TextMuted,
                        fontSize = 11.sp
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
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )

            Text(
                text = team.description,
                color = TextSecondary,
                fontSize = 12.sp,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                lineHeight = 17.sp
            )

            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                team.requiredSkills.forEach { skill ->
                    val matchesMe = currentUserSkills.any { it.equals(skill, ignoreCase = true) }
                    SkillChip(
                        skill = skill,
                        isSelected = matchesMe
                    )
                }
            }

            Divider(color = CharcoalDivider, thickness = 0.8.dp)

            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .size(28.dp)
                            .clip(CircleShape)
                            .background(CharcoalSurfaceVariant),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = team.ownerName.take(1).uppercase(),
                            color = ElectricVioletLight,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                    Column {
                        Text(
                            text = team.ownerName,
                            color = TextPrimary,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.SemiBold
                        )
                        ManitVerificationBadge(
                            isVerified = team.ownerIsManitVerified,
                            scholarNumber = team.ownerScholar
                        )
                    }
                }

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Text(
                        text = "View Details",
                        color = ElectricVioletLight,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold
                    )
                    Icon(
                        Icons.Default.ChevronRight,
                        contentDescription = null,
                        tint = ElectricVioletLight,
                        modifier = Modifier.size(16.dp)
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun StudentCard(
    student: UserProfile,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = CharcoalSurface),
        border = androidx.compose.foundation.BorderStroke(1.dp, CharcoalBorder),
        modifier = modifier
            .fillMaxWidth()
            .clickable { onClick() }
            .testTag("student_card_${student.id}")
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
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .size(38.dp)
                            .clip(CircleShape)
                            .background(
                                Brush.linearGradient(
                                    listOf(ElectricViolet, CyanAccent)
                                )
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = student.fullName.take(1).uppercase(),
                            color = White,
                            fontSize = 15.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                    Column {
                        Text(
                            text = student.fullName,
                            color = TextPrimary,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = "${student.branch} • ${student.academicYear}",
                            color = TextSecondary,
                            fontSize = 11.sp
                        )
                    }
                }

                ManitVerificationBadge(
                    isVerified = student.isManitVerified,
                    status = student.membershipStatus,
                    scholarNumber = student.scholarNumber
                )
            }

            if (student.bio.isNotBlank()) {
                Text(
                    text = student.bio,
                    color = TextSecondary,
                    fontSize = 12.sp,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
            }

            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                student.skills.take(5).forEach { skill ->
                    SkillChip(skill = skill)
                }
            }
        }
    }
}

