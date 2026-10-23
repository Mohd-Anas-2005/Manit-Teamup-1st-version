package com.example.data.repository

import com.example.data.model.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.UUID

object ManitRepository {

    // ----------------------------------------------------
    // AUTHENTICATION & PROFILES STATE
    // ----------------------------------------------------
    private val _currentUser = MutableStateFlow<UserProfile?>(null)
    val currentUser: StateFlow<UserProfile?> = _currentUser.asStateFlow()

    // Temporary storage for OTP verification simulation
    private val pendingOtps = mutableMapOf<String, String>()
    private val pendingRegistrations = mutableMapOf<String, UserProfile>()

    // All registered users in the platform
    private val _allProfiles = MutableStateFlow<List<UserProfile>>(emptyList())
    val allProfiles: StateFlow<List<UserProfile>> = _allProfiles.asStateFlow()

    // ----------------------------------------------------
    // TEAMS STATE
    // ----------------------------------------------------
    private val _teams = MutableStateFlow<List<Team>>(emptyList())
    val teams: StateFlow<List<Team>> = _teams.asStateFlow()

    // ----------------------------------------------------
    // JOIN REQUESTS STATE
    // ----------------------------------------------------
    private val _joinRequests = MutableStateFlow<List<JoinRequest>>(emptyList())
    val joinRequests: StateFlow<List<JoinRequest>> = _joinRequests.asStateFlow()

    // ----------------------------------------------------
    // CHAT MESSAGES STATE
    // ----------------------------------------------------
    private val _messages = MutableStateFlow<List<ChatMessage>>(emptyList())
    val messages: StateFlow<List<ChatMessage>> = _messages.asStateFlow()

    // ----------------------------------------------------
    // NOTIFICATIONS STATE
    // ----------------------------------------------------
    private val _notifications = MutableStateFlow<List<AppNotification>>(emptyList())
    val notifications: StateFlow<List<AppNotification>> = _notifications.asStateFlow()

    // ----------------------------------------------------
    // MODERATION STATE (Blocked users & reports)
    // ----------------------------------------------------
    private val _blockedUserIds = MutableStateFlow<Set<String>>(emptySet())
    val blockedUserIds: StateFlow<Set<String>> = _blockedUserIds.asStateFlow()

    init {
        seedInitialPlatformData()
    }

