# Kinu Development Roadmap

**Project Status:** Phase 4 Complete, Ready for Testing

---

## ✅ COMPLETED PHASES

### Phase 0: Foundation
- [x] Flutter monorepo with Melos
- [x] Clean architecture layers
- [x] Core dependencies
- [x] Build system configured

### Phase 1: Cloud Messaging
- [x] Matrix SDK integration
- [x] Identity service (Ed25519/X25519)
- [x] Secure storage (flutter_secure_storage)
- [x] Database schema (Drift + SQLCipher)
- [x] Chat UI (conversations, messages)
- [x] Message encryption (Matrix E2EE)

### Phase 2: Mesh Networking (BLE)
- [x] BLE service (flutter_blue_plus)
- [x] Noise XX handshake protocol
- [x] Store-and-forward message queue
- [x] Routing engine
- [x] Message deduplication
- [x] Mesh status banner UI
- [x] Auto-start on app launch
- [x] Background service hooks

### Phase 3: Rally Mode
- [x] Location services (geolocator)
- [x] Geohash utility (precision 6)
- [x] Rally database tables (channels, members, reports)
- [x] Rally repository (CRUD operations)
- [x] Channel discovery UI
- [x] Rally channel screen
- [x] Map view (OpenStreetMap + markers)
- [x] Anonymous identity generator
- [x] Reputation system
- [x] Reverse geocoding
- [x] Message expiration (4-hour TTL)
- [x] Background cleanup task

### Phase 4: Account Management & Security
- [x] **Auth Server** (Rust/Axum)
  - [x] JWT-based authentication
  - [x] Passkey/WebAuthn support
  - [x] Password authentication with Argon2id
  - [x] Matrix account auto-creation
- [x] **Two-Factor Authentication**
  - [x] TOTP setup with QR code
  - [x] Backup codes generation
  - [x] 2FA verification on login
- [x] **Device Management**
  - [x] Device tracking on login/register
  - [x] List devices API
  - [x] Revoke individual devices
  - [x] Revoke all other devices
  - [x] X-Device-ID header support
- [x] **Email Verification**
  - [x] SMTP integration (lettre)
  - [x] Verification email templates
  - [x] Recovery email templates
  - [x] Token-based verification
- [x] **Data Export** (GDPR)
  - [x] Export API endpoint
  - [x] Mobile app integration
  - [x] Share via system share sheet
- [x] **Quiet Hours**
  - [x] Time range configuration
  - [x] Overnight span support
  - [x] Settings UI

**Deployment:**
- [x] Auth server deployed to Fly.io
- [x] Matrix server deployed to Fly.io
- [x] Landing page deployed

---

## 🔄 CURRENT PRIORITY

### Device Testing & Validation

**Next Steps:**
1. Test on physical iOS/Android devices
2. Validate BLE mesh networking
3. Test email verification flow
4. Test device management flow
5. Document issues found
6. Fix critical bugs

---

## 📋 NEXT PHASES

### Phase 5: Bridge Relay
**Goal:** Users with internet relay messages for offline users

**Technical Requirements:**
- Rust relay server
- Redis message queue
- WebSocket connections
- Recipient polling system
- Bridge peer discovery
- Message forwarding logic
- Relay node reputation

**Estimated:** 3-4 weeks

### Phase 6: Group Chats
**Goal:** Multi-party encrypted conversations

**Technical Requirements:**
- Matrix rooms integration
- Multi-recipient encryption
- Group member management
- Admin controls
- Group invitations
- Leave/kick functionality
- Group settings UI

**Estimated:** 2-3 weeks

### Phase 7: Media Messages
**Goal:** Send images, voice notes, files

**Technical Requirements:**
- Image picker/camera
- Voice recording
- File compression
- Thumbnail generation
- Media storage
- Download manager
- Media viewer UI

**Estimated:** 2-3 weeks

### Phase 8: Production Hardening
**Goal:** App Store ready

**Technical Requirements:**
- Push notifications (APNs/FCM)
- Background fetch
- App Store assets
- Privacy policy
- Terms of service
- App Store submission
- Beta testing (TestFlight)
- Crash reporting
- Performance monitoring

**Estimated:** 2-3 weeks

---

## 🎯 CRITICAL PATH

### Now → Week 1: Device Testing
1. Deploy to physical devices
2. Test all auth flows (register, login, 2FA, recovery)
3. Test device management
4. Test email verification
5. Test BLE mesh networking
6. Document findings

### Week 2-3: Polish & Bug Fixes
- Fix issues found in testing
- Improve error handling
- Optimize performance
- Add missing edge cases

### Week 4-7: Phase 5 (Bridge Relay)
- Build Rust relay server
- Implement bridge protocol
- Test with 3+ devices
- Deploy relay server

### Week 8-10: Phase 6 (Groups)
- Matrix rooms integration
- Group management UI
- Multi-party encryption

### Week 11-13: Phase 7 (Media)
- Image/voice support
- Media storage
- Viewer UI

### Week 14-16: Phase 8 (Production)
- App Store preparation
- TestFlight beta
- Launch

---

## ⚠️ KNOWN ISSUES

### To Test
- [ ] Email verification on production
- [ ] Device revocation flow
- [ ] 2FA backup codes recovery
- [ ] Data export on mobile

### To Fix
- [ ] Error handling consistency
- [ ] Loading states in UI
- [ ] Network timeout handling

---

## 📊 SUCCESS METRICS

### Technical Metrics
- BLE connection success rate >80%
- Message delivery time <10 seconds (mesh)
- Message delivery time <2 seconds (cloud)
- Battery drain <5% per hour (active use)
- App crash rate <1%

### Product Metrics
- User retention (Day 1, Day 7, Day 30)
- Messages sent per user per day
- 2FA adoption rate
- Device management usage

---

## 🔧 TECHNICAL DEBT

### High Priority
- [ ] Rate limiting on auth endpoints
- [ ] Request validation improvements
- [ ] Error message consistency

### Medium Priority
- [ ] Database query optimization
- [ ] UI polish (animations, loading states)
- [ ] Accessibility (VoiceOver, Dynamic Type)

### Low Priority
- [ ] Code comments
- [ ] Integration tests
- [ ] Documentation updates
- [ ] Verify all GitHub links point to https://github.com/kinuchat/kinuchat (repo) not just /kinuchat/ (org)

---

## 💡 FUTURE IDEAS

### User Requests (Anticipated)
- [ ] Message search
- [ ] Message reactions
- [ ] Voice/video calls
- [ ] Disappearing messages
- [ ] PIN lock
- [ ] Message backups
- [ ] Desktop app
- [ ] Web app

### Security Enhancements
- [ ] E2EE key verification UI
- [ ] Multi-device sync
- [ ] Security audit
- [ ] Bug bounty program

---

## 📝 DOCUMENTATION STATUS

### ✅ Complete
- [x] Main README.md
- [x] Auth Server API (server/auth/README.md)
- [x] Deployment Guide
- [x] Testing Guide

### 🔄 Needs Update
- [ ] Mobile App README
- [ ] SPEC.md (add Phase 4 details)
- [ ] Architecture diagrams

### ❌ Missing
- [ ] User documentation
- [ ] FAQ
- [ ] Privacy policy (legal review)
- [ ] Terms of service (legal review)
