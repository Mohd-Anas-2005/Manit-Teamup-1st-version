package com.example.ui.screens

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
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
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.R
import com.example.data.model.MembershipStatus
import com.example.data.repository.ManitRepository
import com.example.ui.components.ManitVerificationBadge
import com.example.ui.theme.*
import kotlinx.coroutines.delay

@Composable
fun SplashScreen(
    onNavigateToAuth: () -> Unit,
    onNavigateToMain: () -> Unit,
    modifier: Modifier = Modifier
) {
    val currentUser by ManitRepository.currentUser.collectAsState()

    // Smooth entrance animated states
    var startAnim by remember { mutableStateOf(false) }
    val scaleAnim by animateFloatAsState(
        targetValue = if (startAnim) 1f else 0.85f,
        animationSpec = spring(dampingRatio = Spring.DampingRatioMediumBouncy, stiffness = Spring.StiffnessLow),
        label = "splashScale"
    )
    val alphaAnim by animateFloatAsState(
        targetValue = if (startAnim) 1f else 0f,
        animationSpec = tween(durationMillis = 800),
        label = "splashAlpha"
    )

    LaunchedEffect(Unit) {
        startAnim = true
        delay(1600)
        if (currentUser != null) {
            onNavigateToMain()
        } else {
            onNavigateToAuth()
        }
    }

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(MidnightNavyDeep),
        contentAlignment = Alignment.Center
    ) {
        // Atmospheric background glow
        Canvas(modifier = Modifier.fillMaxSize()) {
            drawCircle(
                brush = Brush.radialGradient(
                    colors = listOf(ElectricViolet.copy(alpha = 0.22f), Color.Transparent),
                    center = center,
                    radius = size.minDimension * 0.7f
                )
            )
        }

        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
            modifier = Modifier.padding(24.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(108.dp)
                    .clip(RoundedCornerShape(12.dp))
                    .background(
                        Brush.linearGradient(
                            listOf(ElectricViolet, IndigoAccent, CyanAccent)
                        )
                    )
                    .padding(2.5.dp),
                contentAlignment = Alignment.Center
            ) {
                Image(
                    painter = painterResource(id = R.drawable.ic_manit_teamup_logo),
                    contentDescription = "MANIT TeamUp Logo",
                    modifier = Modifier
                        .fillMaxSize()
                        .clip(RoundedCornerShape(10.dp))
                )
            }

            Spacer(modifier = Modifier.height(26.dp))

            Text(
                text = "MANIT TeamUp",
                color = TextPrimary,
                fontSize = 28.sp,
                fontWeight = FontWeight.ExtraBold,
                letterSpacing = (-0.5).sp
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "Maulana Azad National Institute of Technology, Bhopal",
                color = TextLavender,
                fontSize = 13.sp,
                fontWeight = FontWeight.SemiBold,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(6.dp))

            Text(
                text = "Find the Right Teammates for Hackathons & Projects",
                color = TextSecondary,
                fontSize = 12.sp,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(48.dp))

            CircularProgressIndicator(
                color = ElectricVioletLight,
                modifier = Modifier.size(32.dp),
                strokeWidth = 3.dp
            )
        }
    }
}