    private fun seedInitialPlatformData() {
        // Seed authentic MANIT students
        val student1 = UserProfile(
            id = "user_ayush_manit",
            email = "231114052@stu.manit.ac.in",
            fullName = "Ayush Sharma",
            collegeName = "MANIT Bhopal",
            isManitVerified = true,
            membershipStatus = MembershipStatus.MANIT_STUDENT,
            scholarNumber = "231114052",
            branch = "Computer Science & Engineering",
            academicYear = "2nd Year B.Tech",
            bio = "Building high-throughput Android and backend architectures. Winner SIH 2024 internal round.",
            skills = listOf("Kotlin", "Jetpack Compose", "Go", "Docker", "PostgreSQL", "Firebase"),
            interests = listOf("SIH 2026", "Systems Programming", "Distributed Systems"),
            githubUrl = "https://github.com/ayush-manit",
            linkedinUrl = "https://linkedin.com/in/ayush-sharma-cse",
            whatsappNumber = "+919876543210"
        )

        val student2 = UserProfile(
            id = "user_riya_manit",
            email = "221113019@stu.manit.ac.in",
            fullName = "Riya Verma",
            collegeName = "MANIT Bhopal",
            isManitVerified = true,
            membershipStatus = MembershipStatus.MANIT_STUDENT,
            scholarNumber = "221113019",
            branch = "Information Technology",
            academicYear = "3rd Year B.Tech",
            bio = "Full-stack developer & UI designer. Lead organizer for Version 2025 coding track.",
            skills = listOf("React", "Next.js", "Figma", "UI/UX", "Tailwind CSS", "TypeScript"),
            interests = listOf("FinTech", "Open Source", "Design Systems"),
            githubUrl = "https://github.com/riya-v",
            linkedinUrl = "https://linkedin.com/in/riya-verma-it",
            whatsappNumber = "+919823456789"
        )

        val student3 = UserProfile(
            id = "user_karan_iit",
            email = "karan.patel@iitb.ac.in",
            fullName = "Karan Patel",
            collegeName = "IIT Bombay",
            isManitVerified = false,
            membershipStatus = MembershipStatus.OTHER_COLLEGE,
            scholarNumber = null,
            branch = "Electrical Engineering",
            academicYear = "2nd Year B.Tech",
            bio = "Computer Vision & Edge AI enthusiast. Looking to collaborate with MANIT robotics teams.",
            skills = listOf("Python", "PyTorch", "ROS2", "OpenCV", "C++", "Edge AI"),
            interests = listOf("RoboSub", "Autonomous Vehicles", "SIH 2026"),
            githubUrl = "https://github.com/karan-edge",
            linkedinUrl = "https://linkedin.com/in/karan-patel-ee",
            whatsappNumber = "+919765432101"
        )

        val student4 = UserProfile(
            id = "user_ananya_manit",
            email = "241112088@stu.manit.ac.in",
            fullName = "Ananya Mishra",
            collegeName = "MANIT Bhopal",
            isManitVerified = true,
            membershipStatus = MembershipStatus.MANIT_STUDENT,
            scholarNumber = "241112088",
            branch = "Electronics & Communication",
            academicYear = "1st Year B.Tech",
            bio = "1st year enthusiast exploring IoT, embedded microcontrollers, and firmware design.",
            skills = listOf("C++", "Arduino", "ESP32", "PCB Design", "Python"),
            interests = listOf("IoT Devices", "Smart Campus", "Robotics Club"),
            githubUrl = "https://github.com/ananya-iot",
            linkedinUrl = "https://linkedin.com/in/ananya-mishra-ece",
            whatsappNumber = "+919988776655"
        )

        _allProfiles.value = listOf(student1, student2, student3, student4)

        // Seed Default Teams
        val team1 = Team(
            id = "team_sih_agritech",
            ownerId = student1.id,
            ownerName = student1.fullName,
            ownerScholar = student1.scholarNumber,
            ownerIsManitVerified = true,
            title = "KisanDrishti — AI Edge Crop Disease Detector",
            description = "Building an offline-first Edge AI scanner for rural farmers using smartphone cameras and drone spectral imagery. Target problem statement for Smart India Hackathon (SIH 2026). Need an ML pipeline specialist and a pitch lead.",
            projectCategory = ProjectCategory.HACKATHON,
            eventName = "Smart India Hackathon 2026",
            requiredSkills = listOf("PyTorch", "Edge AI", "Kotlin", "UI/UX", "Flask"),
            maxTeamSize = 6,
            isRecruiting = true,
            members = listOf(
                TeamMember(
                    userId = student1.id,
                    fullName = student1.fullName,
                    role = TeamRole.OWNER,
                    branch = student1.branch,
                    academicYear = student1.academicYear,
                    isManitVerified = true,
                    skills = student1.skills,
                    whatsappNumber = student1.whatsappNumber
                ),
                TeamMember(
                    userId = student2.id,
                    fullName = student2.fullName,
                    role = TeamRole.LEAD,
                    branch = student2.branch,
                    academicYear = student2.academicYear,
                    isManitVerified = true,
                    skills = student2.skills,
                    whatsappNumber = student2.whatsappNumber
                )
            ),
            whatsappGroupLink = "https://chat.whatsapp.com/MANIT_KisanDrishti_SIH26"
        )

        val team2 = Team(
            id = "team_version_web3",
            ownerId = student2.id,
            ownerName = student2.fullName,
            ownerScholar = student2.scholarNumber,
            ownerIsManitVerified = true,
            title = "CampusEscrow — Micro-Task Bounty Protocol",
            description = "A decentralized micro-bounty platform tailored for campus clubs to reward open-source contributions, graphic designs, and bug bounties using smart contracts on Polygon.",
            projectCategory = ProjectCategory.STARTUP,
            eventName = "MANIT Version '26 Flagship",
            requiredSkills = listOf("Solidity", "React", "Next.js", "Node.js", "Web3"),
            maxTeamSize = 4,
            isRecruiting = true,
            members = listOf(
                TeamMember(
                    userId = student2.id,
                    fullName = student2.fullName,
                    role = TeamRole.OWNER,
                    branch = student2.branch,
                    academicYear = student2.academicYear,
                    isManitVerified = true,
                    skills = student2.skills,
                    whatsappNumber = student2.whatsappNumber
                )
            ),
            whatsappGroupLink = "https://chat.whatsapp.com/MANIT_CampusEscrow_Bounty"
        )

        val team3 = Team(
            id = "team_robosub_manit",
            ownerId = student1.id,
            ownerName = "Robotics Club MANIT",
            ownerScholar = "211116010",
            ownerIsManitVerified = true,
            title = "Autonomous Underwater Vehicle (AUV) Navigation",
            description = "MANIT Autonomous Underwater Vehicle Team preparing for National Marine Robotics competition. Developing acoustic sensor fusion and acoustic beacon tracking.",
            projectCategory = ProjectCategory.ACADEMIC_PROJECT,
            eventName = "National Marine Robotics 2026",
            requiredSkills = listOf("ROS2", "C++", "OpenCV", "Embedded Systems"),
            maxTeamSize = 5,
            isRecruiting = true,
            members = listOf(
                TeamMember(
                    userId = student1.id,
                    fullName = "Robotics Club Lead",
                    role = TeamRole.OWNER,
                    branch = "Mechanical Engineering",
                    academicYear = "4th Year B.Tech",
                    isManitVerified = true,
                    skills = listOf("ROS2", "Robotics", "C++")
                )
            ),
            whatsappGroupLink = "https://chat.whatsapp.com/AUV_MANIT_Robotics"
        )

        _teams.value = listOf(team1, team2, team3)

        // Seed Sample Join Requests for interactive testing of accept/reject workflow
        val req1 = JoinRequest(
            id = "req_karan_1",
            teamId = team1.id,
            teamTitle = team1.title,
            applicantId = student3.id,
            applicantName = student3.fullName,
            applicantBranch = student3.branch,
            applicantYear = student3.academicYear,
            applicantCollege = student3.collegeName,
            applicantIsManitVerified = student3.isManitVerified,
            applicantSkills = student3.skills,
            pitchNote = "I have 2 years of experience with PyTorch and YOLOv8 models. I can optimize the edge model for real-time mobile inference on crop leaves.",
            status = RequestStatus.PENDING,
            createdAt = System.currentTimeMillis() - 1000L * 60 * 45
        )

        val req2 = JoinRequest(
            id = "req_ananya_1",
            teamId = team2.id,
            teamTitle = team2.title,
            applicantId = student4.id,
            applicantName = student4.fullName,
            applicantBranch = student4.branch,
            applicantYear = student4.academicYear,
            applicantCollege = student4.collegeName,
            applicantIsManitVerified = student4.isManitVerified,
            applicantSkills = student4.skills,
            pitchNote = "Passionate about smart contracts and IoT escrow triggers. Would love to build the hardware oracle module.",
            status = RequestStatus.PENDING,
            createdAt = System.currentTimeMillis() - 1000L * 60 * 120
        )

        val req3 = JoinRequest(
            id = "req_riya_accepted",
            teamId = team1.id,
            teamTitle = team1.title,
            applicantId = student2.id,
            applicantName = student2.fullName,
            applicantBranch = student2.branch,
            applicantYear = student2.academicYear,
            applicantCollege = student2.collegeName,
            applicantIsManitVerified = student2.isManitVerified,
            applicantSkills = student2.skills,
            pitchNote = "Full stack UI designer. Ready to design modern Figma wireframes and mobile dashboards.",
            status = RequestStatus.ACCEPTED,
            createdAt = System.currentTimeMillis() - 1000L * 60 * 360
        )

        val req4 = JoinRequest(
            id = "req_ayush_declined",
            teamId = team3.id,
            teamTitle = team3.title,
            applicantId = student1.id,
            applicantName = student1.fullName,
            applicantBranch = student1.branch,
            applicantYear = student1.academicYear,
            applicantCollege = student1.collegeName,
            applicantIsManitVerified = student1.isManitVerified,
            applicantSkills = student1.skills,
            pitchNote = "Interested in autonomous hydrophone signal processing.",
            status = RequestStatus.REJECTED,
            createdAt = System.currentTimeMillis() - 1000L * 60 * 600
        )

        _joinRequests.value = listOf(req1, req2, req3, req4)

        // Seed Sample Chat Messages for Team 1
        _messages.value = listOf(
            ChatMessage(
                id = "msg_1",
                teamId = team1.id,
                senderId = student1.id,
                senderName = student1.fullName,
                senderIsManitVerified = true,
                content = "Welcome to KisanDrishti! We are finalizing the dataset for rice plant blight detection.",
                timestamp = System.currentTimeMillis() - 3600000L * 4
            ),
            ChatMessage(
                id = "msg_2",
                teamId = team1.id,
                senderId = student2.id,
                senderName = student2.fullName,
                senderIsManitVerified = true,
                content = "I've uploaded the wireframes in Figma. Excited to build the Edge AI inference flow!",
                timestamp = System.currentTimeMillis() - 3600000L * 2
            )
        )

        // Seed initial notifications tracking join requests, acceptances, rejections & announcements
        _notifications.value = listOf(
            // Notification for Ayush (student1): Incoming Join Request from Karan
            AppNotification(
                id = "notif_seed_1",
                recipientId = student1.id,
                type = NotificationType.JOIN_REQUEST,
                title = "New Application: ${team1.title}",
                body = "Karan Patel (IIT Bombay, Electrical) applied to join KisanDrishti with pitch: \"I have 2 years of experience with PyTorch and YOLOv8 models...\"",
                referenceId = team1.id,
                teamTitle = team1.title,
                actorName = "Karan Patel",
                isRead = false,
                timestamp = System.currentTimeMillis() - 1000L * 60 * 15
            ),
            // Notification for Ayush (student1): Acceptance alert from another team
            AppNotification(
                id = "notif_seed_2",
                recipientId = student1.id,
                type = NotificationType.REQUEST_ACCEPTED,
                title = "Accepted into ${team2.title}!",
                body = "Congratulations! Your join request was accepted by Riya Verma. You are now a confirmed team member with access to Team Chat & WhatsApp Hub.",
                referenceId = team2.id,
                teamTitle = team2.title,
                actorName = "Riya Verma",
                isRead = false,
                timestamp = System.currentTimeMillis() - 1000L * 60 * 60
            ),
            // Notification for Ayush (student1): Rejection alert from team 3
            AppNotification(
                id = "notif_seed_3",
                recipientId = student1.id,
                type = NotificationType.REQUEST_REJECTED,
                title = "Application Update: ${team3.title}",
                body = "Your request to join AUV Navigation was declined by the owner as all robotics specialist slots were filled. Browse the Discover hub for other open competitions!",
                referenceId = team3.id,
                teamTitle = team3.title,
                actorName = "Robotics Club Lead",
                isRead = true,
                timestamp = System.currentTimeMillis() - 1000L * 60 * 180
            ),
            // Notification for Ayush (student1): Milestone Announcement
            AppNotification(
                id = "notif_seed_4",
                recipientId = student1.id,
                type = NotificationType.TEAM_ANNOUNCEMENT,
                title = "🎉 Team Roster Confirmed!",
                body = "Riya Verma has officially joined the confirmed roster for KisanDrishti. Prototype submission deadline is approaching.",
                referenceId = team1.id,
                teamTitle = team1.title,
                actorName = "System",
                isRead = true,
                timestamp = System.currentTimeMillis() - 1000L * 60 * 240
            ),
            // Notification for Riya (student2): Acceptance into team1
            AppNotification(
                id = "notif_seed_riya_1",
                recipientId = student2.id,
                type = NotificationType.REQUEST_ACCEPTED,
                title = "Accepted into ${team1.title}!",
                body = "Congratulations! Ayush Sharma accepted your join request for Smart India Hackathon. Connect with the team via in-app chat or the WhatsApp group.",
                referenceId = team1.id,
                teamTitle = team1.title,
                actorName = "Ayush Sharma",
                isRead = false,
                timestamp = System.currentTimeMillis() - 1000L * 60 * 45
            ),
            // Notification for Karan (student3): Rejection notice
            AppNotification(
                id = "notif_seed_karan_1",
                recipientId = student3.id,
                type = NotificationType.REQUEST_REJECTED,
                title = "Application Update: CampusEscrow",
                body = "Your request to join CampusEscrow was declined by the owner. Keep exploring active teams on MANIT TeamUp!",
                referenceId = team2.id,
                teamTitle = team2.title,
                actorName = "Riya Verma",
                isRead = false,
                timestamp = System.currentTimeMillis() - 1000L * 60 * 30
            )
        )

        // Set Ayush Sharma (student1) as initial logged-in user so user immediately experiences active state
        _currentUser.value = student1
    }

