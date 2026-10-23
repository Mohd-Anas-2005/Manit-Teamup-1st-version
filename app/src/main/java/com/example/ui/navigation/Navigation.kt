package com.example.ui.navigation

sealed class Screen {
    object Splash : Screen()
    object Auth : Screen()
    data class VerifyOtp(val email: String) : Screen()
    object CompleteProfile : Screen()
    object Discover : Screen()
    object MyTeams : Screen()
    object CreateTeam : Screen()
    object Inbox : Screen()
    object Profile : Screen()
    data class TeamDetail(val teamId: String) : Screen()
    data class ChatRoom(val teamId: String, val title: String) : Screen()
    data class EditTeam(val teamId: String) : Screen()
    object SettingsAndSafety : Screen()
}

enum class MainTab(val label: String) {
    DISCOVER("Discover"),
    MY_TEAMS("My Teams"),
    CREATE("Create"),
    INBOX("Inbox"),
    PROFILE("Profile")
}
