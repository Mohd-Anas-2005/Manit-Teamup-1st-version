package com.example.data.model

enum class MembershipStatus(val displayName: String) {
    MANIT_STUDENT("MANIT Student"),
    OTHER_COLLEGE("Student (Other College)"),
    NON_STUDENT("Visiting / Non-Student")
}

enum class ProjectCategory(val displayName: String) {
    HACKATHON("Hackathon"),
    ACADEMIC_PROJECT("College Project"),
    STARTUP("Startup Venture"),
    AI_ML("AI / ML Research"),
    OPEN_SOURCE("Open Source"),
    COMPETITIVE_PROGRAMMING("Coding Contest")
}

enum class TeamRole(val label: String) {
    OWNER("Lead / Owner"),
    LEAD("Co-Lead"),
    MEMBER("Teammate")
}

enum class RequestStatus(val label: String) {
    PENDING("Pending Review"),
    ACCEPTED("Accepted"),
    REJECTED("Declined"),
    WITHDRAWN("Withdrawn")
}

enum class NotificationType {
    JOIN_REQUEST,
    REQUEST_ACCEPTED,
    REQUEST_REJECTED,
    REQUEST_WITHDRAWN,
    TEAM_ANNOUNCEMENT,
    DIRECT_MESSAGE
}

data class UserProfile(
    val id: String,
    val email: String,
    val fullName: String,
    val avatarUrl: String? = null,
    val collegeName: String = "MANIT Bhopal",
    val isManitVerified: Boolean = false,
    val membershipStatus: MembershipStatus = MembershipStatus.MANIT_STUDENT,
    val scholarNumber: String? = null,
    val branch: String = "Computer Science & Engineering",
    val academicYear: String = "1st Year B.Tech",
    val bio: String = "",
    val skills: List<String> = emptyList(),
    val interests: List<String> = emptyList(),
    val githubUrl: String? = null,
    val linkedinUrl: String? = null,
    val portfolioUrl: String? = null,
    val whatsappNumber: String? = null,
    val isProfilePublic: Boolean = true,
    val allowWhatsAppDirect: Boolean = true
)

data class TeamMember(
    val userId: String,
    val fullName: String,
    val role: TeamRole = TeamRole.MEMBER,
    val branch: String,
    val academicYear: String,
    val isManitVerified: Boolean,
    val skills: List<String> = emptyList(),
    val whatsappNumber: String? = null
)

data class Team(
    val id: String,
    val ownerId: String,
    val ownerName: String,
    val ownerScholar: String? = null,
    val ownerIsManitVerified: Boolean = true,
    val title: String,
    val description: String,
    val projectCategory: ProjectCategory,
    val eventName: String,
    val requiredSkills: List<String>,
    val maxTeamSize: Int,
    val isRecruiting: Boolean = true,
    val members: List<TeamMember> = emptyList(),
    val whatsappGroupLink: String? = null,
    val createdAt: Long = System.currentTimeMillis()
) {
    val vacanciesLeft: Int
        get() = (maxTeamSize - members.size).coerceAtLeast(0)

    val isFull: Boolean
        get() = vacanciesLeft == 0
}

data class JoinRequest(
    val id: String,
    val teamId: String,
    val teamTitle: String,
    val applicantId: String,
    val applicantName: String,
    val applicantBranch: String,
    val applicantYear: String,
    val applicantCollege: String,
    val applicantIsManitVerified: Boolean,
    val applicantSkills: List<String>,
    val pitchNote: String,
    val status: RequestStatus = RequestStatus.PENDING,
    val createdAt: Long = System.currentTimeMillis()
)

data class ChatMessage(
    val id: String,
    val teamId: String? = null,
    val senderId: String,
    val senderName: String,
    val senderIsManitVerified: Boolean,
    val receiverId: String? = null,
    val content: String,
    val timestamp: Long = System.currentTimeMillis()
)

data class AppNotification(
    val id: String,
    val recipientId: String,
    val type: NotificationType,
    val title: String,
    val body: String,
    val referenceId: String? = null,
    val teamTitle: String? = null,
    val actorName: String? = null,
    val isRead: Boolean = false,
    val timestamp: Long = System.currentTimeMillis()
)
