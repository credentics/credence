package com.credentics.credence

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (not FlutterActivity) is required by local_auth: its
// BiometricPrompt needs a FragmentActivity host, otherwise authenticate() throws
// no_fragment_activity and biometric unlock silently fails.
class MainActivity : FlutterFragmentActivity()