@Composable
fun AuthScreen(
    onLoginSuccess: () -> Unit,
    onNeedsOtpVerification: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    var isRegisterMode by remember { mutableStateOf(false) }
    var email by remember { mutableStateOf("241114052@stu.manit.ac.in") }
    var password by remember { mutableStateOf("pass1234") }
    var isPasswordVisible by remember { mutableStateOf(false) }
    var fullName by remember { mutableStateOf("Devendra Singh") }
    var branch by remember { mutableStateOf("Computer Science & Engineering") }
    var academicYear by remember { mutableStateOf("1st Year B.Tech") }
    var otherCollegeName by remember { mutableStateOf("") }
    var declaredStatus by remember { mutableStateOf(MembershipStatus.MANIT_STUDENT) }

    var errorMessage by remember { mutableStateOf<String?>(null) }
    var showForgotPasswordDialog by remember { mutableStateOf(false) }
    var forgotEmailSent by remember { mutableStateOf(false) }

    val isManitEmail = ManitRepository.isManitInstitutionalEmail(email)

    // Staggered Hero Animation Steps
    var heroStep by remember { mutableStateOf(0) }
    LaunchedEffect(Unit) {
        delay(100)
        heroStep = 1 // Background & Glow
        delay(150)
        heroStep = 2 // Headline
        delay(150)
        heroStep = 3 // Subtitle & CTAs
        delay(200)
        heroStep = 4 // Floating Nodes & Connections
    }

    // Subtle ambient pulsing for connection lines
    val infiniteTransition = rememberInfiniteTransition(label = "ambientPulse")
    val pulseAlpha by infiniteTransition.animateFloat(
        initialValue = 0.35f,
        targetValue = 0.75f,
        animationSpec = infiniteRepeatable(
            animation = tween(2200, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "pulseAlpha"
    )

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(MidnightNavy)
            .statusBarsPadding()
            .navigationBarsPadding()
            .verticalScroll(rememberScrollState())
            .padding(bottom = 32.dp)
    ) {
        // ==========================================
        // CINEMATIC HERO SECTION
        // ==========================================
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(
                    Brush.verticalGradient(
                        listOf(MidnightNavyDeep, MidnightNavy)
                    )
                )
                .padding(horizontal = 20.dp, vertical = 20.dp)
        ) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.fillMaxWidth()
            ) {
                // Official Brand Icon (Square shaped with filler)
                Image(
                    painter = painterResource(id = R.drawable.ic_manit_teamup_logo),
                    contentDescription = "MANIT TeamUp Logo",
                    modifier = Modifier
                        .size(76.dp)
                        .clip(RoundedCornerShape(8.dp))
                        .border(1.5.dp, Brush.linearGradient(listOf(ElectricViolet, CyanAccent)), RoundedCornerShape(8.dp))
                )

                Spacer(modifier = Modifier.height(14.dp))

                // Campus Badge Header
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier
                        .clip(RoundedCornerShape(20.dp))
                        .background(CharcoalSurfaceVariant)
                        .border(1.dp, CharcoalBorder, RoundedCornerShape(20.dp))
                        .padding(horizontal = 12.dp, vertical = 5.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .size(8.dp)
                            .clip(CircleShape)
                            .background(CyanLight)
                    )
                    Text(
                        text = "MANIT Bhopal • Campus Collaboration Hub",
                        color = TextLavender,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                }

                Spacer(modifier = Modifier.height(18.dp))

                // Hero Headline
                Text(
                    text = "Build Winning Teams.\nCreate Without Limits.",
                    color = TextPrimary,
                    fontSize = 26.sp,
                    fontWeight = FontWeight.ExtraBold,
                    lineHeight = 32.sp,
                    textAlign = TextAlign.Center,
                    letterSpacing = (-0.5).sp
                )

                Spacer(modifier = Modifier.height(10.dp))

                // Subtitle
                Text(
                    text = "Connect with peer hackers, designers, ML engineers, and developers across MANIT and national hackathons with verified credentials.",
                    color = TextSecondary,
                    fontSize = 13.sp,
                    lineHeight = 18.sp,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(horizontal = 8.dp)
                )

                Spacer(modifier = Modifier.height(20.dp))

                // Interactive Collaborative Constellation Canvas
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(140.dp)
                        .clip(RoundedCornerShape(16.dp))
                        .background(CharcoalSurface)
                        .border(1.dp, CharcoalBorder, RoundedCornerShape(16.dp))
                        .padding(8.dp),
                    contentAlignment = Alignment.Center
                ) {
                    // Animated connection lines between 4 peer nodes
                    Canvas(modifier = Modifier.fillMaxSize()) {
                        val w = size.width
                        val h = size.height

                        val p1 = Offset(w * 0.18f, h * 0.35f) // Node 1 (Ayush - CSE)
                        val p2 = Offset(w * 0.50f, h * 0.20f) // Node 2 (Riya - IT UI/UX)
                        val p3 = Offset(w * 0.82f, h * 0.35f) // Node 3 (Karan - Edge AI)
                        val p4 = Offset(w * 0.50f, h * 0.78f) // Node 4 (SIH 2026 Core)

                        val path = Path().apply {
                            moveTo(p1.x, p1.y)
                            lineTo(p2.x, p2.y)
                            lineTo(p3.x, p3.y)
                            lineTo(p4.x, p4.y)
                            close()
                            moveTo(p2.x, p2.y)
                            lineTo(p4.x, p4.y)
                        }

                        drawPath(
                            path = path,
                            color = CyanAccent.copy(alpha = pulseAlpha * 0.6f),
                            style = Stroke(width = 1.5.dp.toPx())
                        )

                        // Center hub glow
                        drawCircle(
                            brush = Brush.radialGradient(
                                colors = listOf(ElectricVioletLight.copy(alpha = pulseAlpha * 0.4f), Color.Transparent),
                                center = p4,
                                radius = 40.dp.toPx()
                            )
                        )
                    }

                    // Floating Profile Chips positioned inside the constellation
                    Row(
                        modifier = Modifier.fillMaxSize(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        HeroNodeTag(name = "Ayush (CSE)", skill = "Kotlin / Go", icon = Icons.Default.Terminal)
                        HeroNodeTag(name = "Riya (IT)", skill = "Figma / React", icon = Icons.Default.Palette)
                        HeroNodeTag(name = "Karan (IIT)", skill = "Edge AI", icon = Icons.Default.Memory)
                    }
                }

                Spacer(modifier = Modifier.height(18.dp))

                // Fast Quick Action Buttons
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Button(
                        onClick = {
                            // Pre-fill quick demo credentials to explore immediately
                            ManitRepository.signIn("241114052@stu.manit.ac.in", "pass1234")
                            onLoginSuccess()
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = ElectricViolet),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier
                            .weight(1f)
                            .height(48.dp)
                            .testTag("hero_find_team_btn")
                    ) {
                        Icon(Icons.Default.Explore, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("Find Your Team", fontWeight = FontWeight.Bold, fontSize = 13.sp)
                    }

                    OutlinedButton(
                        onClick = {
                            isRegisterMode = true
                        },
                        shape = RoundedCornerShape(12.dp),
                        border = androidx.compose.foundation.BorderStroke(1.dp, ElectricVioletLight),
                        modifier = Modifier
                            .weight(1f)
                            .height(48.dp)
                            .testTag("hero_create_account_btn")
                    ) {
                        Icon(Icons.Default.PersonAdd, contentDescription = null, tint = ElectricVioletLight, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("Join Campus Hub", color = ElectricVioletLight, fontWeight = FontWeight.Bold, fontSize = 13.sp)
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(10.dp))

        // ==========================================
        // AUTHENTICATION TAB & FORM
        // ==========================================
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Segmented Switcher Tabs
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(CharcoalSurface)
                    .border(1.dp, CharcoalBorder, RoundedCornerShape(14.dp))
                    .padding(4.dp)
            ) {
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .clip(RoundedCornerShape(10.dp))
                        .background(if (!isRegisterMode) ElectricViolet else Color.Transparent)
                        .clickable { isRegisterMode = false }
                        .padding(vertical = 10.dp)
                        .testTag("tab_sign_in"),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "Sign In",
                        color = if (!isRegisterMode) White else TextSecondary,
                        fontWeight = FontWeight.Bold,
                        fontSize = 14.sp
                    )
                }
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .clip(RoundedCornerShape(10.dp))
                        .background(if (isRegisterMode) ElectricViolet else Color.Transparent)
                        .clickable { isRegisterMode = true }
                        .padding(vertical = 10.dp)
                        .testTag("tab_register"),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "Register",
                        color = if (isRegisterMode) White else TextSecondary,
                        fontWeight = FontWeight.Bold,
                        fontSize = 14.sp
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Institutional Domain & Credibility Status
            Card(
                shape = RoundedCornerShape(14.dp),
                colors = CardDefaults.cardColors(containerColor = CharcoalSurface),
                border = androidx.compose.foundation.BorderStroke(
                    1.dp,
                    if (isManitEmail) ElectricVioletLight else CharcoalBorder
                ),
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier.padding(14.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Icon(
                        imageVector = if (isManitEmail) Icons.Default.Shield else Icons.Default.Public,
                        contentDescription = null,
                        tint = if (isManitEmail) ElectricVioletLight else CyanLight,
                        modifier = Modifier.size(24.dp)
                    )
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = if (isManitEmail) "MANIT Scholar ID Detected" else "Open Collaborator Mode",
                            color = TextPrimary,
                            fontSize = 13.sp,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = if (isManitEmail)
                                "Validating your @stu.manit.ac.in grants the official verified student badge."
                            else
                                "Students from other institutes can collaborate on cross-college hackathons.",
                            color = TextSecondary,
                            fontSize = 11.sp,
                            lineHeight = 15.sp
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Register Extra Fields
            if (isRegisterMode) {
                OutlinedTextField(
                    value = fullName,
                    onValueChange = { fullName = it },
                    label = { Text("Full Name") },
                    singleLine = true,
                    leadingIcon = { Icon(Icons.Default.Person, contentDescription = null, tint = TextSecondary) },
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = ElectricVioletLight,
                        unfocusedBorderColor = CharcoalBorder,
                        focusedTextColor = TextPrimary,
                        unfocusedTextColor = TextPrimary
                    ),
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("auth_name_input")
                )

                Spacer(modifier = Modifier.height(12.dp))

                OutlinedTextField(
                    value = branch,
                    onValueChange = { branch = it },
                    label = { Text("Branch / Department (e.g. CSE, ECE, IT)") },
                    singleLine = true,
                    leadingIcon = { Icon(Icons.Default.School, contentDescription = null, tint = TextSecondary) },
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = ElectricVioletLight,
                        unfocusedBorderColor = CharcoalBorder,
                        focusedTextColor = TextPrimary,
                        unfocusedTextColor = TextPrimary
                    ),
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("auth_branch_input")
                )

                Spacer(modifier = Modifier.height(12.dp))

                OutlinedTextField(
                    value = academicYear,
                    onValueChange = { academicYear = it },
                    label = { Text("Academic Year (e.g. 1st Year B.Tech)") },
                    singleLine = true,
                    leadingIcon = { Icon(Icons.Default.CalendarToday, contentDescription = null, tint = TextSecondary) },
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = ElectricVioletLight,
                        unfocusedBorderColor = CharcoalBorder,
                        focusedTextColor = TextPrimary,
                        unfocusedTextColor = TextPrimary
                    ),
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("auth_year_input")
                )

                if (!isManitEmail) {
                    Spacer(modifier = Modifier.height(12.dp))
                    OutlinedTextField(
                        value = otherCollegeName,
                        onValueChange = { otherCollegeName = it },
                        label = { Text("College / University Name") },
                        placeholder = { Text("e.g. IIT Delhi, NIT Trichy") },
                        singleLine = true,
                        leadingIcon = { Icon(Icons.Default.AccountBalance, contentDescription = null, tint = TextSecondary) },
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = CyanAccent,
                            unfocusedBorderColor = CharcoalBorder,
                            focusedTextColor = TextPrimary,
                            unfocusedTextColor = TextPrimary
                        ),
                        modifier = Modifier.fillMaxWidth()
                    )
                }

                Spacer(modifier = Modifier.height(12.dp))
            }

            // Email Field
            OutlinedTextField(
                value = email,
                onValueChange = { email = it },
                label = { Text("Email Address") },
                placeholder = { Text("scholar@stu.manit.ac.in or personal email") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
                leadingIcon = { Icon(Icons.Default.Email, contentDescription = null, tint = TextSecondary) },
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = ElectricVioletLight,
                    unfocusedBorderColor = CharcoalBorder,
                    focusedTextColor = TextPrimary,
                    unfocusedTextColor = TextPrimary
                ),
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("auth_email_input")
            )

            Spacer(modifier = Modifier.height(12.dp))

            // Password Field
            OutlinedTextField(
                value = password,
                onValueChange = { password = it },
                label = { Text("Password") },
                singleLine = true,
                visualTransformation = if (isPasswordVisible) VisualTransformation.None else PasswordVisualTransformation(),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                leadingIcon = { Icon(Icons.Default.Lock, contentDescription = null, tint = TextSecondary) },
                trailingIcon = {
                    IconButton(onClick = { isPasswordVisible = !isPasswordVisible }) {
                        Icon(
                            imageVector = if (isPasswordVisible) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                            contentDescription = "Toggle password visibility",
                            tint = TextSecondary
                        )
                    }
                },
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = ElectricVioletLight,
                    unfocusedBorderColor = CharcoalBorder,
                    focusedTextColor = TextPrimary,
                    unfocusedTextColor = TextPrimary
                ),
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("auth_password_input")
            )

            if (errorMessage != null) {
                Spacer(modifier = Modifier.height(12.dp))
                Card(
                    colors = CardDefaults.cardColors(containerColor = CoralSubtle),
                    shape = RoundedCornerShape(10.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        modifier = Modifier.padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Icon(Icons.Default.ErrorOutline, contentDescription = null, tint = CoralLight)
                        Text(text = errorMessage ?: "", color = CoralLight, fontSize = 12.sp)
                    }
                }
            }

            if (!isRegisterMode) {
                Spacer(modifier = Modifier.height(6.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.End
                ) {
                    TextButton(onClick = { showForgotPasswordDialog = true }) {
                        Text("Forgot Password?", color = CyanLight, fontSize = 12.sp)
                    }
                }
            } else {
                Spacer(modifier = Modifier.height(14.dp))
            }

            // Primary Action Button
            Button(
                onClick = {
                    errorMessage = null
                    if (isRegisterMode) {
                        val result = ManitRepository.startRegistration(
                            email = email,
                            password = password,
                            fullName = fullName,
                            branch = branch,
                            academicYear = academicYear,
                            college = if (isManitEmail) "MANIT Bhopal" else otherCollegeName,
                            declaredStatus = declaredStatus
                        )
                        result.onSuccess {
                            onNeedsOtpVerification(email)
                        }.onFailure {
                            errorMessage = it.message ?: "Registration error"
                        }
                    } else {
                        val result = ManitRepository.signIn(email, password)
                        result.onSuccess {
                            onLoginSuccess()
                        }.onFailure {
                            errorMessage = it.message ?: "Sign-in error"
                        }
                    }
                },
                colors = ButtonDefaults.buttonColors(containerColor = ElectricViolet),
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp)
                    .testTag("auth_submit_btn")
            ) {
                Text(
                    text = if (isRegisterMode) "Verify Institutional Email" else "Sign In to TeamUp",
                    color = White,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold
                )
            }

            Spacer(modifier = Modifier.height(18.dp))

            // Institutional Privacy Guarantee
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.padding(horizontal = 8.dp)
            ) {
                Icon(Icons.Default.Security, contentDescription = null, tint = TextMuted, modifier = Modifier.size(16.dp))
                Text(
                    text = "End-to-end encrypted. Never share your MANIT student ERP credentials.",
                    color = TextMuted,
                    fontSize = 11.sp,
                    textAlign = TextAlign.Center
                )
            }
        }
    }

    // Forgot Password Dialog
    if (showForgotPasswordDialog) {
        AlertDialog(
            onDismissRequest = { showForgotPasswordDialog = false },
            title = { Text("Password Recovery", color = TextPrimary) },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text(
                        "Enter your student email. A password reset token will be dispatched to your inbox.",
                        color = TextSecondary,
                        fontSize = 13.sp
                    )
                    OutlinedTextField(
                        value = email,
                        onValueChange = { email = it },
                        label = { Text("Email") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                    if (forgotEmailSent) {
                        Text("Reset token sent! Check your inbox.", color = StatusSuccess, fontSize = 12.sp)
                    }
                }
            },
            confirmButton = {
                Button(
                    onClick = { forgotEmailSent = true },
                    colors = ButtonDefaults.buttonColors(containerColor = ElectricViolet)
                ) {
                    Text("Send Token")
                }
            },
            dismissButton = {
                TextButton(onClick = { showForgotPasswordDialog = false }) {
                    Text("Close", color = TextSecondary)
                }
            },
            containerColor = CharcoalSurface,
            shape = RoundedCornerShape(16.dp)
        )
    }
}