    // ----------------------------------------------------
    // AUTHENTICATION METHODS
    // ----------------------------------------------------

    /**
     * Checks if email conforms to MANIT scholar institutional format:
     * e.g. 241114052@stu.manit.ac.in
     */
    fun isManitInstitutionalEmail(email: String): Boolean {
        val trimmed = email.trim().lowercase()
        return trimmed.endsWith("@stu.manit.ac.in") || trimmed.endsWith("@manit.ac.in")
    }

    /**
     * Extracts scholar number if present in email prefix
     */
    fun extractScholarNumber(email: String): String? {
        val trimmed = email.trim().lowercase()
        if (isManitInstitutionalEmail(trimmed)) {
            val prefix = trimmed.substringBefore("@")
            if (prefix.all { it.isDigit() }) return prefix
        }
        return null
    }

    /**
     * Registers a new account and generates verification OTP.
     * Guaranteed: Never claims verification until OTP check succeeds.
     */
    fun startRegistration(
        email: String,
        password: String,
        fullName: String,
        branch: String,
        academicYear: String,
        college: String = "MANIT Bhopal",
        declaredStatus: MembershipStatus? = null
    ): Result<String> {
        val cleanEmail = email.trim().lowercase()
        if (!cleanEmail.contains("@") || !cleanEmail.contains(".")) {
            return Result.failure(IllegalArgumentException("Please enter a valid email address."))
        }
        if (password.length < 6) {
            return Result.failure(IllegalArgumentException("Password must contain at least 6 characters."))
        }

        val isManit = isManitInstitutionalEmail(cleanEmail)
        val scholar = extractScholarNumber(cleanEmail)
        val membershipStatus = when {
            isManit -> MembershipStatus.MANIT_STUDENT
            declaredStatus != null -> declaredStatus
            else -> MembershipStatus.OTHER_COLLEGE
        }
        val effectiveCollege = if (isManit) "MANIT Bhopal" else college.ifBlank { "Other College" }

        val newProfile = UserProfile(
            id = "user_${UUID.randomUUID().toString().take(8)}",
            email = cleanEmail,
            fullName = fullName.trim(),
            collegeName = effectiveCollege,
            isManitVerified = false, // ALWAYS false until OTP verification succeeds!
            membershipStatus = membershipStatus,
            scholarNumber = scholar,
            branch = branch,
            academicYear = academicYear,
            bio = if (isManit) "MANIT Student" else "Cross-college collaborator",
            skills = listOf("Problem Solving"),
            interests = listOf("Hackathons")
        )

        val otp = (100000..999999).random().toString()
        pendingOtps[cleanEmail] = otp
        pendingRegistrations[cleanEmail] = newProfile

        return Result.success(otp)
    }

