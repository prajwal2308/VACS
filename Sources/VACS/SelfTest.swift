import Foundation

/// Assertion-based self-check runnable without XCTest (Command Line Tools can't
/// build the SwiftPM test target). Run with:  ./build/VACS.app/Contents/MacOS/VACS --selftest
/// Exits 0 if all checks pass, 1 otherwise.
enum SelfTest {
    static func run() -> Never {
        var failures: [String] = []
        func check(_ cond: Bool, _ msg: String) { if !cond { failures.append(msg) } }

        // Byte formatting
        check(ByteText.string(0) == "0 B", "ByteText 0")
        check(ByteText.string(1024) == "1.0 KB", "ByteText 1KB")
        check(ByteText.string(1536) == "1.5 KB", "ByteText 1.5KB")
        check(ByteText.string(1_073_741_824) == "1.0 GB", "ByteText 1GB")

        // Overlap detection (dedup between known rules and discovery)
        check(Scanner.overlaps("/a/b", with: ["/a"]), "overlap child")
        check(Scanner.overlaps("/a", with: ["/a/b"]), "overlap parent")
        check(!Scanner.overlaps("/ab", with: ["/a"]), "overlap false-prefix")
        check(!Scanner.overlaps("/x", with: ["/a"]), "overlap unrelated")

        // Safety decoding
        let json = #"[{"id":"x","name":"X","path":"~/x","category":"C","safety":"command","note":"n","command":"do"}]"#
        if let rules = try? JSONDecoder().decode([Rule].self, from: Data(json.utf8)) {
            check(rules.first?.safety == .command, "decode .command")
            check(rules.first?.command == "do", "decode command string")
        } else {
            failures.append("decode failed")
        }

        // Rules database consistency
        let rules = Scanner.loadRules()
        check(!rules.isEmpty, "rules load")
        for r in rules where r.safety == .command {
            check(r.command != nil, "command rule missing command: \(r.id)")
        }
        check(Set(rules.map(\.id)).count == rules.count, "duplicate rule ids")
        check(!rules.contains { $0.id == "trash" }, "trash rule must not be in rules.json — use Trash sidebar")

        if failures.isEmpty {
            print("VACS self-test: OK (\(rules.count) rules loaded)")
            exit(0)
        } else {
            print("VACS self-test: FAILED")
            failures.forEach { print("  - \($0)") }
            exit(1)
        }
    }
}
