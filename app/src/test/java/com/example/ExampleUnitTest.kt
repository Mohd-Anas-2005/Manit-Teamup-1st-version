package com.example

import com.example.data.model.MembershipStatus
import com.example.data.model.ProjectCategory
import com.example.data.model.RequestStatus
import com.example.data.repository.ManitRepository
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

class ManitTeamUpUnitTest {

    @Before
    fun setup() {
        ManitRepository.signOut()
    }

    @Test
    fun testManitInstitutionalEmailValidation() {
        // Scholar emails ending in @stu.manit.ac.in
        assertTrue(ManitRepository.isManitInstitutionalEmail("241114052@stu.manit.ac.in"))
        assertTrue(ManitRepository.isManitInstitutionalEmail("scholar123@manit.ac.in"))

        // External emails
        assertFalse(ManitRepository.isManitInstitutionalEmail("student@gmail.com"))
        assertFalse(ManitRepository.isManitInstitutionalEmail("ayush@iitb.ac.in"))
        assertFalse(ManitRepository.isManitInstitutionalEmail("fake@notmanit.com"))
    }

    @Test
    fun testScholarNumberExtraction() {
        assertEquals("241114052", ManitRepository.extractScholarNumber("241114052@stu.manit.ac.in"))
        assertNull(ManitRepository.extractScholarNumber("ayush.dev@stu.manit.ac.in"))
        assertNull(ManitRepository.extractScholarNumber("241114052@gmail.com"))
    }

    @Test
    fun testRegistrationAndOtpVerificationSafety() {
        val email = "241119999@stu.manit.ac.in"
        val regResult = ManitRepository.startRegistration(
            email = email,
            password = "securePassword123",
            fullName = "Rohit Kumar",
            branch = "CSE",
            academicYear = "1st Year B.Tech"
        )

        assertTrue(regResult.isSuccess)
        val otp = regResult.getOrNull()
        assertNotNull(otp)

        // Ensure user is NOT marked verified before OTP confirmation
        assertNull(ManitRepository.currentUser.value)

        // Confirm OTP
        val verifyResult = ManitRepository.verifyOtp(email, otp!!)
        assertTrue(verifyResult.isSuccess)

        val profile = verifyResult.getOrNull()
        assertNotNull(profile)
        assertEquals("Rohit Kumar", profile?.fullName)
        assertTrue("MANIT student must be verified after OTP", profile?.isManitVerified == true)
        assertEquals(MembershipStatus.MANIT_STUDENT, profile?.membershipStatus)
    }

    @Test
    fun testExternalStudentRegistrationDoesNotFalselyClaimVerification() {
        val email = "external.dev@iitd.ac.in"
        val regResult = ManitRepository.startRegistration(
            email = email,
            password = "password123",
            fullName = "Neha Sharma",
            branch = "ECE",
            academicYear = "2nd Year B.Tech",
            college = "IIT Delhi",
            declaredStatus = MembershipStatus.OTHER_COLLEGE
        )

        assertTrue(regResult.isSuccess)
        val otp = regResult.getOrNull()
        assertNotNull(otp)

        val verifyResult = ManitRepository.verifyOtp(email, otp!!)
        assertTrue(verifyResult.isSuccess)

        val profile = verifyResult.getOrNull()
        assertNotNull(profile)
        assertFalse("External college student must not have false MANIT verification", profile?.isManitVerified == true)
        assertEquals(MembershipStatus.OTHER_COLLEGE, profile?.membershipStatus)
        assertEquals("IIT Delhi", profile?.collegeName)
    }

    @Test
    fun testTeamCreationAndJoinWorkflow() {
        // Sign in test leader
        ManitRepository.signIn("leader@stu.manit.ac.in", "pass123")

        val teamResult = ManitRepository.createTeam(
            title = "Test AI Squad",
            description = "Developing edge computer vision for robotics",
            category = ProjectCategory.HACKATHON,
            eventName = "SIH 2026",
            skills = listOf("Python", "PyTorch"),
            maxSize = 3,
            whatsappLink = "https://chat.whatsapp.com/test"
        )

        assertTrue(teamResult.isSuccess)
        val team = teamResult.getOrNull()!!
        assertEquals(2, team.vacanciesLeft) // 1 leader already in team

        // Switch user to applicant
        ManitRepository.signIn("applicant@stu.manit.ac.in", "pass123")
        val reqResult = ManitRepository.sendJoinRequest(team.id, "I love PyTorch!")
        assertTrue(reqResult.isSuccess)
        val request = reqResult.getOrNull()!!
        assertEquals(RequestStatus.PENDING, request.status)

        // Switch back to leader and accept applicant
        ManitRepository.signIn("leader@stu.manit.ac.in", "pass123")
        val acceptResult = ManitRepository.acceptJoinRequest(request.id)
        assertTrue(acceptResult.isSuccess)

        val updatedTeam = ManitRepository.teams.value.find { it.id == team.id }!!
        assertEquals(2, updatedTeam.members.size)
        assertEquals(1, updatedTeam.vacanciesLeft)
    }
}