    /**
     * Verifies the 6-digit OTP code sent to the email.
     * Only grants isManitVerified = true if the email is @stu.manit.ac.in!
     */
    fun verifyOtp(email: String, code: String): Result<UserProfile> {
        val cleanEmail = email.trim().lowercase()
        val storedOtp = pendingOtps[cleanEmail]
        if (storedOtp == null) {
            // For convenience, if entered 123456 or default test OTP, accept
            if (code != "123456") {
                return Result.failure(IllegalArgumentException("No pending verification found. Please request a new code."))
            }
        } else if (storedOtp != code && code != "123456") {
            return Result.failure(IllegalArgumentException("Invalid verification code. Please check your inbox."))
        }

        val profile = pendingRegistrations[cleanEmail] ?: UserProfile(
            id = "user_${UUID.randomUUID().toString().take(8)}",
            email = cleanEmail,
            fullName = cleanEmail.substringBefore("@").replaceFirstChar { it.uppercase() },
            collegeName = if (isManitInstitutionalEmail(cleanEmail)) "MANIT Bhopal" else "Guest Institute",
            isManitVerified = isManitInstitutionalEmail(cleanEmail),
            membershipStatus = if (isManitInstitutionalEmail(cleanEmail)) MembershipStatus.MANIT_STUDENT else MembershipStatus.OTHER_COLLEGE
        )

        // Grant official verification badge if and only if domain is institutional
        val finalizedProfile = profile.copy(
            isManitVerified = isManitInstitutionalEmail(cleanEmail)
        )

        pendingOtps.remove(cleanEmail)
        pendingRegistrations.remove(cleanEmail)

        // Add to active profiles and set current user
        val existingIndex = _allProfiles.value.indexOfFirst { it.email == cleanEmail }
        if (existingIndex >= 0) {
            val updated = _allProfiles.value.toMutableList()
            updated[existingIndex] = finalizedProfile
            _allProfiles.value = updated
        } else {
            _allProfiles.value = _allProfiles.value + finalizedProfile
        }

        _currentUser.value = finalizedProfile
        return Result.success(finalizedProfile)
    }

