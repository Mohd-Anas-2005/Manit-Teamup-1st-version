package com.example

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.repository.ManitRepository
import com.example.ui.components.AppHeader
import com.example.ui.navigation.MainTab
import com.example.ui.navigation.Screen
import com.example.ui.screens.*
import com.example.ui.theme.*

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            ManitTeamUpTheme {
                MainAppHost()
            }
        }
    }
}

@Composable
fun MainAppHost() {
    var screenStack by remember { mutableStateOf<List<Screen>>(listOf(Screen.Splash)) }
    var currentTab by remember { mutableStateOf(MainTab.DISCOVER) }

    val currentScreen = screenStack.lastOrNull() ?: Screen.Splash
    val currentUser by ManitRepository.currentUser.collectAsState()
    val notifications by ManitRepository.notifications.collectAsState()

    val unreadNotifsCount = remember(notifications, currentUser) {
        notifications.count { it.recipientId == currentUser?.id && !it.isRead }
    }

    fun pushScreen(screen: Screen) {
        screenStack = screenStack + screen
    }

    fun popScreen() {
        if (screenStack.size > 1) {
            screenStack = screenStack.dropLast(1)
        }
    }

    fun navigateRoot(screen: Screen) {
        screenStack = listOf(screen)
    }

    // Secondary screen back handler
    if (screenStack.size > 1) {
        BackHandler {
            popScreen()
        }
    }

    val isTopLevelScreen = currentScreen is Screen.Discover ||
            currentScreen is Screen.MyTeams ||
            currentScreen is Screen.Inbox ||
            currentScreen is Screen.Profile

    Scaffold(
        modifier = Modifier.fillMaxSize(),
        containerColor = MidnightNavy,
        topBar = {
            if (isTopLevelScreen && currentUser != null) {
                AppHeader(
                    title = when (currentTab) {
                        MainTab.DISCOVER -> "Teammate & Project Discovery"
                        MainTab.MY_TEAMS -> "Team Workspace & Requests"
                        MainTab.CREATE -> "Launch New Team"
                        MainTab.INBOX -> "Team Chat & Channels"
                        MainTab.PROFILE -> "Student Profile & Credentials"
                    },
                    unreadNotificationsCount = unreadNotifsCount,
                    onNotificationsClick = {
                        currentTab = MainTab.INBOX
                        navigateRoot(Screen.Inbox)
                    },
                    onProfileClick = {
                        currentTab = MainTab.PROFILE
                        navigateRoot(Screen.Profile)
                    }
                )
            }
        },
        bottomBar = {
            if (isTopLevelScreen && currentUser != null) {
                TeamUpBottomNav(
                    currentTab = currentTab,
                    unreadNotifs = unreadNotifsCount,
                    onTabSelected = { tab ->
                        currentTab = tab
                        when (tab) {
                            MainTab.DISCOVER -> navigateRoot(Screen.Discover)
                            MainTab.MY_TEAMS -> navigateRoot(Screen.MyTeams)
                            MainTab.CREATE -> pushScreen(Screen.CreateTeam)
                            MainTab.INBOX -> navigateRoot(Screen.Inbox)
                            MainTab.PROFILE -> navigateRoot(Screen.Profile)
                        }
                    }
                )
            }
        }
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            when (val screen = currentScreen) {
                is Screen.Splash -> {
                    SplashScreen(
                        onNavigateToAuth = { navigateRoot(Screen.Auth) },
                        onNavigateToMain = {
                            currentTab = MainTab.DISCOVER
                            navigateRoot(Screen.Discover)
                        }
                    )
                }

                is Screen.Auth -> {
                    AuthScreen(
                        onLoginSuccess = {
                            currentTab = MainTab.DISCOVER
                            navigateRoot(Screen.Discover)
                        },
                        onNeedsOtpVerification = { email ->
                            pushScreen(Screen.VerifyOtp(email))
                        }
                    )
                }

                is Screen.VerifyOtp -> {
                    VerifyOtpScreen(
                        email = screen.email,
                        onVerificationSuccess = {
                            currentTab = MainTab.DISCOVER
                            navigateRoot(Screen.Discover)
                        },
                        onBackToAuth = { popScreen() }
                    )
                }

                is Screen.Discover -> {
                    DiscoverScreen(
                        onTeamClick = { teamId -> pushScreen(Screen.TeamDetail(teamId)) },
                        onStudentClick = { studentId ->
                            // View details
                        },
                        onCreateTeamClick = { pushScreen(Screen.CreateTeam) }
                    )
                }

                is Screen.MyTeams -> {
                    MyTeamsScreen(
                        onTeamClick = { teamId -> pushScreen(Screen.TeamDetail(teamId)) },
                        onOpenChat = { teamId, title -> pushScreen(Screen.ChatRoom(teamId, title)) },
                        onCreateTeamClick = { pushScreen(Screen.CreateTeam) }
                    )
                }

                is Screen.CreateTeam -> {
                    CreateEditTeamScreen(
                        editingTeamId = null,
                        onFinished = {
                            popScreen()
                            currentTab = MainTab.MY_TEAMS
                            navigateRoot(Screen.MyTeams)
                        },
                        onBack = { popScreen() }
                    )
                }

                is Screen.EditTeam -> {
                    CreateEditTeamScreen(
                        editingTeamId = screen.teamId,
                        onFinished = { popScreen() },
                        onBack = { popScreen() }
                    )
                }

                is Screen.Inbox -> {
                    InboxScreen(
                        onOpenTeamChat = { teamId, title -> pushScreen(Screen.ChatRoom(teamId, title)) }
                    )
                }

                is Screen.Profile -> {
                    ProfileScreen(
                        onSignOut = {
                            navigateRoot(Screen.Auth)
                        }
                    )
                }

                is Screen.TeamDetail -> {
                    TeamDetailScreen(
                        teamId = screen.teamId,
                        onBack = { popScreen() },
                        onOpenTeamChat = { teamId, title -> pushScreen(Screen.ChatRoom(teamId, title)) },
                        onEditTeam = { teamId -> pushScreen(Screen.EditTeam(teamId)) }
                    )
                }

                is Screen.ChatRoom -> {
                    ChatRoomScreen(
                        teamId = screen.teamId,
                        title = screen.title,
                        onBack = { popScreen() }
                    )
                }

                else -> {
                    DiscoverScreen(
                        onTeamClick = { teamId -> pushScreen(Screen.TeamDetail(teamId)) },
                        onStudentClick = {},
                        onCreateTeamClick = { pushScreen(Screen.CreateTeam) }
                    )
                }
            }
        }
    }
}

