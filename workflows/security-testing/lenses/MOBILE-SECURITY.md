# Mobile Security

Detect mobile-specific vulnerabilities in iOS and Android applications, including insecure storage, transport security, and platform-specific issues.

## What to Flag

### Insecure Local Storage
- PHI or credentials in AsyncStorage / SharedPreferences / UserDefaults (plaintext)
- Sensitive data not using Keychain (iOS) or EncryptedSharedPreferences (Android)
- SQLite databases with sensitive data stored unencrypted
- Sensitive data in application cache directories

### Transport Security
- Missing certificate pinning for API connections
- ATS (App Transport Security) exceptions allowing HTTP
- Custom `TrustManager` that accepts all certificates (Android)
- `NSAllowsArbitraryLoads` enabled in Info.plist

### Deep Links & URL Schemes
- Custom URL schemes without origin validation
- Deep link handlers that navigate to arbitrary screens based on URL params
- Intent filters accepting data from untrusted sources without validation
- Universal links / App Links without domain verification

### Screen Security
- No screenshot protection on PHI-displaying screens
- Screen recording not prevented for sensitive views
- PHI visible in app switcher/recent apps thumbnail
- Sensitive data not cleared when app backgrounds

### Authentication & Biometrics
- Biometric auth bypassable by device passcode fallback to access PHI
- Auth tokens stored in plaintext
- No re-authentication for sensitive operations
- Missing jailbreak/root detection for PHI-handling apps

### Debug & Build Issues
- Debug logging enabled in release builds
- Debug menu or test endpoints accessible in production builds
- Source maps or debug symbols included in release
- Hardcoded test/staging API URLs or credentials in release code

## Patterns

```javascript
// BAD: PHI in AsyncStorage (plaintext)
await AsyncStorage.setItem('patientData', JSON.stringify(patient))

// GOOD: Use encrypted storage
import EncryptedStorage from 'react-native-encrypted-storage'
await EncryptedStorage.setItem('patientData', JSON.stringify(patient))
```

```javascript
// BAD: No screenshot protection
export const PatientScreen = () => <View><PatientDetails /></View>

// GOOD: Prevent screenshots on sensitive screens
useEffect(() => {
  const subscription = AppState.addEventListener('change', (state) => {
    if (state === 'inactive') setBlurOverlay(true)
  })
  return () => subscription.remove()
}, [])
```

```xml
<!-- BAD: Accepts arbitrary deep links -->
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <data android:scheme="myapp" android:host="*" />
</intent-filter>

<!-- GOOD: Verified App Links with specific paths -->
<intent-filter android:autoVerify="true">
  <data android:scheme="https" android:host="app.example.com" android:pathPrefix="/verified" />
</intent-filter>
```

## Severity

- **CRITICAL**: PHI in plaintext storage, disabled certificate validation
- **HIGH**: Missing cert pinning, biometric bypass, debug builds in production
- **MEDIUM**: Missing screenshot protection, unvalidated deep links
- **LOW**: Missing jailbreak detection, source maps in release

## False Positives to Avoid

- Development-only debug configuration (check build variants/schemes)
- Encrypted storage wrappers that handle encryption transparently
- Certificate pinning configured at the network layer (OkHttp interceptor, TrustKit)
- Non-sensitive data in AsyncStorage (user preferences, UI state)