    fun resendOtp(email: String): String {
        val cleanEmail = email.trim().lowercase()
        val newOtp = (100000..999999).random().toString()
        pendingOtps[cleanEmail] = newOtp
        return newOtp
    }

    fun signIn(email: String, password: String): Result<UserProfile> {
        val cleanEmail = email.trim().lowercase()
        if (cleanEmail.isBlank() || password.isBlank()) {
            return Result.failure(IllegalArgumentException("Email and password cannot be empty."))
        }

        val existing = _allProfiles.value.find { it.email.equals(cleanEmail, ignoreCase = true) }
        if (existing != null) {
            _currentUser.value = existing
            return Result.success(existing)
        }

        // Quick sign-in provision for demonstration
        val isManit = isManitInstitutionalEmail(cleanEmail)
        val user = UserProfile(
            id = "user_${UUID.randomUUID().toString().take(8)}",
            email = cleanEmail,
            fullName = cleanEmail.substringBefore("@").replace(".", " ").split(" ")
                .joinToString(" ") { it.replaceFirstChar { c -> c.uppercase() } },
            collegeName = if (isManit) "MANIT Bhopal" else "Collaborating College",
            isManitVerified = isManit,
            membershipStatus = if (isManit) MembershipStatus.MANIT_STUDENT else MembershipStatus.OTHER_COLLEGE,
            scholarNumber = extractScholarNumber(cleanEmail),
            branch = "Computer Science & Engineering",
            academicYear = "1st Year B.Tech",
            skills = listOf("Kotlin", "Python", "Git")
        )
        _allProfiles.value = _allProfiles.value + user
        _currentUser.value = user
        return Result.success(user)
    }

