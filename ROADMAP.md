# MeshLink Development Roadmap

**Project Status:** Phase 3 Complete, Ready for Device Testing

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

**Gaps (non-blocking):**
- [ ] Onboarding wizard for Matrix registration
- [ ] Contact discovery/search UI
- [ ] Matrix auto-registration

### Phase 2: Mesh Networking (BLE)
- [x] BLE service (flutter_blue_plus)
- [x] Noise XX handshake protocol
- [x] Store-and-forward message queue
- [x] Routing engine
- [x] Message deduplication
- [x] Mesh status banner UI
- [x] Auto-start on app launch
- [x] Background service hooks

**Needs Validation:**
- [ ] BLE mesh works on real devices (simulator can't test)
- [ ] Connection reliability within 30 feet
- [ ] Store-and-forward actually delivers
- [ ] Battery impact acceptable

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
- [x] 58 unit tests (geohash + anonymous identity)

**Needs Validation:**
- [ ] Location-based discovery works
- [ ] Map view performs well
- [ ] Geohash precision appropriate
- [ ] Reputation filtering effective

---

## 🔄 CURRENT PRIORITY

### Device Testing & Validation
**Blocker:** Xcode compatibility (being resolved via macOS update)

**Once unblocked:**
1. Deploy to iPhone 17 Pro + iPad
2. Test BLE mesh networking (THE critical test)
3. Validate Rally Mode on real GPS
4. Document issues found
5. Fix critical bugs
6. Iterate

**Timeline:** 1-2 days after macOS/Xcode update

---

## 📋 NEXT PHASES (Not Started)

### Phase 4: Bridge Relay
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

**Dependencies:** Phase 2 BLE must work reliably

### Phase 5: Group Chats
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

**Dependencies:** Phase 1 cloud messaging stable

### Phase 6: Media Messages
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

**Dependencies:** Phase 1 & 2 stable

### Phase 7: Advanced Mesh Features
**Goal:** Multi-hop routing, better reliability

**Technical Requirements:**
- Multi-hop message routing
- Path optimization
- Network topology mapping
- Route discovery protocol
- Load balancing
- Congestion control

**Estimated:** 3-4 weeks

**Dependencies:** Phase 2 working, Phase 4 complete

### Phase 8: Production Hardening
**Goal:** App Store ready

**Technical Requirements:**
- Push notifications (APNs)
- Background fetch
- App Store assets
- Privacy policy
- Terms of service
- App Store submission
- Beta testing (TestFlight)
- Analytics (privacy-preserving)
- Crash reporting
- Performance monitoring

**Estimated:** 2-3 weeks

**Dependencies:** Core features stable

---

## 🎯 CRITICAL PATH

### Now → Week 1: Device Validation
1. Update macOS/Xcode
2. Deploy to physical devices
3. **TEST BLE MESH** (make or break)
4. Fix critical bugs found
5. Document baseline performance

### Week 2-3: Polish Phase 1-3
Based on device testing findings:
- Fix BLE reliability issues
- Improve Rally UX
- Add missing onboarding flows
- Optimize battery usage
- Add contact management UI

### Week 4-7: Phase 4 (Bridge Relay)
- Build Rust relay server
- Implement bridge protocol
- Test with 3+ devices
- Deploy relay server to cloud

### Week 8-10: Phase 5 (Group Chats)
- Matrix rooms integration
- Group management UI
- Multi-party encryption

### Week 11-13: Phase 6 (Media)
- Image/voice support
- Media storage
- Viewer UI

### Week 14-17: Phase 7 (Advanced Mesh)
- Multi-hop routing
- Network optimization
- Reliability improvements

### Week 18-20: Phase 8 (Production)
- App Store preparation
- TestFlight beta
- Launch

**Total Estimated Timeline:** ~5 months from now to App Store

---

## ⚠️ KNOWN RISKS

### Technical Risks
1. **BLE reliability on iOS** - iOS backgrounds BLE after 10 seconds
   - Mitigation: Background service, keep-alive strategies
2. **Battery drain from BLE scanning** - Continuous scanning drains battery
   - Mitigation: Adaptive scan intervals, user controls
3. **Matrix server dependency** - Self-hosted or public server?
   - Mitigation: Document server setup, provide defaults
4. **iOS App Store approval** - BLE + encryption might raise flags
   - Mitigation: Clear privacy policy, explain use case

### Product Risks
1. **User adoption** - Network effects matter for mesh
   - Mitigation: Rally Mode works with 1 device, grow organically
2. **Competition** - Briar, Bridgefy exist
   - Mitigation: Better UX, hybrid cloud/mesh approach
3. **Regulatory** - Some countries ban encrypted apps
   - Mitigation: Clear documentation, comply with laws

### Timeline Risks
1. **BLE doesn't work** - If mesh is unreliable, pivot to cloud-only?
   - Mitigation: Test early (now), validate before continuing
2. **Scope creep** - Adding features delays launch
   - Mitigation: Stick to roadmap, defer non-critical features
3. **One developer** - No redundancy if you're blocked
   - Mitigation: Clear documentation (like this!), modular design

---

## 🎬 DECISION POINTS

### After Device Testing (Next Week)
**Decision:** Continue with roadmap OR pivot based on BLE results?

**If BLE works well:**
→ Continue with Phase 4 (Bridge Relay)

**If BLE is unreliable:**
→ Option A: Focus on cloud-only (Phase 5: Groups, Phase 6: Media)
→ Option B: Investigate alternative mesh (WiFi Direct, etc.)
→ Option C: Rally Mode as primary feature, mesh as experimental

### After Phase 4 (Month 2)
**Decision:** Add features OR launch beta?

**If relay server works:**
→ Continue to Phase 5-6 (more features)

**If enough stability:**
→ Skip to Phase 8 (production hardening)
→ Launch TestFlight beta
→ Get user feedback before adding features

### After Phase 6 (Month 3)
**Decision:** Advanced features OR launch?

**Market conditions:**
- If competitors launching → rush to market
- If niche opportunity → continue features

---

## 📊 SUCCESS METRICS (Post-Launch)

### Technical Metrics
- BLE connection success rate >80%
- Message delivery time <10 seconds (mesh)
- Message delivery time <2 seconds (cloud)
- Battery drain <5% per hour (active use)
- App crash rate <1%

### Product Metrics
- User retention (Day 1, Day 7, Day 30)
- Messages sent per user per day
- Rally channel participation
- Mesh messages vs cloud messages ratio
- User growth rate

### Business Metrics (If Relevant)
- App Store rating >4.0
- TestFlight beta signups
- GitHub stars (if open source)
- Press/blog mentions

---

## 🔧 TECHNICAL DEBT TO ADDRESS

### High Priority
1. Matrix auto-registration (affects onboarding UX)
2. BLE reconnection logic (affects reliability)
3. Contact discovery UI (affects usability)
4. Error handling consistency (affects stability)

### Medium Priority
1. Database query optimization (affects performance)
2. UI polish (animations, loading states)
3. Accessibility (VoiceOver, Dynamic Type)
4. Localization infrastructure

### Low Priority
1. Code comments (affects maintainability)
2. Integration tests (affects confidence)
3. Documentation (affects onboarding new devs)
4. Refactoring (affects code quality)

---

## 💡 FEATURE IDEAS (Future Backlog)

### User Requests (Anticipated)
- [ ] Message search
- [ ] Message reactions
- [ ] Voice/video calls
- [ ] Disappearing messages
- [ ] Screen security (screenshot blocking)
- [ ] PIN lock
- [ ] Fingerprint/Face ID unlock
- [ ] Message backups
- [ ] Desktop app
- [ ] Web app

### Technical Improvements
- [ ] E2EE key verification UI
- [ ] Multi-device sync
- [ ] Message read receipts
- [ ] Typing indicators
- [ ] Online/offline status
- [ ] Custom themes
- [ ] Battery optimization modes

### Rally Mode Extensions
- [ ] Persistent channels (not ephemeral)
- [ ] Channel moderation (elected mods)
- [ ] Rally events (scheduled gatherings)
- [ ] Rally categories (protest, event, emergency)
- [ ] Rally notifications (new channels nearby)

---

## 🚀 DEPLOYMENT STRATEGY

### Phase 1: Internal Testing (Now)
- Test on personal devices (iPhone + iPad)
- Fix critical bugs
- Validate core features
- Document issues

### Phase 2: Friends & Family (Week 2)
- 5-10 trusted testers
- TestFlight distribution
- Collect feedback
- Fix major issues

### Phase 3: Closed Beta (Month 2)
- 50-100 beta testers
- Public TestFlight link (limited slots)
- Analytics enabled
- Bug bounty program?

### Phase 4: Public Beta (Month 3)
- Unlimited TestFlight
- App Store review process
- Marketing push
- Press outreach

### Phase 5: App Store Launch (Month 4-5)
- Version 1.0 release
- Product Hunt launch
- Reddit/HN posts
- Social media campaign

---

## 📝 DOCUMENTATION NEEDED

### User Documentation
- [ ] Getting started guide
- [ ] FAQ
- [ ] Troubleshooting
- [ ] Privacy policy
- [ ] Terms of service

### Developer Documentation
- [ ] Architecture overview
- [ ] API documentation
- [ ] Database schema reference
- [ ] Protocol specifications
- [ ] Contributing guide (if open source)

### Operational Documentation
- [ ] Server deployment guide
- [ ] Monitoring setup
- [ ] Incident response
- [ ] Backup/restore procedures

---

## 🎯 NEXT SESSION GOALS

When you restart after macOS/Xcode update:

### Goal 1: Deploy Successfully
- Both devices recognized by Xcode
- Apps install without errors
- Apps launch without crashes

### Goal 2: Test BLE Mesh
- Devices discover each other via BLE
- Messages send offline via mesh
- Store-and-forward works

### Goal 3: Document Findings
- What works?
- What doesn't?
- What needs fixing?

### Goal 4: Decide Next Steps
Based on BLE results:
- Continue with roadmap? (if BLE works)
- Pivot strategy? (if BLE fails)
- Focus on polish? (if everything works)

---

**The critical unknown: Does BLE mesh networking actually work in the real world?**

Everything else is secondary until we validate this core assumption. 🎯