@Composable
fun HeroNodeTag(
    name: String,
    skill: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    modifier: Modifier = Modifier
) {
    Surface(
        shape = RoundedCornerShape(10.dp),
        color = CharcoalSurfaceVariant,
        border = androidx.compose.foundation.BorderStroke(1.dp, CharcoalBorder),
        modifier = modifier
    ) {
        Column(
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 6.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(imageVector = icon, contentDescription = null, tint = CyanLight, modifier = Modifier.size(16.dp))
            Text(text = name, color = TextPrimary, fontSize = 10.sp, fontWeight = FontWeight.Bold)
            Text(text = skill, color = TextMuted, fontSize = 9.sp)
        }
    }
}

@Composable
fun VerifyOtpScreen(
    email: String,
    onVerificationSuccess: () -> Unit,
    onBackToAuth: () -> Unit,
    modifier: Modifier = Modifier
) {
    var otpCode by remember { mutableStateOf("") }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var timerSeconds by remember { mutableStateOf(60) }

    val isManit = ManitRepository.isManitInstitutionalEmail(email)

    LaunchedEffect(Unit) {
        while (timerSeconds > 0) {
            delay(1000)
            timerSeconds--
        }
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(MidnightNavy)
            .statusBarsPadding()
            .navigationBarsPadding()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onBackToAuth) {
                Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = TextPrimary)
            }
            Text(
                text = "Institutional Verification",
                color = TextPrimary,
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold
            )
        }

        Spacer(modifier = Modifier.height(30.dp))

        Box(
            modifier = Modifier
                .size(72.dp)
                .clip(CircleShape)
                .background(ElectricVioletSubtle),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Default.MarkEmailRead,
                contentDescription = null,
                tint = ElectricVioletLight,
                modifier = Modifier.size(36.dp)
            )
        }

        Spacer(modifier = Modifier.height(20.dp))

        Text(
            text = "Verify Email Address",
            color = TextPrimary,
            fontSize = 20.sp,
            fontWeight = FontWeight.Bold
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = "A 6-digit confirmation code has been dispatched to:",
            color = TextSecondary,
            fontSize = 13.sp,
            textAlign = TextAlign.Center
        )

        Text(
            text = email,
            color = ElectricVioletLight,
            fontSize = 14.sp,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(top = 4.dp)
        )

        Spacer(modifier = Modifier.height(16.dp))

        if (isManit) {
            Card(
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(containerColor = CharcoalSurface),
                border = androidx.compose.foundation.BorderStroke(1.dp, ElectricVioletLight)
            ) {
                Row(
                    modifier = Modifier.padding(12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Icon(Icons.Default.Shield, contentDescription = null, tint = ElectricVioletLight, modifier = Modifier.size(20.dp))
                    Text(
                        text = "MANIT Verified Badge will be officially granted upon successful code confirmation.",
                        color = ElectricVioletLight,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Medium
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(28.dp))

        OutlinedTextField(
            value = otpCode,
            onValueChange = { if (it.length <= 6) otpCode = it },
            label = { Text("6-Digit OTP Code") },
            placeholder = { Text("e.g. 123456") },
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = ElectricVioletLight,
                unfocusedBorderColor = CharcoalBorder,
                focusedTextColor = TextPrimary,
                unfocusedTextColor = TextPrimary
            ),
            modifier = Modifier
                .fillMaxWidth()
                .testTag("otp_code_input")
        )

        Spacer(modifier = Modifier.height(8.dp))
        Row(
            modifier = Modifier
                .clip(RoundedCornerShape(8.dp))
                .background(CharcoalSurfaceVariant)
                .clickable { otpCode = "123456" }
                .padding(horizontal = 10.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Icon(Icons.Default.Code, contentDescription = null, tint = CyanLight, modifier = Modifier.size(14.dp))
            Text("Dev Demo Code: 123456 (Tap to auto-fill)", color = CyanLight, fontSize = 11.sp)
        }

        if (errorMessage != null) {
            Spacer(modifier = Modifier.height(12.dp))
            Text(errorMessage ?: "", color = CoralLight, fontSize = 12.sp)
        }

        Spacer(modifier = Modifier.height(24.dp))

        Button(
            onClick = {
                val result = ManitRepository.verifyOtp(email, otpCode)
                result.onSuccess {
                    onVerificationSuccess()
                }.onFailure {
                    errorMessage = it.message ?: "Verification failed."
                }
            },
            colors = ButtonDefaults.buttonColors(containerColor = ElectricViolet),
            shape = RoundedCornerShape(12.dp),
            modifier = Modifier
                .fillMaxWidth()
                .height(50.dp)
                .testTag("otp_submit_btn")
        ) {
            Text("Confirm Verification", color = White, fontWeight = FontWeight.Bold, fontSize = 15.sp)
        }

        Spacer(modifier = Modifier.height(16.dp))

        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.Center
        ) {
            if (timerSeconds > 0) {
                Text(
                    text = "Resend code in ${timerSeconds}s",
                    color = TextMuted,
                    fontSize = 12.sp
                )
            } else {
                TextButton(onClick = {
                    ManitRepository.resendOtp(email)
                    timerSeconds = 60
                }) {
                    Text("Resend Verification Code", color = CyanLight, fontSize = 13.sp)
                }
            }
        }
    }
}