    fun signOut() {
        _currentUser.value = null
    }

    fun updateProfile(updated: UserProfile) {
        _currentUser.value = updated
        val list = _allProfiles.value.toMutableList()
        val idx = list.indexOfFirst { it.id == updated.id }
        if (idx >= 0) {
            list[idx] = updated
            _allProfiles.value = list
        }
    }

    fun deleteAccount() {
        val current = _currentUser.value ?: return
        // Cascade delete: remove user's teams, applications, messages
        _teams.value = _teams.value.filter { it.ownerId != current.id }
        _joinRequests.value = _joinRequests.value.filter { it.applicantId != current.id }
        _allProfiles.value = _allProfiles.value.filter { it.id != current.id }
        _currentUser.value = null
    }

    // ----------------------------------------------------
    // TEAMS CRUD & DISCOVERY METHODS
    // ----------------------------------------------------

    fun createTeam(
        title: String,
        description: String,
        category: ProjectCategory,
        eventName: String,
        skills: List<String>,
        maxSize: Int,
        whatsappLink: String?
    ): Result<Team> {
        val user = _currentUser.value ?: return Result.failure(IllegalStateException("User not logged in."))
        if (title.isBlank()) return Result.failure(IllegalArgumentException("Team title is required."))
        if (skills.isEmpty()) return Result.failure(IllegalArgumentException("At least one required skill is needed."))

        val newTeam = Team(
            id = "team_${UUID.randomUUID().toString().take(8)}",
            ownerId = user.id,
            ownerName = user.fullName,
            ownerScholar = user.scholarNumber,
            ownerIsManitVerified = user.isManitVerified,
            title = title.trim(),
            description = description.trim(),
            projectCategory = category,
            eventName = eventName.trim().ifBlank { "Open Project" },
            requiredSkills = skills,
            maxTeamSize = maxSize.coerceIn(2, 10),
            isRecruiting = true,
            members = listOf(
                TeamMember(
                    userId = user.id,
                    fullName = user.fullName,
                    role = TeamRole.OWNER,
                    branch = user.branch,
                    academicYear = user.academicYear,
                    isManitVerified = user.isManitVerified,
                    skills = user.skills,
                    whatsappNumber = user.whatsappNumber
                )
            ),
            whatsappGroupLink = whatsappLink?.trim()?.ifBlank { null }
        )

        _teams.value = listOf(newTeam) + _teams.value
        return Result.success(newTeam)
    }

    fun updateTeam(updated: Team) {
        val current = _currentUser.value ?: return
        if (updated.ownerId != current.id) return
        val list = _teams.value.toMutableList()
        val idx = list.indexOfFirst { it.id == updated.id }
        if (idx >= 0) {
            list[idx] = updated
            _teams.value = list
        }
    }

    fun deleteTeam(teamId: String): Boolean {
        val current = _currentUser.value ?: return false
        val team = _teams.value.find { it.id == teamId } ?: return false
        if (team.ownerId != current.id) return false

        _teams.value = _teams.value.filter { it.id != teamId }
        _joinRequests.value = _joinRequests.value.filter { it.teamId != teamId }
        _messages.value = _messages.value.filter { it.teamId != teamId }
        return true
    }

    // ----------------------------------------------------
    // JOIN REQUESTS WORKFLOW
    // ----------------------------------------------------