@Composable
fun TeamUpBottomNav(
    currentTab: MainTab,
    unreadNotifs: Int,
    onTabSelected: (MainTab) -> Unit,
    modifier: Modifier = Modifier
) {
    Surface(
        color = CharcoalSurface,
        tonalElevation = 8.dp,
        border = androidx.compose.foundation.BorderStroke(1.dp, CharcoalBorder),
        modifier = modifier
            .fillMaxWidth()
            .navigationBarsPadding()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 8.dp, vertical = 6.dp),
            horizontalArrangement = Arrangement.SpaceAround,
            verticalAlignment = Alignment.CenterVertically
        ) {
            NavTabItem(
                label = "Discover",
                icon = Icons.Default.Explore,
                isSelected = currentTab == MainTab.DISCOVER,
                onClick = { onTabSelected(MainTab.DISCOVER) },
                testTag = "nav_tab_discover"
            )

            NavTabItem(
                label = "My Teams",
                icon = Icons.Default.Groups,
                isSelected = currentTab == MainTab.MY_TEAMS,
                onClick = { onTabSelected(MainTab.MY_TEAMS) },
                testTag = "nav_tab_my_teams"
            )

            // Distinctive Center Action Button for Team Creation
            Box(
                modifier = Modifier
                    .size(46.dp)
                    .clip(CircleShape)
                    .background(
                        Brush.linearGradient(
                            listOf(ElectricViolet, MagentaAccent, CyanAccent)
                        )
                    )
                    .clickable { onTabSelected(MainTab.CREATE) }
                    .testTag("nav_btn_create_team"),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.Add,
                    contentDescription = "Create Team",
                    tint = White,
                    modifier = Modifier.size(26.dp)
                )
            }

            NavTabItem(
                label = "Inbox",
                icon = Icons.Default.Forum,
                isSelected = currentTab == MainTab.INBOX,
                badgeCount = unreadNotifs,
                onClick = { onTabSelected(MainTab.INBOX) },
                testTag = "nav_tab_inbox"
            )

            NavTabItem(
                label = "Profile",
                icon = Icons.Default.Person,
                isSelected = currentTab == MainTab.PROFILE,
                onClick = { onTabSelected(MainTab.PROFILE) },
                testTag = "nav_tab_profile"
            )
        }
    }
}

@Composable
fun NavTabItem(
    label: String,
    icon: ImageVector,
    isSelected: Boolean,
    badgeCount: Int = 0,
    onClick: () -> Unit,
    testTag: String
) {
    val tint = if (isSelected) ElectricVioletLight else TextMuted

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
        modifier = Modifier
            .clip(RoundedCornerShape(12.dp))
            .clickable { onClick() }
            .padding(horizontal = 10.dp, vertical = 4.dp)
            .testTag(testTag)
    ) {
        BadgedBox(
            badge = {
                if (badgeCount > 0) {
                    Badge(
                        containerColor = CoralAccent,
                        contentColor = White
                    ) {
                        Text("$badgeCount")
                    }
                }
            }
        ) {
            Icon(
                imageVector = icon,
                contentDescription = label,
                tint = tint,
                modifier = Modifier.size(22.dp)
            )
        }

        Spacer(modifier = Modifier.height(2.dp))

        Text(
            text = label,
            color = tint,
            fontSize = 11.sp,
            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium
        )
    }
}
