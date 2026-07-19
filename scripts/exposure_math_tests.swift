// Standalone sanity tests for the burn-time math.
// Run: ./scripts/run_exposure_tests.sh
// Compiles the real model files, so any drift in the formula fails here.

import Foundation

var failures = 0

func expect(_ condition: Bool, _ message: String) {
    if condition {
        print("  PASS  \(message)")
    } else {
        print("  FAIL  \(message)")
        failures += 1
    }
}

print("safeExposureMinutes:")
// Reference: burn minutes ≈ MED(J/m²) / (1.5 × UVI)
expect((14...19).contains(FitzpatrickType.typeI.safeExposureMinutes(uvIndex: 8)),
       "Type I @ UV 8 ≈ 16 min (got \(FitzpatrickType.typeI.safeExposureMinutes(uvIndex: 8)))")
expect((30...36).contains(FitzpatrickType.typeII.safeExposureMinutes(uvIndex: 5)),
       "Type II @ UV 5 ≈ 33 min (got \(FitzpatrickType.typeII.safeExposureMinutes(uvIndex: 5)))")
expect((60...72).contains(FitzpatrickType.typeVI.safeExposureMinutes(uvIndex: 8)),
       "Type VI @ UV 8 ≈ 66 min (got \(FitzpatrickType.typeVI.safeExposureMinutes(uvIndex: 8)))")
expect(FitzpatrickType.typeI.safeExposureMinutes(uvIndex: 0.5) == 0,
       "Below UV 1 returns 0 (no timer)")
expect(FitzpatrickType.typeVI.safeExposureMinutes(uvIndex: 1) == 120,
       "Very low UV clamps at the 120 min cap")

print("monotonicity:")
for type in FitzpatrickType.allCases {
    let atUV3 = type.safeExposureMinutes(uvIndex: 3)
    let atUV11 = type.safeExposureMinutes(uvIndex: 11)
    expect(atUV3 >= atUV11, "\(type.displayName): more UV never means more time (\(atUV3) ≥ \(atUV11))")
}
expect(FitzpatrickType.typeI.safeExposureMinutes(uvIndex: 8) < FitzpatrickType.typeVI.safeExposureMinutes(uvIndex: 8),
       "Fairer skin gets less time at the same UV")

print("SunExposureScore:")
expect(SunExposureScore.calculate(uvIndex: 8, skinType: .typeI, cloudCoverPercent: 0) == .high,
       "Type I @ UV 8, clear sky → High")
expect(SunExposureScore.calculate(uvIndex: 11, skinType: .typeI, cloudCoverPercent: 0) == .avoid,
       "Type I @ UV 11, clear sky → Avoid")
expect(SunExposureScore.calculate(uvIndex: 3, skinType: .typeVI, cloudCoverPercent: 0) == .low,
       "Type VI @ UV 3 → Low")
expect(SunExposureScore.calculate(uvIndex: 7, skinType: .typeII, cloudCoverPercent: 50) == .moderate,
       "Type II @ UV 7, 50% cloud → Moderate")
expect(SunExposureScore.calculate(uvIndex: 0, skinType: .typeI, cloudCoverPercent: 0) == .low,
       "UV 0 → Low")

// The old bug: every type × UV combination clamped to 120. Prove results vary.
let allResults = Set(FitzpatrickType.allCases.flatMap { type in
    [3.0, 6.0, 9.0].map { type.safeExposureMinutes(uvIndex: $0) }
})
expect(allResults.count > 5, "Results vary across skin types and UV levels (\(allResults.count) distinct values)")

if failures > 0 {
    print("\n\(failures) FAILURE(S)")
    exit(1)
}
print("\nAll tests passed.")