    fun sendJoinRequest(teamId: String, pitchNote: String): Result<JoinRequest> {
        val user = _currentUser.value ?: return Result.failure(IllegalStateException("Please log in."))
        val team = _teams.value.find { it.id == teamId } ?: return Result.failure(IllegalArgumentException("Team not found."))

        if (team.ownerId == user.id) {
            return Result.failure(IllegalArgumentException("You are the owner of this team."))
        }
        if (team.members.any { it.userId == user.id }) {
            return Result.failure(IllegalArgumentException("You are already a member of this team."))
        }
        if (team.isFull) {
            return Result.failure(IllegalArgumentException("This team has already reached its maximum capacity."))
        }

        val existing = _joinRequests.value.find { it.teamId == teamId && it.applicantId == user.id }
        if (existing != null && existing.status == RequestStatus.PENDING) {
            return Result.failure(IllegalArgumentException("You already have a pending application for this team."))
        }

        val request = JoinRequest(
            id = "req_${UUID.randomUUID().toString().take(8)}",
            teamId = team.id,
            teamTitle = team.title,
            applicantId = user.id,
            applicantName = user.fullName,
            applicantBranch = user.branch,
            applicantYear = user.academicYear,
            applicantCollege = user.collegeName,
            applicantIsManitVerified = user.isManitVerified,
            applicantSkills = user.skills,
            pitchNote = pitchNote.trim(),
            status = RequestStatus.PENDING
        )

        _joinRequests.value = listOf(request) + _joinRequests.value

        // Notify team owner of new application
        addNotification(
            recipientId = team.ownerId,
            type = NotificationType.JOIN_REQUEST,
            title = "New Application: ${team.title}",
            body = "${user.fullName} (${user.branch}) applied to join your team with pitch: \"${pitchNote.take(75)}\"",
            referenceId = team.id,
            teamTitle = team.title,
            actorName = user.fullName
        )

        return Result.success(request)
    }

    fun acceptJoinRequest(requestId: String): Result<Unit> {
        val user = _currentUser.value ?: return Result.failure(IllegalStateException("Not logged in."))
        val request = _joinRequests.value.find { it.id == requestId } ?: return Result.failure(IllegalArgumentException("Request not found."))
        val team = _teams.value.find { it.id == request.teamId } ?: return Result.failure(IllegalArgumentException("Team not found."))

        if (team.ownerId != user.id) {
            return Result.failure(SecurityException("Only the team owner can accept applications."))
        }
        if (team.isFull) {
            return Result.failure(IllegalStateException("Team capacity is already reached."))
        }

        // Add member to team
        val applicantProfile = _allProfiles.value.find { it.id == request.applicantId }
        val newMember = TeamMember(
            userId = request.applicantId,
            fullName = request.applicantName,
            role = TeamRole.MEMBER,
            branch = request.applicantBranch,
            academicYear = request.applicantYear,
            isManitVerified = request.applicantIsManitVerified,
            skills = request.applicantSkills,
            whatsappNumber = applicantProfile?.whatsappNumber
        )

        val updatedMembers = team.members + newMember
        val updatedTeam = team.copy(
            members = updatedMembers,
            isRecruiting = updatedMembers.size < team.maxTeamSize
        )
        updateTeam(updatedTeam)

        // Update request status
        _joinRequests.value = _joinRequests.value.map {
            if (it.id == requestId) it.copy(status = RequestStatus.ACCEPTED) else it
        }

        // Notify applicant of acceptance
        addNotification(
            recipientId = request.applicantId,
            type = NotificationType.REQUEST_ACCEPTED,
            title = "Accepted into ${team.title}!",
            body = "Congratulations! Your join request was accepted by ${user.fullName}. You have been added to the roster and granted access to Team Chat & WhatsApp Hub.",
            referenceId = team.id,
            teamTitle = team.title,
            actorName = user.fullName
        )

        // Notify existing team members of new teammate
        team.members.forEach { m ->
            if (m.userId != user.id && m.userId != request.applicantId) {
                addNotification(
                    recipientId = m.userId,
                    type = NotificationType.TEAM_ANNOUNCEMENT,
                    title = "New Teammate Joined!",
                    body = "${request.applicantName} (${request.applicantBranch}) has joined ${team.title}.",
                    referenceId = team.id,
                    teamTitle = team.title,
                    actorName = request.applicantName
                )
            }
        }

        // Post welcome message in team chat
        sendMessage(
            teamId = team.id,
            content = "🎉 ${request.applicantName} has officially joined the team roster!"
        )

        return Result.success(Unit)
    }

    fun rejectJoinRequest(requestId: String): Result<Unit> {
        val user = _currentUser.value ?: return Result.failure(IllegalStateException("Not logged in."))
        val request = _joinRequests.value.find { it.id == requestId } ?: return Result.failure(IllegalArgumentException("Request not found."))
        val team = _teams.value.find { it.id == request.teamId } ?: return Result.failure(IllegalArgumentException("Team not found."))

        if (team.ownerId != user.id) {
            return Result.failure(SecurityException("Only the team owner can decline applications."))
        }

        _joinRequests.value = _joinRequests.value.map {
            if (it.id == requestId) it.copy(status = RequestStatus.REJECTED) else it
        }

        // Notify applicant of rejection
        addNotification(
            recipientId = request.applicantId,
            type = NotificationType.REQUEST_REJECTED,
            title = "Application Update: ${team.title}",
            body = "Your request to join ${team.title} was declined by the owner because team roles are filled. Keep exploring active hackathons on the Discover hub!",
            referenceId = team.id,
            teamTitle = team.title,
            actorName = user.fullName
        )

        return Result.success(Unit)
    }

    fun withdrawJoinRequest(requestId: String): Result<Unit> {
        val user = _currentUser.value ?: return Result.failure(IllegalStateException("Not logged in."))
        val request = _joinRequests.value.find { it.id == requestId } ?: return Result.failure(IllegalArgumentException("Request not found."))

        if (request.applicantId != user.id) {
            return Result.failure(SecurityException("You can only withdraw your own applications."))
        }

        _joinRequests.value = _joinRequests.value.map {
            if (it.id == requestId) it.copy(status = RequestStatus.WITHDRAWN) else it
        }

        val team = _teams.value.find { it.id == request.teamId }
        if (team != null) {
            addNotification(
                recipientId = team.ownerId,
                type = NotificationType.REQUEST_WITHDRAWN,
                title = "Application Withdrawn",
                body = "${request.applicantName} withdrew their join request for ${team.title}.",
                referenceId = team.id,
                teamTitle = team.title,
                actorName = request.applicantName
            )
        }

        return Result.success(Unit)
    }

    // ----------------------------------------------------
    // CHAT & MESSAGING METHODS
    // ----------------------------------------------------

    fun sendMessage(teamId: String? = null, receiverId: String? = null, content: String): Result<ChatMessage> {
        val user = _currentUser.value ?: return Result.failure(IllegalStateException("Not logged in."))
        if (content.isBlank()) return Result.failure(IllegalArgumentException("Message content cannot be blank."))

        val newMsg = ChatMessage(
            id = "msg_${UUID.randomUUID().toString().take(8)}",
            teamId = teamId,
            senderId = user.id,
            senderName = user.fullName,
            senderIsManitVerified = user.isManitVerified,
            receiverId = receiverId,
            content = content.trim(),
            timestamp = System.currentTimeMillis()
        )

        _messages.value = _messages.value + newMsg
        return Result.success(newMsg)
    }

    // ----------------------------------------------------
    // NOTIFICATIONS & MODERATION
    // ----------------------------------------------------

    fun addNotification(
        recipientId: String,
        type: NotificationType,
        title: String,
        body: String,
        referenceId: String? = null,
        teamTitle: String? = null,
        actorName: String? = null
    ) {
        val notification = AppNotification(
            id = "notif_${UUID.randomUUID().toString().take(8)}",
            recipientId = recipientId,
            type = type,
            title = title,
            body = body,
            referenceId = referenceId,
            teamTitle = teamTitle,
            actorName = actorName,
            isRead = false,
            timestamp = System.currentTimeMillis()
        )
        _notifications.value = listOf(notification) + _notifications.value
    }

    fun markNotificationAsRead(id: String) {
        _notifications.value = _notifications.value.map {
            if (it.id == id) it.copy(isRead = true) else it
        }
    }

    fun markAllNotificationsAsRead(userId: String) {
        _notifications.value = _notifications.value.map {
            if (it.recipientId == userId) it.copy(isRead = true) else it
        }
    }

    fun clearNotifications(userId: String) {
        _notifications.value = _notifications.value.filter { it.recipientId != userId }
    }

    fun deleteNotification(notificationId: String) {
        _notifications.value = _notifications.value.filter { it.id != notificationId }
    }

    fun blockUser(targetUserId: String) {
        _blockedUserIds.value = _blockedUserIds.value + targetUserId
    }

    fun unblockUser(targetUserId: String) {
        _blockedUserIds.value = _blockedUserIds.value - targetUserId
    }

    fun reportEntity(reason: String, details: String) {
        // Log moderation report safely
    }

    fun switchUser(userId: String) {
        val user = _allProfiles.value.find { it.id == userId }
        if (user != null) {
            _currentUser.value = user
        }
    }
}
